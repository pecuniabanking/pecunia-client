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

import Foundation
import WebKit
import AppKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


@objc protocol JSLogger : JSExport {
    func logError(_ message: String) -> Void;
    func logWarning(_ message: String) -> Void;
    func logInfo(_ message: String) -> Void;
    func logDebug(_ message: String) -> Void;
    func logVerbose(_ message: String) -> Void;
}

internal class UserQueryEntry {
    var bankCode: String;
    var passwords: String;
    var accountNumbers: [String];
    var authRequest: AuthRequest;

    init(bankCode bank: String, password pw: String, accountNumbers numbers: [String], auth: AuthRequest) {
        bankCode = bank;
        passwords = pw;
        accountNumbers = numbers;
        authRequest = auth;
    }
};

class WebClient: WebView, WebViewJSExport {

    
    fileprivate var redirecting: Bool = false;
    fileprivate var pluginDescription: String = ""; // The plugin description for error messages.

    var URL: String {
        get {
            return mainFrameURL;
        }
        set {
            redirecting = false;
            if let url = Foundation.URL(string: newValue) {
                mainFrame.load(URLRequest(url: url));
            }
        }
    }

    var postURL: String {
        get {
            return mainFrameURL;
        }
        set {
            redirecting = false;
            if let url = Foundation.URL(string: newValue) {
                var request = URLRequest(url: url);
                request.httpMethod = "POST";
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type");
                mainFrame.load(request);
            }
        }
    }


    var query: UserQueryEntry?;
    var callback: JSValue = JSValue();
    var completion: ([BankQueryResult]) -> Void = { (_: [BankQueryResult]) -> Void in }; // Block to call on results arrival.

    func doTest() {
        redirecting = false;
    }
    
    func reportError(_ account: String, _ message: String) {
        query!.authRequest.errorOccured = true; // Flag the error in the auth request, so it doesn't store the PIN.

        let alert = NSAlert();
        alert.messageText = NSString.localizedStringWithFormat(NSLocalizedString("AP1800", comment: "") as NSString,
            account, pluginDescription) as String;
        alert.informativeText = message;
        alert.alertStyle = .warning;
        alert.runModal();
    }

    func resultsArrived(_ results: JSValue) -> Void {
        query!.authRequest.finishPasswordEntry();

        if let entries = results.toArray() as? [[String: AnyObject]] {
            var queryResults: [BankQueryResult] = [];

            // Unfortunately, the number format can change within a single set of values, which makes it
            // impossible to just have the plugin specify it for us.
            for entry in entries {
                let queryResult = BankQueryResult();

                if  let type = entry["isCreditCard"] as? Bool {
                    queryResult.type = type ? .creditCard : .bankStatement;
                }

                if let lastSettleDate = entry["lastSettleDate"] as? Date {
                    queryResult.lastSettleDate = lastSettleDate;
                }

                if let account = entry["account"] as? String {
                    queryResult.account = BankAccount.find(withNumber: account, bankCode: query!.bankCode);
                    if queryResult.type == .creditCard {
                        queryResult.ccNumber = account;
                    }
                }

                // Balance string might contain a currency code (3 letters).
                if let value = entry["balance"] as? String, value.count > 0 {
                    if let number = NSDecimalNumber.fromString(value) {  // Returns the value up to the currency code (if any).
                        queryResult.balance = number;
                    }
                }

                let statements = entry["statements"] as! [[String: AnyObject]];
                for jsonStatement in statements {
                    let statement: BankStatement = BankStatement.createTemporary(); // Created in memory context.
                    if let final = jsonStatement["final"] as? Bool {
                        statement.isPreliminary = NSNumber(value: !final);
                    }

                    if let date = jsonStatement["valutaDate"] as? Date {
                        statement.valutaDate = date.addingTimeInterval(12 * 3600); // Add 12hrs so we start at noon.
                    } else {
                        statement.valutaDate = Date();
                    }

                    if let date = jsonStatement["date"] as? Date {
                        statement.date = date.addingTimeInterval(12 * 3600);
                    } else {
                        statement.date = statement.valutaDate;
                    }

                    if let purpose = jsonStatement["transactionText"] as? String {
                        statement.purpose = purpose;
                    }

                    if let value = jsonStatement["value"] as? String, value.count > 0 {
                        // Because there is a setValue function in NSObject we cannot write to the .value
                        // member in BankStatement. Using a custom setter would make this into a function
                        // call instead, but that crashes atm.
                        // Using dictionary access instead for the time being until this is resolved.
                        if let number = NSDecimalNumber.fromString(value) {
                            statement.setValue(number, forKey: "value");
                        } else {
                            statement.setValue(NSDecimalNumber(value: 0 as Int32), forKey: "value");
                        }
                    }

                    if let value = jsonStatement["originalValue"] as? String, value.count > 0 {
                        if let number = NSDecimalNumber.fromString(value) {
                            statement.origValue = number;
                        }
                    }
                    queryResult.statements.append(statement);
                }

                // Explicitly sort by date, as it might happen that statements have a different
                // sorting (e.g. by valuta date).
                queryResult.statements.sort(by: { $0.date < $1.date });
                queryResults.append(queryResult);
            }
            completion(queryResults);
        }
    }

}

