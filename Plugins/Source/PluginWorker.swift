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

// Contains the implementation needed to run JS code.
// Certain JS protocols are modeled after HTMLUnit.

import Foundation
import WebKit
import AppKit

internal enum XPathResult: Int {
    case ANY_TYPE = 0                     // The type of the result depends on the expression specified
                                          // by the first parameter of the evaluate method.
    case NUMBER_TYPE = 1                  // The result is a number. Use the numberValue property to get
                                          // the value of the result.
    case STRING_TYPE = 2                  // The result is a string. Use the stringValue property to get
                                          // the value of the result.
    case BOOLEAN_TYPE = 3                 // The result is a boolean. Use the booleanValue property to
                                          // get the value of the result.
    case UNORDERED_NODE_ITERATOR_TYPE = 4 // The result contains all nodes that match the expression,
                                          // but not necessarily in the same order as they appear in the
                                          // document hierarchy. Use the iterateNext method to get the
                                          // matching nodes.
    case ORDERED_NODE_ITERATOR_TYPE = 5   // The result contains all nodes that match the expression,
                                          // in the same order as they appear in the document hierarchy.
                                          // Use the iterateNext method to get the matching nodes.
    case UNORDERED_NODE_SNAPSHOT_TYPE = 6 // The result contains snapshots for all nodes that match the
                                          // expression, but not necessarily in the same order as they
                                          // appear in the document hierarchy. Use the snapshotItem method
                                          // to get the matching nodes.
    case ORDERED_NODE_SNAPSHOT_TYPE = 7   // The result contains snapshots for all nodes that match the
                                          // expression, in the same order as they appear in the document
                                          // hierarchy. Use the snapshotItem method to get the matching nodes.
    case ANY_UNORDERED_NODE_TYPE = 8      // The result is a node that matches the expression. The result
                                          // node is not necessarily the first matching node in the document
                                          // hierarchy. Use the singleNodeValue property to get the matching node.
    case FIRST_ORDERED_NODE_TYPE = 9      // The result is the first node in the document hierarchy that
                                          // matches the expression. Use the singleNodeValue property to
                                          // get the matching node.
};

@objc protocol JSLogger : JSExport {
    func logError(message: String) -> Void;
    func logWarning(message: String) -> Void;
    func logInfo(message: String) -> Void;
    func logDebug(message: String) -> Void;
    func logVerbose(message: String) -> Void;
}

@objc protocol WebElementJSExport : JSExport {
    var valueAttribute: JSValue { get set };
    var name: JSValue { get set };
    var id: JSValue { get set };

    func click(); // Should probably be on WebInputJSExport, but atm I don't know how to tell an input
                  // and other elements apart.
}

@objc protocol WebInputJSExport : WebElementJSExport {
}

@objc protocol WebFormJSExport : JSExport {
    func getInputByName(name: String) -> WebInputJSExport;
    func getFirstByXPath(path: String) -> WebElementJSExport;
    func getElementById(id: String) -> WebElementJSExport;
}

@objc protocol WebPageJSExport : JSExport {

}

// JS protocols for certain WebKit classes we want to be usable in JS.
@objc protocol WebViewJSExport : JSExport {

    func navigateTo(location: String) -> String;
    func getFirstByXPath(path: String) -> JSValue;
    func getFormByName(path: String) -> WebFormJSExport;

    var URL: String { get };
    var callback: JSValue { get set };
}

class WebElement: NSObject, WebElementJSExport {
    private let jsElement: JSValue;

    var valueAttribute: JSValue {
        get {
            if jsElement.isUndefined() {
                return JSValue(undefinedInContext: jsElement.context);
            }
            return jsElement.valueForProperty("value");
        }
        set {
            if !jsElement.isUndefined() {
                jsElement.setValue(newValue, forProperty: "value");
            }
        }
    }

    var name: JSValue {
        get {
            if jsElement.isUndefined() {
                return JSValue(undefinedInContext: jsElement.context);
            }
            return jsElement.valueForProperty("name");
        }

        set {
            if !jsElement.isUndefined() {
                jsElement.setValue(newValue, forProperty: "name");
            }
        }
    }

    var id: JSValue {
        get {
            if jsElement.isUndefined() {
                return JSValue(undefinedInContext: jsElement.context);
            }
            return jsElement.valueForProperty("id");
        }

        set {
            if !jsElement.isUndefined() {
                jsElement.setValue(newValue, forProperty: "id");
            }
        }
    }

    init(_ element: JSValue) {
        jsElement = element;
        super.init();
    }

