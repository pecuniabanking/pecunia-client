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

@objc protocol JSLogger : JSExport {
    func logError(message: String) -> Void;
    func logWarning(message: String) -> Void;
    func logInfo(message: String) -> Void;
    func logDebug(message: String) -> Void;
    func logVerbose(message: String) -> Void;
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
    private var redirecting: Bool = false;
    private var pluginDescription: String = ""; // The plugin description for error messages.

    var URL: String {
        get {
            return mainFrameURL;
        }
        set {
            redirecting = false;
            if let url = NSURL(string: newValue) {
                mainFrame.loadRequest(NSURLRequest(URL: url));
            }
        }
    }

    var postURL: String {
        get {
            return mainFrameURL;
        }
        set {
            redirecting = false;
            if let url = NSURL(string: newValue) {
                let request = NSMutableURLRequest(URL: url);
                request.HTTPMethod = "POST";
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type");
                mainFrame.loadRequest(request);
            }
        }
    }


    var query: UserQueryEntry?;
    var callback: JSValue = JSValue();
    var completion: ([BankQueryResult]) -> Void = { (_: [BankQueryResult]) -> Void in }; // Block to call on results arrival.


    func reportError(account: String, _ message: String) {
        query!.authRequest.errorOccured = true; // Flag the error in the auth request, so it doesn't store the PIN.

        let alert = NSAlert();
        alert.messageText = NSString.localizedStringWithFormat(NSLocalizedString("AP1800", comment: ""),
            account, pluginDescription) as String;
        alert.informativeText = message;
        alert.alertStyle = .Warning;
        alert.runModal();
    }

    func resultsArrived(results: JSValue) -> Void {
        query!.authRequest.finishPasswordEntry();

        if let entries = results.toArray() as? [[String: AnyObject]] {
            var queryResults: [BankQueryResult] = [];

            // Unfortunately, the number format can change within a single set of values, which makes it
            // impossible to just have the plugin specify it for us.
            for entry in entries {
                let queryResult = BankQueryResult();

                if  let type = entry["isCreditCard"] as? Bool {
                    queryResult.type = type ? .CreditCard : .BankStatement;
                }

                if let lastSettleDate = entry["lastSettleDate"] as? NSDate {
                    queryResult.lastSettleDate = lastSettleDate;
                }

                if let account = entry["account"] as? String {
                    queryResult.account = BankAccount.findAccountWithNumber(account, bankCode: query!.bankCode);
                    if queryResult.type == .CreditCard {
                        queryResult.ccNumber = account;
                    }
                }

                // Balance string might contain a currency code (3 letters).
                if let value = entry["balance"] as? String where value.characters.count > 0 {
                    if let number = NSDecimalNumber.fromString(value) {  // Returns the value up to the currency code (if any).
                        queryResult.balance = number;
                    }
                }

                let statements = entry["statements"] as! [[String: AnyObject]];
                for jsonStatement in statements {
                    let statement: BankStatement = BankStatement.createTemporary(); // Created in memory context.
                    if let final = jsonStatement["final"] as? Bool {
                        statement.isPreliminary = !final;
                    }

                    if let date = jsonStatement["valutaDate"] as? NSDate {
                        statement.valutaDate = date.dateByAddingTimeInterval(12 * 3600); // Add 12hrs so we start at noon.
                    } else {
                        statement.valutaDate = NSDate();
                    }

                    if let date = jsonStatement["date"] as? NSDate {
                        statement.date = date.dateByAddingTimeInterval(12 * 3600);
                    } else {
                        statement.date = statement.valutaDate;
                    }

                    if let purpose = jsonStatement["transactionText"] as? String {
                        statement.purpose = purpose;
                    }

                    if let remoteName = jsonStatement["remoteName"] as? String {
                        statement.remoteName = remoteName;
                    }

                    if let remoteAccount = jsonStatement["remoteAccount"] as? String {
                        statement.remoteAccount = remoteAccount;
                    }

                    if let remoteBankCode = jsonStatement["remoteBankCode"] as? String {
                        statement.remoteBankCode = remoteBankCode;
                    }

                    if let remoteIBAN = jsonStatement["remoteIBAN"] as? String {
                        statement.remoteIBAN = remoteIBAN;
                    }

                    if let remoteBIC = jsonStatement["remoteBIC"] as? String {
                        statement.remoteBIC = remoteBIC;
                    }

                    if let value = jsonStatement["value"] as? String  where value.characters.count > 0 {
                        // Because there is a setValue function in NSObject we cannot write to the .value
                        // member in BankStatement. Using a custom setter would make this into a function
                        // call instead, but that crashes atm.
                        // Using dictionary access instead for the time being until this is resolved.
                        if let number = NSDecimalNumber.fromString(value) {
                            statement.setValue(number, forKey: "value");
                        } else {
                            statement.setValue(NSDecimalNumber(int: 0), forKey: "value");
                        }
                    }

                    if let value = jsonStatement["originalValue"] as? String where value.characters.count > 0 {
                        if let number = NSDecimalNumber.fromString(value) {
                            statement.origValue = number;
                        }
                    }
                    queryResult.statements.append(statement);
                }

                // Explicitly sort by date, as it might happen that statements have a different
                // sorting (e.g. by valuta date).
                queryResult.statements.sortInPlace({ $0.date < $1.date });
                if let value = queryResult.statements.last as BankStatement? {
                    queryResult.account?.latestTransferDate = value.date;
                }
                queryResults.append(queryResult);
            }
            completion(queryResults);
        }
    }

}