class PluginContext : NSObject, WebFrameLoadDelegate, WebUIDelegate {
    fileprivate let webClient: WebClient;
    fileprivate let workContext: JSContext; // The context on which we run the script.
                                        // WebView's context is recreated on loading a new page,
                                        // stopping so any running JS code.
    fileprivate var jsLogger: JSLogger;
    fileprivate var debugScript: String = "";

    init?(pluginFile: String, logger: JSLogger, hostWindow: NSWindow?) {
        jsLogger = logger;
        webClient = WebClient();

        workContext = JSContext();
        super.init();

        prepareContext();

        do {
            let script = try String(contentsOfFile: pluginFile, encoding: String.Encoding.utf8);
            let parseResult = workContext.evaluateScript(script);
            if parseResult?.toString() != "true" {
                logger.logError("Script loaded but did not return \"true\"");
                return nil;
            }
        } catch {
            logger.logError("Failed to parse script");
            return nil;
        }
        setupWebClient(hostWindow);
    }

    init?(script: String, logger: JSLogger, hostWindow: NSWindow?) {
        jsLogger = logger;
        webClient = WebClient();

        workContext = JSContext();
        super.init();

        prepareContext();

        let parseResult = workContext.evaluateScript(script);
        if parseResult?.toString() != "true" {
            return nil;
        }
        setupWebClient(hostWindow);
    }

    // MARK: - Setup