    func click() {
        jsElement.invokeMethod("click", withArguments: []);
    }
}

class WebInput: WebElement, WebInputJSExport {
    override init(_ input: JSValue) {
        super.init(input);
    }
}

class WebForm: WebElement, WebFormJSExport {
    func getInputByName(name: String) -> WebInputJSExport {
        return WebInput(jsElement.valueForProperty("elements").valueForProperty(name));
    }

    func getFirstByXPath(path: String) -> WebElementJSExport {
        let context = jsElement.context;
        let document = context.objectForKeyedSubscript("document");
        let result = document.invokeMethod("evaluate", withArguments: [path, jsElement,
            JSValue(nullInContext: context), XPathResult.FIRST_ORDERED_NODE_TYPE.rawValue, JSValue(nullInContext: context)]);
        let node = result.valueForProperty("singleNodeValue");
        return WebElement(node);
    }

    func getElementById(id: String) -> WebElementJSExport {
        let context = jsElement.context;
        let document = context.objectForKeyedSubscript("document");
        return WebElement(document.invokeMethod("getElementById", withArguments: [id]));
    }
}

class WebClient: WebView, WebViewJSExport {
    var plugin: PluginContext?;

    func navigateTo(location: String) -> String {
        if plugin == nil {
            return "Plugin not set on WebView";
        }

        return plugin!.navigateTo(location);
    }

    func getFirstByXPath(path: String) -> JSValue {
        let context = mainFrame.javaScriptContext;
        let document = context.objectForKeyedSubscript("document");
        let test = document.toArray();
        let result = document.invokeMethod("evaluate", withArguments: [path, document,
            JSValue(nullInContext: context), XPathResult.FIRST_ORDERED_NODE_TYPE.rawValue, JSValue(nullInContext: context)]);
        return result.valueForProperty("singleNodeValue");
    }

    func getFormByName(name: String) -> WebFormJSExport {
        let context = mainFrame.javaScriptContext;
        let form = context.objectForKeyedSubscript("document").valueForProperty("forms").valueForProperty(name);
        return WebForm(form);
    }

    var URL: String {
        return mainFrameURL;
    }

    var callback: JSValue = JSValue();
}

class PluginContext : NSObject {
    private let webClient: WebClient;
    private let workContext: JSContext; // The context on which we run the script.
                                        // WebView's context is recreated on loading a new page,
                                        // stopping so any running JS code.
    private var jsLogger: JSLogger;
    private var redirecting: Bool;
    private var debugScript: String = "";

    init?(pluginFile: String, logger: JSLogger, hostWindow: NSWindow) { // Expects the plugin script to return "true" as last line.
        jsLogger = logger;
        redirecting = false;
        webClient = WebClient();

        workContext = JSContext();
        super.init();

        prepareContext();

        if let script = String(contentsOfFile: pluginFile, encoding: NSUTF8StringEncoding, error: nil) {
            let parseResult = workContext.evaluateScript(script);
            if parseResult.toString() != "true" {
                logger.logError("Script loaded but did not return \"true\"");
                return nil;
            }
        } else {
            logger.logError("Failed to parse script");
            return nil;
        }

        webClient.plugin = self;
        webClient.frameLoadDelegate = self;
        webClient.hostWindow = hostWindow;
    }

    init?(script: String, logger: JSLogger, hostWindow: NSWindow) {
        jsLogger = logger;
        redirecting = false;
        webClient = WebClient();

        workContext = JSContext();
        super.init();

        prepareContext();

        let parseResult = workContext.evaluateScript(script);
        if parseResult.toString() != "true" {
            return nil;
        }

        webClient.plugin = self;
        webClient.frameLoadDelegate = self;
        webClient.hostWindow = hostWindow;
    }

    // MARK: - Setup

    private func prepareContext() {
        workContext.setObject(false, forKeyedSubscript: "JSError");
        workContext.exceptionHandler = { workContext, exception in
            self.jsLogger.logError(exception.toString());
            workContext.setObject(true, forKeyedSubscript: "JSError");
        }

        workContext.setObject(jsLogger.self, forKeyedSubscript: "Logger");
        webClient.mainFrame.javaScriptContext.setObject(jsLogger.self, forKeyedSubscript: "Logger");
        workContext.setObject(webClient.self, forKeyedSubscript: "webClient");
        workContext.setObject(WebForm.self, forKeyedSubscript: "WebForm");
        workContext.setObject(WebInput.self, forKeyedSubscript: "WebInput");
        workContext.setObject(WebElement.self, forKeyedSubscript: "WebElement");
    }

    // MARK: - Plugin Logic

