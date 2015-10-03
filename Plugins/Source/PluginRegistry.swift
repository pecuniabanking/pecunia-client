/*
 * Copyright (c) 2015, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

import Foundation;
import WebKit;

@objc public class PluginRegistry : NSObject, JSLogger {

    private var plugins: [String: (description: String, context: PluginContext)] = [:];
    private static var registry: PluginRegistry?;

    public class func startup() {
        registry = PluginRegistry();
        registry!.setup();
    }

    private func setup() {
        logDebug("Starting up plugin registry");

        let pluginPath = MOAssistant.sharedAssistant().pluginDir;
        let fileManager = NSFileManager.defaultManager();

        // For standard plugins (non-existing, out-of-date) checks.
        let defaultPluginPaths = NSBundle.mainBundle().pathsForResourcesOfType("js", inDirectory: "Plugins");

        var isDir: ObjCBool = false;
        if fileManager.fileExistsAtPath(pluginPath, isDirectory: &isDir) && isDir {
            do {
                var contents = try fileManager.contentsOfDirectoryAtPath(pluginPath);

                // First check if any of the default plugins is missing or newer and copy it to the
                // target plugin folder if so.
                var needRescan = false;
                for defaultPluginPath in defaultPluginPaths {
                    let pluginName = NSURL(fileURLWithPath: defaultPluginPath).lastPathComponent!;
                    let pluginNameCopy : NSString = pluginName as NSString; // To avoid frequent casts.
                    if !contents.contains(pluginName) {
                        needRescan = true;
                        try fileManager.copyItemAtPath(defaultPluginPath, toPath: pluginPath + "/" + pluginName);
                    } else {
                        // Check last modified date and if the default is newer backup existing file + copy.
                        // If there's any error accessing the files then ignore them.
                        do {
                            let sourceAttributes = try fileManager.attributesOfItemAtPath(defaultPluginPath) as NSDictionary;
                            let targetName = pluginPath + "/" + pluginName;
                            let targetAttributes = try fileManager.attributesOfItemAtPath(targetName) as NSDictionary;
                            if let sourceDate = sourceAttributes.fileModificationDate(),
                                let targetDate = targetAttributes.fileModificationDate() {
                                    if sourceDate > targetDate {
                                        // A newer version of the plugin exists. Backup the exsting one
                                        // (don't touch existing backups) and then copy the new one.
                                        var newBackupName = "";
                                        let baseName = pluginNameCopy.stringByDeletingPathExtension;
                                        let ext = pluginNameCopy.pathExtension;
                                        var counter = 1;

                                        while counter < 1000 {
                                            let tempBackupName = baseName + ".backup \(counter++)." + ext;
                                            if !contents.contains(tempBackupName) {
                                                // Unused backup name found.
                                                newBackupName = tempBackupName;
                                                break;
                                            }
                                        }

                                        // If we cannot find a usable backup name give up and simply replace
                                        // the current file.
                                        if newBackupName.isEmpty {
                                            do {
                                                try fileManager.removeItemAtPath(targetName);
                                            } catch let error as NSError {
                                                logError("Cannot delete existing plugin: \(error.localizedDescription)");
                                                continue;
                                            }

                                        } else {
                                            do {
                                                try fileManager.moveItemAtPath(targetName, toPath: pluginPath + "/" + newBackupName);
                                            } catch let error as NSError {
                                                logError("Cannot backup existing plugin: \(error.localizedDescription)");
                                                continue;
                                            }
                                        }

                                        do {
                                            try fileManager.copyItemAtPath(defaultPluginPath, toPath: targetName);
                                        } catch let error as NSError {
                                            NSAlert(error: error).runModal();
                                        }
                                    }
                            }
                        } catch {
                            continue;
                        }
                    }
                }

                // Re-read folder content if we copied files.
                if needRescan {
                    contents = try fileManager.contentsOfDirectoryAtPath(pluginPath);
                }

                for entry in contents {
                    do {
                        if !entry.hasSuffix(".js") {
                            continue;
                        }
                        let result = try entry.containsMatch("\\.backup \\d+\\.", ignoreCase: true);
                        if result! {
                            continue;
                        }
                    } catch {
                        continue;
                    }

                    if let context = PluginContext(pluginFile: pluginPath + "/" + entry, logger: PluginRegistry.registry!, hostWindow: nil) {
                        let (name, _, description, _, _, _) = context.pluginInfo();
                        if name.hasPrefix("pecunia.plugin.") {
                            if plugins[name] != nil {
                                logWarning("Duplicate plugin name found: \(name)");
                            }
                            plugins[name] = (description, context);
                            logInfo("Successfully loaded plugin: \(name) (\(description))");
                        }
                    }
                }
                logDebug("Found \(plugins.count) valid plugins");
            } catch let error as NSError {
                logError("Could not enumerate plugin folder: \(error.localizedDescription)");
                NSAlert(error: error).runModal();
            }
        }

        logDebug("Done loading scripts in plugin registry");
    }

    public static func getPluginList() -> [[String: String]] {
        var result: [[String: String]] = [];
        for (key, entry) in registry!.plugins {
            result.append(["id": key, "name": entry.description]);
        }
        return result;
    }

    // Checks all registered plugins if any of them can handle the given combination.
    // The first hit wins.
    public static func pluginForAccount(account: String, bankCode: String) -> String {
        for (key, entry) in registry!.plugins {
            if entry.context.canHandle(account, bankCode: bankCode) {
                return key;
            }
        }
        return "";
    }

    /**
     * Takes a list of accounts (which all must be handled by the same plugin) and runs the associated
     * plugin for them. The account list is split by user ids.
     */
    public static func getStatements(accounts: [BankAccount], completion: ([BankQueryResult]) -> Void) -> Void {
        logEnter();

        // The HBCI part of the statement retrieval computes an own start date for each account.
        // We don't do this kind of granularity here. Instead we use the lowest start date found for all
        // accounts which might return a few more results for accounts that have been updated later
        // than others (but nobodoy would notice anyway, as the unwanted older statements exist already in the db).
        var fromDate: NSDate?;
        var maxStatDays: NSTimeInterval = 0;
        if NSUserDefaults.standardUserDefaults().boolForKey("limitStatsAge") {
            maxStatDays = NSTimeInterval(NSUserDefaults.standardUserDefaults().integerForKey("maxStatDays"));
        }

        var queryList: [String: UserQueryEntry] = [:];
        for account in accounts {
            if account.latestTransferDate == nil && maxStatDays > 0 {
                account.latestTransferDate = NSDate(timeInterval: -86400.0 * maxStatDays, sinceDate: NSDate());
            }

            if (account.latestTransferDate != nil) {
                let startDate = NSDate(timeInterval: -2592000, sinceDate: account.latestTransferDate);
                if fromDate == nil || startDate.isBefore(fromDate!) {
                    fromDate = startDate;
                }
            }

            var entry = queryList[account.userId];
            if entry == nil {
                // At the moment we don't accept other authentication methods than user name + password.
                let request = AuthRequest();
                let password = request.getPin(account.bankCode, userId: account.userId);
                if password != "<abort>" {
                    entry = UserQueryEntry(bankCode: account.bankCode, password: password,
                        accountNumbers: [], auth: request);
                    queryList[account.userId] = entry;
                }
            }

            if entry != nil {
                let number = String(account.accountNumber().characters.filter { $0 != " " } ); // Remove all space chars.
                entry!.accountNumbers.append(number);
            }
        }

        // Use a fixed interval of 30 days if none of the accounts has a latest transfer date and no max stat days
        // value is specified.
        if fromDate == nil {
            fromDate = NSDate(timeInterval: -2592000 * maxStatDays, sinceDate: NSDate());
        }

        let pluginId = accounts[0].plugin;
        if let (_, pluginContext) = registry?.plugins[pluginId] {
            if queryList.count == 0 {
                completion([]);
            } else {
                for (userId, query) in queryList {
                    pluginContext.getStatements(userId, query: query, fromDate: fromDate!,
                        toDate: NSDate(), completion: completion);
                }
            }
        } else {
            registry!.logError("Couldn't find plugin " + pluginId);
            completion([]);
        }

        logLeave();
    }

    func logError(message: String) -> Void {
        DDLog.doLog(DDLogFlag.Error, message: message, function: nil, file: nil, line: -1, arguments: []);
    };

    func logWarning(message: String) -> Void {
        DDLog.doLog(DDLogFlag.Warning, message: message, function: nil, file: nil, line: -1, arguments: []);
    };

    func logInfo(message: String) -> Void {
        DDLog.doLog(DDLogFlag.Info, message: message, function: nil, file: nil, line: -1, arguments: []);
    };

    func logDebug(message: String) -> Void {
        DDLog.doLog(DDLogFlag.Debug, message: message, function: nil, file: nil, line: -1, arguments: []);
    };

    func logVerbose(message: String) -> Void {
        DDLog.doLog(DDLogFlag.Verbose, message: message, function: nil, file: nil, line: -1, arguments: []);
    };
}
