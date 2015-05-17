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

import Cocoa;
import WebKit;

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, JSLogger {

  @IBOutlet weak var window: NSWindow!;
  @IBOutlet weak var pluginFileTextField: NSTextField!;
  @IBOutlet var logTextView: NSTextView!;

  @IBOutlet weak var variablesTableView: NSTableView!;

  @IBOutlet weak var detailsTextField: NSTextField!;
  @IBOutlet weak var userNameTextField: NSTextField!;
  @IBOutlet weak var passwordTextField: NSTextField!;

  private var context: PluginContext? = nil;

  private var redirecting = false;

  private var variables: [[String: String]] = [];

  func applicationDidFinishLaunching(aNotification: NSNotification) {

    let defaults = NSUserDefaults.standardUserDefaults();
    if let name = defaults.stringForKey("pptScriptPath") {
      pluginFileTextField.stringValue = name;
    }

    if let user = defaults.stringForKey("pptLoginUser") {
      userNameTextField.stringValue = user;
    }

    if let password = defaults.stringForKey("pptLoginPassword") {
      passwordTextField.stringValue = password;
    }

    logIntern("Ready");
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }

  @IBAction func selectScriptFile(sender: AnyObject) {
    let panel = NSOpenPanel();
    panel.title = "Select Plugin File (*.js)";
    panel.canChooseDirectories = false;
    panel.canChooseFiles = true;
    panel.allowsMultipleSelection = false;
    panel.allowedFileTypes = ["js"];

    let runResult = panel.runModal();
    if runResult == NSModalResponseOK && panel.URL != nil {
      pluginFileTextField.stringValue = panel.URL!.path!;

      let defaults = NSUserDefaults.standardUserDefaults();
      defaults.setObject(panel.URL!.path!, forKey: "pptScriptPath");
    }
  }

  @IBAction func close(sender: AnyObject) {
    NSApplication.sharedApplication().terminate(self);
  }

  override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
    logIntern("Info: navigating to: " + sender.mainFrameURL);
    
    if redirecting {
      redirecting = false;
      return;
    }

    if sender.mainFrame == frame {

      /*
      view.stringByEvaluatingJavaScriptFromString("function description() {var element = document.evaluate( \"//input[@maxlength='16']\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null ); return element.singleNodeValue.textContent;}");

      var function: JSValue = context.objectForKeyedSubscript("description");
      logIntern(function.callWithArguments([]).toString());

      view.stringByEvaluatingJavaScriptFromString("function description2() {var formLogin = document.evaluate(\"//form[@name='login']\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null ); return formLogin;}");

      function = context.objectForKeyedSubscript("description2");
      logIntern(function.callWithArguments([]).toString());
*/
      // After loading a webpage the entire JS context is cleared and filled with data from the
      // webpage, hence we have to reload everything again.
      updateVariables();

      //let html = view.stringByEvaluatingJavaScriptFromString("document.documentElement.outerHTML");
      //logIntern(html);
    }
  }

  // MARK: - Logging

  private let logFont = NSFont(name: "LucidaConsole", size: 13);

  @objc func logError(message: String) -> Void {
    let text = String(format: "[Error] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.redColor()]));
  };

  @objc func logWarning(message: String) -> Void {
    let text = String(format: "[Warning] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor(red: 0.95, green: 0.75, blue: 0, alpha: 1)]));
  };

  @objc func logInfo(message: String) -> Void {
    let text = String(format: "[Info] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!]));
  };

  @objc func logDebug(message: String) -> Void {
    let text = String(format: "[Debug] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.darkGrayColor()]));
  };

  @objc func logVerbose(message: String) -> Void {
    let text = String(format: "[Verbose] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.grayColor()]));
  };

  func logIntern(message: String) -> Void {
    let text = String(format: "==> %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.grayColor()]));
  };
  
  // MARK: - Application Logic

  // Updates display for all global vars in the context (vars defined on global level, not in functions
  // objects etc.).
  private func updateVariables() {
    if context != nil {
      variables = context!.getVariables();
    }

    variablesTableView.reloadData();
  }
  
  // MARK: - User Interaction

  @IBAction func clearLog(sender: AnyObject) {
    logTextView.string = "";
  }

  @IBAction func loadScript(sender: AnyObject) {
    logIntern("Loading script...");

    context = PluginContext(pluginFile: pluginFileTextField.stringValue, logger: self, hostWindow: window);
    if context == nil {
      detailsTextField.stringValue = "Loading failed";
      logError("Loading plugin script failed.");
      return;
    }

    context?.navigateTo("http://localhost");
    let bundle = NSBundle(forClass: AppDelegate.self);
    if let scriptPath = bundle.pathForResource("debug-helper", ofType: "js", inDirectory: "") {
      if let script = String(contentsOfFile: scriptPath, encoding: NSUTF8StringEncoding, error: nil) {
        context?.addDebugScript(script);
      }
    }

    var text: String;
    let (name, author, description, homePage, license, version) = context!.pluginInfo();

    if count(name) == 0 || name == "undefined" {
      logIntern("Plugin name missing or empty");
      text = "<plugin name not found>";
    } else {
      if !name.hasPrefix("pecunia.plugin.") {
        logIntern("Warning: plugin name doesn't contain 'pecunia.plugin.' prefix and will not be recognized");
      }
      text = name;
    }

    if count(description) == 0 || description == "undefined" {
      logIntern("Warning: plugin description not found");
      text += ", <description not found>";
    } else {
      text += ", " + description.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
    }

    detailsTextField.stringValue = text;
    updateVariables();
  }


  @IBAction func logIn(sender: AnyObject) {

    if context == nil {
      logError("Load plugin first");
      return;
    }

    let defaults = NSUserDefaults.standardUserDefaults();
    defaults.setObject(userNameTextField.stringValue, forKey: "pptLoginUser");
    defaults.setObject(passwordTextField.stringValue, forKey: "pptLoginPassword");

    let scriptFunction: JSValue = context!.getFunction("logIn");
    if scriptFunction.isUndefined() {
      logIntern("Error: logIn() not found");
      return;
    }

    let result = scriptFunction.callWithArguments([userNameTextField.stringValue, passwordTextField.stringValue]);

    if result.toBool() {
      logIntern("Login process successfully started");
    } else {
      logIntern("Login process setup failed");
    }

    updateVariables();
  }

  @IBAction func logOut(sender: AnyObject) {
    if context == nil {
      logError("Load plugin first");
      return;
    }

    let scriptFunction: JSValue = context!.getFunction("logOut");
    if scriptFunction.isUndefined() {
      logIntern("Error: logOut() not found");
      return;
    }

    let result = scriptFunction.callWithArguments([]);

    if result.toBool() {
      logIntern("Logout process successfully started");
    } else {
      logIntern("Logout process setup failed");
    }

    updateVariables();
  }

  @IBAction func getStatements(sender: AnyObject) {
    /*
    if context == nil {
    logError("Load plugin first");
    return;
    }


    let scriptFunction: JSValue = context.objectForKeyedSubscript("getStatements");
    if scriptFunction.isUndefined() {
      log(-1, message: "Error: getStatements() not found");
      return;
    }

    var fromDate: NSDate = NSDate();
    /*
    if from != nil {
    fromDate = from!.lowDate();
    }
    */
    var toDate: NSDate = NSDate();
    /*
    if to != nil {
    toDate = to!.lowDate();
    }
    */

    let result = scriptFunction.callWithArguments([fromDate, toDate]);

    if !result.isUndefined() {
      log(-1, message: "Successfully received statements");
    } else {
      log(-1, message: "Getting statements failed");
    }
*/
    updateVariables();
  }

  @IBAction func dumpHTML(sender: AnyObject) {
    if context != nil {
      let html = context!.getCurrentHTML();
      logIntern(html);
    }
  }

  /// MARK: TableView delegate functions

  func numberOfRowsInTableView(tableView: NSTableView) -> Int
  {
    return variables.count;
  }

  func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
    return variables[row][tableColumn!.identifier];
  }

}