    // Starts (async) navigation to the given location.
    // Returns an error message if something went wrong, otherwise OK.
    func navigateTo(location: String) -> String {
        if let url = NSURL(string: location) {
            redirecting = false;

            webClient.mainFrame.loadRequest(NSURLRequest(URL: url));
            return "OK";

        }
        return "Invalid URL";
    }

    // Allows to add any additional script to the plugin context.
    func addScript(script: String) {
        workContext.evaluateScript(script);
    }

    // Like addScript but for both contexts. Applied on the webclient context each time
    // it is recreated.
    func addDebugScript(script: String) {
        debugScript = script;
        workContext.evaluateScript(script);
    }

    func pluginInfo() -> (name: String, author: String, description: String, homePage: String, license: String, version: String) {

        return (
            name: workContext.objectForKeyedSubscript("name").toString(),
            author: workContext.objectForKeyedSubscript("author").toString(),
            description: workContext.objectForKeyedSubscript("description").toString(),
            homePage: workContext.objectForKeyedSubscript("homePage").toString(),
            license: workContext.objectForKeyedSubscript("license").toString(),
            version: workContext.objectForKeyedSubscript("version").toString()
        );
    }

    func getFunction(name: String) -> JSValue {
        return workContext.objectForKeyedSubscript(name);
    }

    // Only works when a debug script with that function is loaded.
    func getVariables() -> [[String: String]] {
        let context = webClient.mainFrame.javaScriptContext;
        var function = context.objectForKeyedSubscript("getVariables");
        if function.isUndefined() {
            context.evaluateScript(
                "function getVariables() {\n" +
                    "  var result = [];\n" +
                    "  for (var element in document) {\n" +
                    "    try { var o = document[element];\n" +
                    "      if (typeof o != 'function' && typeof o != 'object') {\n" +
                    "        result.push([element, '' + typeof o, '' + o]);\n" +
                    "      }\n" +
                    "    } catch(e) { /* Very likely a security issue. Ignore this member. */ };\n" +
                    "  }\n" +
                    "  return result;\n" +
                "}");
            function = context.objectForKeyedSubscript("getVariables");
        }

        var variables: [[String: String]] = [];
        let result = function.callWithArguments([]);
        if var values = result.toArray() {
            values.sort({ ($0[0] as! String).lowercaseString < ($1[0] as! String).lowercaseString });
            for variable in values as! [[String]] {
                var entries = [String: String]();
                if variable.count > 0 {
                    entries["name"] = variable[0];
                }
                if variable.count > 1 {
                    entries["type"] = variable[1];
                }
                if variable.count > 2 {
                    entries["value"] = variable[2];
                }
                variables.append(entries);
            }
        } else {
            jsLogger.logError("getVariables() returned undefined result");
        }
        return variables;
    }

    // Returns the outer HTML text.
    func getCurrentHTML() -> String {
        return webClient.stringByEvaluatingJavaScriptFromString("document.getElementsByTagName('html')[0].outerHTML");
    }

    // MARK: - webView delegate methods.

    override func webView(sender: WebView!, didStartProvisionalLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("==> Start loading");
        redirecting = false; // Gets set when we get redirected while processing the provisional frame.
    }

    override func webView(sender: WebView!, didReceiveServerRedirectForProvisionalLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("==> Received server redirect for frame");
    }

    override func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("==> Committed load for frame");
    }

    override func webView(sender: WebView!, willPerformClientRedirectToURL URL: NSURL!,
        delay seconds: NSTimeInterval, fireDate date: NSDate!, forFrame frame: WebFrame!) {
            jsLogger.logVerbose("==> Performing client redirection...");
            redirecting = true;
    }

    override func webView(sender: WebView!, didCreateJavaScriptContext context: JSContext, forFrame: WebFrame!) {
        jsLogger.logVerbose("==> JS create");
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        jsLogger.logDebug("==> Finished loading frame from URL: " + frame.dataSource!.response.URL!.absoluteString!);
        if redirecting {
            redirecting = false;
            return;
        }
        
        if !webClient.callback.isUndefined() && !webClient.callback.isNull() {
            jsLogger.logVerbose("==>   Calling callback...");
            webClient.callback.callWithArguments([]);
        }
    }

    override func webView(sender: WebView!, willCloseFrame frame: WebFrame!) {
        jsLogger.logVerbose("==> Closing frame...");
    }

    override func webView(sender: WebView!, didFailLoadWithError error: NSError!, forFrame frame: WebFrame!) {
        jsLogger.logError("Navigating to webpage failed with error \(error.localizedDescription)")
    }
}