class PluginContext : NSObject, WebFrameLoadDelegate, WebUIDelegate {
    private let webClient: WebClient;
    private let workContext: JSContext; // The context on which we run the script.
                                        // WebView's context is recreated on loading a new page,
                                        // stopping so any running JS code.
    private var jsLogger: JSLogger;
    private var debugScript: String = "";

    init?(pluginFile: String, logger: JSLogger, hostWindow: NSWindow?) {
        jsLogger = logger;
        webClient = WebClient();

        workContext = JSContext();
        super.init();

        prepareContext();

        do {
            let script = try String(contentsOfFile: pluginFile, encoding: NSUTF8StringEncoding);
            let parseResult = workContext.evaluateScript(script);
            if parseResult.toString() != "true" {
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
        if parseResult.toString() != "true" {
            return nil;
        }
        setupWebClient(hostWindow);
    }

    // MARK: - Setup

    private func prepareContext() {
        workContext.setObject(false, forKeyedSubscript: "JSError");
        workContext.exceptionHandler = { workContext, exception in
            self.jsLogger.logError(exception.toString());
            workContext.setObject(true, forKeyedSubscript: "JSError");
        }

        workContext.setObject(jsLogger.self, forKeyedSubscript: "logger");
        webClient.mainFrame.javaScriptContext.setObject(jsLogger.self, forKeyedSubscript: "logger");

        // Export Webkit to the work context, so that plugins can use it to work with data/the DOM
        // from the web client.
        workContext.setObject(DOMNodeList.self, forKeyedSubscript: "DOMNodeList");
        workContext.setObject(DOMCSSStyleDeclaration.self, forKeyedSubscript: "DOMCSSStyleDeclaration");
        workContext.setObject(DOMCSSRuleList.self, forKeyedSubscript: "DOMCSSRuleList");
        workContext.setObject(DOMNamedNodeMap.self, forKeyedSubscript: "DOMNamedNodeMap");
        workContext.setObject(DOMNode.self, forKeyedSubscript: "DOMNode");
        workContext.setObject(DOMAttr.self, forKeyedSubscript: "DOMAttr");
        workContext.setObject(DOMElement.self, forKeyedSubscript: "DOMElement");
        workContext.setObject(DOMHTMLCollection.self, forKeyedSubscript: "DOMHTMLCollection");
        workContext.setObject(DOMHTMLElement.self, forKeyedSubscript: "DOMHTMLElement");
        workContext.setObject(DOMDocumentType.self, forKeyedSubscript: "DOMDocumentType");
        workContext.setObject(DOMHTMLFormElement.self, forKeyedSubscript: "DOMHTMLFormElement");
        workContext.setObject(DOMHTMLInputElement.self, forKeyedSubscript: "DOMHTMLInputElement");
        workContext.setObject(DOMHTMLButtonElement.self, forKeyedSubscript: "DOMHTMLButtonElement");
        workContext.setObject(DOMHTMLAnchorElement.self, forKeyedSubscript: "DOMHTMLAnchorElement");
        workContext.setObject(DOMHTMLOptionElement.self, forKeyedSubscript: "DOMHTMLOptionElement");
        workContext.setObject(DOMHTMLOptionsCollection.self, forKeyedSubscript: "DOMHTMLOptionsCollection");
        workContext.setObject(DOMHTMLSelectElement.self, forKeyedSubscript: "DOMHTMLSelectElement");
        workContext.setObject(DOMImplementation.self, forKeyedSubscript: "DOMImplementation");
        workContext.setObject(DOMStyleSheetList.self, forKeyedSubscript: "DOMStyleSheetList");
        workContext.setObject(DOMDocumentFragment.self, forKeyedSubscript: "DOMDocumentFragment");
        workContext.setObject(DOMCharacterData.self, forKeyedSubscript: "DOMCharacterData");
        workContext.setObject(DOMText.self, forKeyedSubscript: "DOMText");
        workContext.setObject(DOMComment.self, forKeyedSubscript: "DOMComment");
        workContext.setObject(DOMCDATASection.self, forKeyedSubscript: "DOMCDATASection");
        workContext.setObject(DOMProcessingInstruction.self, forKeyedSubscript: "DOMProcessingInstruction");
        workContext.setObject(DOMEntityReference.self, forKeyedSubscript: "DOMEntityReference");
        workContext.setObject(DOMDocument.self, forKeyedSubscript: "DOMDocument");
        workContext.setObject(WebFrame.self, forKeyedSubscript: "WebFrame");
        workContext.setObject(webClient.self, forKeyedSubscript: "webClient");
    }

    private func setupWebClient(hostWindow: NSWindow?) {
        webClient.frameLoadDelegate = self;
        webClient.UIDelegate = self;
        webClient.preferences.javaScriptCanOpenWindowsAutomatically = true;
        webClient.hostWindow = hostWindow;
        if hostWindow != nil {
            hostWindow!.contentView = webClient;
        }
        webClient.pluginDescription = workContext.objectForKeyedSubscript("description").toString();

        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString");
        webClient.applicationNameForUserAgent = "Pecunia/\(version) (Safari)";
    }

    // MARK: - Plugin Logic

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

    // Calls the getStatements() plugin function and translates results from JSON to a BankQueryResult list.
    func getStatements(userId: String, query: UserQueryEntry, fromDate: NSDate, toDate: NSDate,
        completion: ([BankQueryResult]) -> Void) -> Void {
            let scriptFunction: JSValue = workContext.objectForKeyedSubscript("getStatements");
            let pluginId = workContext.objectForKeyedSubscript("name").toString();
            if scriptFunction.isUndefined {
                jsLogger.logError("Error: getStatements() not found in plugin " + pluginId);
                return;
            }

            webClient.completion = completion;
            webClient.query = query;
            if !(scriptFunction.callWithArguments([userId, query.bankCode, query.passwords, fromDate,
                toDate, query.accountNumbers]) != nil) {
                jsLogger.logError("getStatements() didn't properly start for plugin " + pluginId);
            }
    }

    func getFunction(name: String) -> JSValue {
        return workContext.objectForKeyedSubscript(name);
    }

    // Returns the outer body HTML text.
    func getCurrentHTML() -> String {
        return webClient.mainFrame.document.body.outerHTML;
    }

    func canHandle(account: String, bankCode: String) -> Bool {
        let function = workContext.objectForKeyedSubscript("canHandle");
        if function.isUndefined {
            return false;
        }

        let result = function.callWithArguments([account, bankCode]);
        if result.isBoolean {
            return result.toBool();
        }
        return false;
    }

    // MARK: - webView delegate methods.

    internal func webView(sender: WebView!, didStartProvisionalLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("(*) Start loading");
        webClient.redirecting = false; // Gets set when we get redirected while processing the provisional frame.
    }

    internal func webView(sender: WebView!, didReceiveServerRedirectForProvisionalLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("(*) Received server redirect for frame");
    }

    internal func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("(*) Committed load for frame");
    }

    internal func webView(sender: WebView!, willPerformClientRedirectToURL URL: NSURL!,
        delay seconds: NSTimeInterval, fireDate date: NSDate!, forFrame frame: WebFrame!) {
            jsLogger.logVerbose("(*) Performing client redirection...");
            webClient.redirecting = true;
    }

    internal func webView(sender: WebView!, didCreateJavaScriptContext context: JSContext, forFrame: WebFrame!) {
        jsLogger.logVerbose("(*) JS create");
    }

    internal func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        jsLogger.logVerbose("(*) Finished loading frame from URL: " + frame.dataSource!.response.URL!.absoluteString!);
        if webClient.redirecting {
            webClient.redirecting = false;
            return;
        }

        if !webClient.callback.isUndefined && !webClient.callback.isNull {
            jsLogger.logVerbose("(*) Calling callback...");
            webClient.callback.callWithArguments([false]);
        }
    }

    internal func webView(sender: WebView!, willCloseFrame frame: WebFrame!) {
        jsLogger.logVerbose("(*) Closing frame...");
    }

    internal func webView(sender: WebView!, didFailLoadWithError error: NSError!, forFrame frame: WebFrame!) {
        jsLogger.logError("(*) Navigating to webpage failed with error: \(error.localizedDescription)")
    }
    
    internal func webView(sender: WebView!, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame: WebFrame!) {
        let alert = NSAlert();
        alert.messageText = message;
        alert.runModal();
    }
    
}