    fileprivate func prepareContext() {
        workContext.setObject(false, forKeyedSubscript: "JSError" as (NSCopying & NSObjectProtocol)?);
        workContext.exceptionHandler = { workContext, exception in
            self.jsLogger.logError((exception?.toString())!);
            workContext?.setObject(true, forKeyedSubscript: "JSError" as (NSCopying & NSObjectProtocol)?);
        }

        workContext.setObject(jsLogger.self, forKeyedSubscript: "logger" as NSCopying & NSObjectProtocol);
        webClient.mainFrame.javaScriptContext.setObject(jsLogger.self, forKeyedSubscript: "logger" as NSCopying & NSObjectProtocol);
        //webClient.mainFrame.javaScriptContext.setObject(webClient.self, forKeyedSubscript: "webClient" as NSCopying & NSObjectProtocol);

        // Export Webkit to the work context, so that plugins can use it to work with data/the DOM
        // from the web client.
        workContext.setObject(DOMNodeList.self, forKeyedSubscript: "DOMNodeList" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMCSSStyleDeclaration.self, forKeyedSubscript: "DOMCSSStyleDeclaration" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMCSSRuleList.self, forKeyedSubscript: "DOMCSSRuleList" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMNamedNodeMap.self, forKeyedSubscript: "DOMNamedNodeMap" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMNode.self, forKeyedSubscript: "DOMNode" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMAttr.self, forKeyedSubscript: "DOMAttr" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMElement.self, forKeyedSubscript: "DOMElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLCollection.self, forKeyedSubscript: "DOMHTMLCollection" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLElement.self, forKeyedSubscript: "DOMHTMLElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMDocumentType.self, forKeyedSubscript: "DOMDocumentType" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLFormElement.self, forKeyedSubscript: "DOMHTMLFormElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLInputElement.self, forKeyedSubscript: "DOMHTMLInputElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLButtonElement.self, forKeyedSubscript: "DOMHTMLButtonElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLAnchorElement.self, forKeyedSubscript: "DOMHTMLAnchorElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLOptionElement.self, forKeyedSubscript: "DOMHTMLOptionElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLOptionsCollection.self, forKeyedSubscript: "DOMHTMLOptionsCollection" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMHTMLSelectElement.self, forKeyedSubscript: "DOMHTMLSelectElement" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMImplementation.self, forKeyedSubscript: "DOMImplementation" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMStyleSheetList.self, forKeyedSubscript: "DOMStyleSheetList" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMDocumentFragment.self, forKeyedSubscript: "DOMDocumentFragment" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMCharacterData.self, forKeyedSubscript: "DOMCharacterData" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMText.self, forKeyedSubscript: "DOMText" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMComment.self, forKeyedSubscript: "DOMComment" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMCDATASection.self, forKeyedSubscript: "DOMCDATASection" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMProcessingInstruction.self, forKeyedSubscript: "DOMProcessingInstruction" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMEntityReference.self, forKeyedSubscript: "DOMEntityReference" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(DOMDocument.self, forKeyedSubscript: "DOMDocument" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(WebFrame.self, forKeyedSubscript: "WebFrame" as (NSCopying & NSObjectProtocol)?);
        workContext.setObject(webClient.self, forKeyedSubscript: "webClient" as NSCopying & NSObjectProtocol);
    }

    fileprivate func setupWebClient(_ hostWindow: NSWindow?) {
        webClient.frameLoadDelegate = self;
        webClient.uiDelegate = self;
        webClient.preferences.javaScriptCanOpenWindowsAutomatically = true;
        webClient.hostWindow = hostWindow;
        if hostWindow != nil {
            hostWindow!.contentView = webClient;
        }
        webClient.pluginDescription = workContext.objectForKeyedSubscript("description").toString();

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString");
        webClient.applicationNameForUserAgent = "Pecunia/\(version ?? "1.3.3") (Safari)";
    }

    // MARK: - Plugin Logic

    // Allows to add any additional script to the plugin context.
    func addScript(_ script: String) {
        workContext.evaluateScript(script);
    }

    // Like addScript but for both contexts. Applied on the webclient context each time
    // it is recreated.
    func addDebugScript(_ script: String) {
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

    // Calls the getStatements() plugin function and translates results from JSON to a BankQueryResult list.
    func getStatements(_ userId: String, query: UserQueryEntry, fromDate: Date, toDate: Date,
        completion: @escaping ([BankQueryResult]) -> Void) -> Void {
            let scriptFunction: JSValue = workContext.objectForKeyedSubscript("getStatements");
            let pluginId = workContext.objectForKeyedSubscript("name").toString();
            if scriptFunction.isUndefined {
                jsLogger.logError("Error: getStatements() not found in plugin " + pluginId!);
                return;
            }

            webClient.completion = completion;
            webClient.query = query;
            if !(scriptFunction.call(withArguments: [userId, query.bankCode, query.passwords, fromDate,
                toDate, query.accountNumbers]) != nil) {
                jsLogger.logError("getStatements() didn't properly start for plugin " + pluginId!);
            }
    }

    func getFunction(_ name: String) -> JSValue {
        return workContext.objectForKeyedSubscript(name);
    }

    // Returns the outer body HTML text.
    func getCurrentHTML() -> String {
        return webClient.mainFrame.document.body.outerHTML;
    }

    func canHandle(_ account: String, bankCode: String) -> Bool {
        let function = workContext.objectForKeyedSubscript("canHandle");
        if (function?.isUndefined)! {
            return false;
        }

        let result = function?.call(withArguments: [account, bankCode]);
        if (result?.isBoolean)! {
            return result!.toBool();
        }
        return false;
    }

    // MARK: - webView delegate methods.

    internal func webView(_ sender: WebView!, didStartProvisionalLoadFor frame: WebFrame!) {
        jsLogger.logVerbose("(*) Start loading");
        webClient.redirecting = false; // Gets set when we get redirected while processing the provisional frame.
    }

    internal func webView(_ sender: WebView!, didReceiveServerRedirectForProvisionalLoadFor frame: WebFrame!) {
        jsLogger.logVerbose("(*) Received server redirect for frame");
    }

    internal func webView(_ sender: WebView!, didCommitLoadFor frame: WebFrame!) {
        jsLogger.logVerbose("(*) Committed load for frame");
    }

    internal func webView(_ sender: WebView!, willPerformClientRedirectTo URL: URL!,
        delay seconds: TimeInterval, fire date: Date!, for frame: WebFrame!) {
            jsLogger.logVerbose("(*) Performing client redirection...");
            webClient.redirecting = true;
    }

    internal func webView(_ sender: WebView!, didCreateJavaScriptContext context: JSContext, for forFrame: WebFrame!) {
        jsLogger.logVerbose("(*) JS create");
    }

    internal func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        jsLogger.logVerbose("(*) Finished loading frame from URL: " + frame.dataSource!.response.url!.absoluteString);
        if webClient.redirecting {
            webClient.redirecting = false;
            return;
        }

        if !webClient.callback.isUndefined && !webClient.callback.isNull {
            jsLogger.logVerbose("(*) Calling callback...");
            webClient.callback.call(withArguments: [false]);
        }
    }

    internal func webView(_ sender: WebView!, willClose frame: WebFrame!) {
        jsLogger.logVerbose("(*) Closing frame...");
    }

    internal func webView(_ sender: WebView!, didFailLoadWithError error: Error!, for frame: WebFrame!) {
        jsLogger.logError("(*) Navigating to webpage failed with error: \(error.localizedDescription)")
    }
    
    internal func webView(_ sender: WebView!, runJavaScriptAlertPanelWithMessage message: String, initiatedBy initiatedByFrame: WebFrame!) {
        let alert = NSAlert();
        alert.messageText = message;
        alert.runModal();
    }
    
}
