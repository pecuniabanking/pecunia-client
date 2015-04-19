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

import Foundation
import JavaScriptCore

@objc public protocol BankingPlugin {
    func pluginDescription() -> String;

    func login(account: BankAccount, password: String) -> Bool;
    func logoff() -> Bool;

    func getStatements(from: ShortDate?, to: ShortDate?) -> [BankQueryResult];
}

@objc public class PluginRegistry {

    private static var plugins: [String: JSContext] = [:];

    public class func startup() {
        logDebug("Starting up plugin registry");

        let scriptingPath = MOAssistant.sharedAssistant().scriptingDir;
        let fileManager = NSFileManager.defaultManager();

        var isDir: ObjCBool = false;
        if fileManager.fileExistsAtPath(scriptingPath, isDirectory: &isDir) && isDir {
            if let contents = fileManager.contentsOfDirectoryAtPath(scriptingPath, error: nil) {
                logDebug("Found %i files in scripts folder", arguments: contents.count);

                for entry in contents {
                    let name = entry as! String;
                    if !name.hasSuffix(".js") {
                        continue;
                    }

                    var error: NSError?;
                    if let script = NSString(contentsOfFile: scriptingPath + "/" + name, encoding: NSUTF8StringEncoding, error: &error) {
                        let context = JSContext();
                        context.evaluateScript(script as String);

                        // Check validity of the plugin.
                        let pluginNameFunction: JSValue = context.objectForKeyedSubscript("pluginName");
                        let result = pluginNameFunction.callWithArguments([]).toString();
                        if result.hasSuffix("-PecuniaPlugin") {
                            plugins[result] = context;
                        }
                    }
                }
                logDebug("Found %i valid plugins", arguments: plugins.count);
            }
        }

        logDebug("Done loading scripts in plugin registry");
    }

    public class func pluginForName(name: String) -> BankingPlugin? {
        if let context = plugins[name] {
            return BankingPluginImpl(context);
        }
        return nil;
    }
}

@objc private class BankingPluginImpl: NSObject, BankingPlugin {

    private var context: JSContext;

    init(_ context: JSContext) {
        self.context = context;
        super.init();
    }

    @objc func pluginDescription() -> String {
        let pluginNameFunction: JSValue = context.objectForKeyedSubscript("description");
        return pluginNameFunction.callWithArguments([]).toString();
    }

    @objc func login(account: BankAccount, password: String) -> Bool {
        return false;
    }

    @objc func logoff() -> Bool {
        return false;
    }

    @objc func getStatements(from: ShortDate?, to: ShortDate?) -> [BankQueryResult] {
        return [];
    }

}
