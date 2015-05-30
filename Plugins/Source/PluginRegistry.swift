/**
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

@objc public class PluginRegistry : NSObject, JSLogger {

    private var plugins: [String: (String, PluginContext)] = [:];
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
        let defaultPluginPaths = NSBundle.mainBundle().pathsForResourcesOfType("js", inDirectory: "Plugins") as! [String];

        var isDir: ObjCBool = false;
        if fileManager.fileExistsAtPath(pluginPath, isDirectory: &isDir) && isDir {
            if var contents = fileManager.contentsOfDirectoryAtPath(pluginPath, error: nil) as? [String] {
                // First check if any of the default plugins is missing and copy it to the target plugin folder if so.
                var needRescan = false;
                var error: NSError?;
                for defaultPluginPath in defaultPluginPaths {
                    if !contents.contains(defaultPluginPath.lastPathComponent) {
                        needRescan = true;
                        if (!fileManager.copyItemAtPath(defaultPluginPath,
                            toPath: pluginPath + "/" + defaultPluginPath.lastPathComponent, error: &error)) {
                                NSAlert(error: error!).runModal();
                        }
                    } else {
                        // TODO: check last modified date and if the default is newer ask user + copy.
                    }
                }

                // Re-read folder content if we copied files.
                if needRescan {
                    contents = fileManager.contentsOfDirectoryAtPath(pluginPath, error: nil) as! [String];
                }

                for entry in contents {
                    if !entry.hasSuffix(".js") {
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
                logDebug("Found \(count(plugins)) valid plugins");
            }
        }

        logDebug("Done loading scripts in plugin registry");
    }

    public func getStatements(fromPlugin name: String, accounts: [BankAccount]) -> Void {
        if let context = plugins[name] {
        }
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
