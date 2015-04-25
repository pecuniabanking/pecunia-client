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
                        prepareContext(context);

                        context.evaluateScript(script as String);
                        let foundJSError = context.objectForKeyedSubscript("JSError").toBool();

                        // Check validity of the plugin.
                        if !foundJSError {
                            let pluginNameFunction: JSValue = context.objectForKeyedSubscript("pluginName");
                            let result = pluginNameFunction.callWithArguments([]).toString();
                            if result.hasSuffix("-PecuniaPlugin") {
                                let key = result.substringToIndex(advance(result.endIndex, -count("-PecuniaPlugin")));
                                plugins[key] = context;
                            }
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

    /// Prepares the given context so it can be used with our JS plugins, injecting functions
    /// to read HTML data or log output, setting an error handler etc.
    private class func prepareContext(context: JSContext) -> Void {

        context.setObject(false, forKeyedSubscript: "JSError");
        context.exceptionHandler = { context, exception in
            logError("JS Error: %@", arguments: exception);
            context.setObject(true, forKeyedSubscript: "JSError");
        }

        // Install our HTML read function, which can then be used from JS
        // to load an html page.
        var htmlFromUrl : @objc_block (String!) -> String = {
            (urlString : String!) -> String in

            let url = NSURL(string: urlString);
            var error: NSError?;
            let html = NSString(contentsOfURL: url!, encoding: NSUTF8StringEncoding, error: &error)

            if (error != nil) {
                logError("Couldn't retrieve content at URL: \(urlString). The error is: \(error?.localizedDescription)");
                return "";
            } else {
                return html! as String;
            }
        }
        context.setObject(unsafeBitCast(htmlFromUrl, AnyObject.self), forKeyedSubscript: "htmlFromUrl")

        // Similar for logging.
        let logErrorFunction: @objc_block (String!) -> Void = { logError($0); };
        context.setObject(unsafeBitCast(logErrorFunction, AnyObject.self), forKeyedSubscript: "logError")
        let logWarningFunction: @objc_block (String!) -> Void = { logWarning($0); };
        context.setObject(unsafeBitCast(logWarningFunction, AnyObject.self), forKeyedSubscript: "logWarning")
        let logInfoFunction: @objc_block (String!) -> Void = { logInfo($0); };
        context.setObject(unsafeBitCast(logInfoFunction, AnyObject.self), forKeyedSubscript: "logInfo")
        let logDebugFunction: @objc_block (String!) -> Void = { logDebug($0); };
        context.setObject(unsafeBitCast(logDebugFunction, AnyObject.self), forKeyedSubscript: "logDebug")
        let logVerboseFunction: @objc_block (String!) -> Void = { logVerbose($0); };
        context.setObject(unsafeBitCast(logVerboseFunction, AnyObject.self), forKeyedSubscript: "logVerbose")
    }
}

@objc private class BankingPluginImpl: NSObject, BankingPlugin {

    private var context: JSContext;

    init(_ context: JSContext) {
        context.setObject(BankQueryResult.self, forKeyedSubscript: "BankQueryResult")
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
        var fromDate: NSDate = NSDate();
        if from != nil {
            fromDate = from!.lowDate();
        }
        var toDate: NSDate = NSDate();
        if to != nil {
            toDate = to!.lowDate();
        }

        let pluginNameFunction: JSValue = context.objectForKeyedSubscript("getStatements");
        return pluginNameFunction.callWithArguments([fromDate, toDate]).toArray() as! [BankQueryResult];
    }

}
