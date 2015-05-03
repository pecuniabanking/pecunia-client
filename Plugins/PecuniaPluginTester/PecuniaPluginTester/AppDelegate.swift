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
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource {

  @IBOutlet weak var window: NSWindow!;
  @IBOutlet weak var pluginFileTextField: NSTextField!;
  @IBOutlet var logTextView: NSTextView!;

  @IBOutlet weak var functionNamesTableView: NSTableView!;
  @IBOutlet weak var variablesTableView: NSTableView!;

  @IBOutlet weak var detailsTextField: NSTextField!;
  @IBOutlet weak var userNameTextField: NSTextField!;
  @IBOutlet weak var passwordTextField: NSTextField!;

  private let view = WebView();
  private var redirecting = false;
  private var jsScriptFile = "";

  private var functionNames: [String] = [];
  private var variables: [[String: String]] = [];

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    view.frameLoadDelegate = self;
    view.hostWindow = window;

    let defaults = NSUserDefaults.standardUserDefaults();
    if let name = defaults.stringForKey("pptScriptPath") {
      pluginFileTextField.stringValue = name;
    }

    // To get an initial DOM.
    view.mainFrame.loadHTMLString("<p></p>", baseURL: NSURL(string: "http://localhost"));
    logIntern("Ready");
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }

  @IBAction func selectScriptFile(sender: AnyObject) {
    let panel = NSOpenPanel();
    panel.title = "Select Plugin File (*.xml)";
    panel.canChooseDirectories = false;
    panel.canChooseFiles = true;
    panel.allowsMultipleSelection = false;
    panel.allowedFileTypes = ["xml"];

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

  func printDescription(context: JSContext) {
    let value: JSValue = context.objectForKeyedSubscript("screenW");
    println(value);

    let function: JSValue = context.objectForKeyedSubscript("description");
    println(function.callWithArguments([]).toString());
  }

  override func webView(sender: WebView!, willPerformClientRedirectToURL URL: NSURL!,
    delay seconds: NSTimeInterval, fireDate date: NSDate!, forFrame frame: WebFrame!) {
      //redirecting = true;
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
      prepareContext();

      if count(jsScriptFile) > 0 {
        var path = pluginFileTextField.stringValue.stringByDeletingLastPathComponent;
        path = path.stringByAppendingPathComponent(jsScriptFile);
        //jsScriptFile = "";
        if let script = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
          let parseResult = view.stringByEvaluatingJavaScriptFromString(script);
          if parseResult != "true" {
            logIntern("Error: parsing the script failed");
          }
        } else {
          logIntern("Error: couldn't load script file from: " + path);
        }
      }

      updateFunctionNames(view.mainFrame.javaScriptContext);
      updateVariables(view.mainFrame.javaScriptContext);

      //let html = view.stringByEvaluatingJavaScriptFromString("document.documentElement.outerHTML");
      //logIntern(html);
    }
  }

  /// MARK: - Setup
  private func prepareContext() {

    let context = view.mainFrame.javaScriptContext;

    context.setObject(false, forKeyedSubscript: "JSError");
    context.exceptionHandler = { context, exception in
      self.logIntern("JS Error: " + exception.toString());
      context.setObject(true, forKeyedSubscript: "JSError");
    }

    // Similar for logging.
    let logErrorFunction: @objc_block (String!) -> Void = { self.logError($0); };
    context.setObject(unsafeBitCast(logErrorFunction, AnyObject.self), forKeyedSubscript: "logError");
    let logWarningFunction: @objc_block (String!) -> Void = { self.logWarning($0); };
    context.setObject(unsafeBitCast(logWarningFunction, AnyObject.self), forKeyedSubscript: "logWarning");
    let logInfoFunction: @objc_block (String!) -> Void = { self.logInfo($0); };
    context.setObject(unsafeBitCast(logInfoFunction, AnyObject.self), forKeyedSubscript: "logInfo");
    let logDebugFunction: @objc_block (String!) -> Void = { self.logDebug($0); };
    context.setObject(unsafeBitCast(logDebugFunction, AnyObject.self), forKeyedSubscript: "logDebug");
    let logVerboseFunction: @objc_block (String!) -> Void = { self.logVerbose($0); };
    context.setObject(unsafeBitCast(logVerboseFunction, AnyObject.self), forKeyedSubscript: "logVerbose");

    let bundle = NSBundle(forClass: AppDelegate.self);
    if let scriptPath = bundle.pathForResource("debug-helper", ofType: "js", inDirectory: "") {
      if let script = String(contentsOfFile: scriptPath, encoding: NSUTF8StringEncoding, error: nil) {
        view.stringByEvaluatingJavaScriptFromString(script);
      }
    }
  }

  /// MARK: - Log Functions

  private let logFont = NSFont(name: "LucidaConsole", size: 13);

  private func logError(message: String) {
    let text = String(format: "[Error] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.redColor()]));
  }

  private func logWarning(message: String) {
    let text = String(format: "[Warning] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor(red: 0.95, green: 0.75, blue: 0, alpha: 1)]));
  }
  
  private func logInfo(message: String) {
    let text = String(format: "[Info] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!]));
  }
  
  private func logDebug(message: String) {
    let text = String(format: "[Debug] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.darkGrayColor()]));
  }
  
  private func logVerbose(message: String) {
    let text = String(format: "[Verbose] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.grayColor()]));
  }

  private func logIntern(message: String) {
    let text = String(format: "%@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.grayColor()]));
  }

  // MARK: - Application Logic

  // Updates display for current functions in the context.
  private func updateFunctionNames(context: JSContext) {
    let scriptFunction: JSValue = context.objectForKeyedSubscript("getFunctionNames");
    if scriptFunction.isUndefined() {
      logIntern("Error: getFunctionNames() not found");
      return;
    }

    let result = scriptFunction.callWithArguments([]);
    if let names = result.toArray() {
      functionNames.removeAll(keepCapacity: true);
      for name in names as! [String] {
        functionNames.append(name);
      }
    } else {
      logIntern("Error: getFunctionNames() returned undefined result");
    }

    functionNamesTableView.reloadData();
  }

  // Updates display for all global vars in the context (vars defined on global level, not in functions
  // objects etc.).
  private func updateVariables(context: JSContext) {
    let scriptFunction: JSValue = context.objectForKeyedSubscript("getVariables");
    if scriptFunction.isUndefined() {
      logIntern("Error: getVariables() not found");
      return;
    }

    let result = scriptFunction.callWithArguments([]);
    if let values = result.toArray() {
      variables.removeAll(keepCapacity: true);
      for variable in values as! [String] {
        let parts = (variable as NSString).componentsSeparatedByString(":") as! [String];
        var entries = [String: String]();
        if parts.count > 0 {
          entries["name"] = parts[0];
        }
        if parts.count > 1 {
          entries["type"] = parts[1];
        }
        if parts.count > 2 {
          entries["value"] = parts[2];
        }
        variables.append(entries);
      }
    } else {
      logIntern("Error: getVariables() returned undefined result");
    }

    variablesTableView.reloadData();
  }
  
  // MARK: - User Interaction

  @IBAction func clearLog(sender: AnyObject) {
    logTextView.string = "";
  }

  @IBAction func loadScript(sender: AnyObject) {
    logIntern("Loading script...");

    if let xml = String(contentsOfFile: pluginFileTextField.stringValue, encoding: NSUTF8StringEncoding, error: nil) {

      var error: NSError?;
      let details = NSDictionary.dictForXMLString(xml, error: &error);
      if error != nil {
        detailsTextField.stringValue = "nothing loaded yet";
        logIntern("Error: parsing the plugin xml failed:\n" + error!.localizedDescription);
        return;
      }

      let context = view.mainFrame.javaScriptContext;

      if let plugin = details["plugin"] as? NSDictionary {
        var text = "";
        if let name = plugin["name"] as? NSString {
          if !name.hasPrefix("pecunia.plugin.") {
            logIntern("Warning: plugin name doesn't contain 'pecunia.plugin.' prefix and will not be accepted");
          }
          text = name as! String;
        } else {
          logIntern("Error: descriptor not valid, plugin name attribute not set");
          detailsTextField.stringValue = "missing name";
          return;
        }

        var descriptionText = "";
        if let entry = plugin["description"] as? NSDictionary {
          if let description = entry["text"] as? NSString {
            descriptionText = description.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
          }
        }

        if count(descriptionText) == 0 {
          logIntern("Warning: plugin description not found");
          text += ", <description not found>";
        } else {
          text += ", " + descriptionText;
        }

        detailsTextField.stringValue = text;

        if let name = plugin["name"] as? NSString {
          if !name.hasPrefix("pecunia.plugin.") {
            logIntern("Warning: plugin name doesn't contain 'pecunia.plugin.' prefix and will not be accepted");
          }
          text = name as! String;
        } else {
          logIntern("Error: descriptor not valid, plugin name attribute not set");
          detailsTextField.stringValue = "missing name";
          return;
        }

        // Finally get the initial url to navigate too and trigger script loading.
        if let entry = plugin["script"] as? NSDictionary {
          jsScriptFile = entry["name"] as! String;
        } else {
          logIntern("Error: descriptor not valid, script file not set");
          return;
        }

        if let value = plugin["initialUrl"] as? NSString {
          if let url = NSURL(string: value as! String) {
            view.mainFrame.loadRequest(NSURLRequest(URL: url));
          } else {
            logIntern("Error: initialUrl attribute not a valid URL");
            return;
          }
        } else {
          logIntern("Error: descriptor not valid, initialUrl attribute not set");
          return;
        }

      } else {
        logIntern("Error: plugin descriptor not valid, missing <plugin></plugin> block");
        detailsTextField.stringValue = "wrong descriptor format";
        return;
      }
    } else {
      logIntern("Error: could not load plugin descriptor file.")
    }

    logIntern("Loading succesfully done");
  }

  @IBAction func logIn(sender: AnyObject) {
    let context = view.mainFrame.javaScriptContext;

    let scriptFunction: JSValue = context.objectForKeyedSubscript("logIn");
    if scriptFunction.isUndefined() {
      logIntern("Error: logIn() not found");
      return;
    }

    let result = scriptFunction.callWithArguments([userNameTextField.stringValue, passwordTextField.stringValue]);

    if result.toBool() {
      logIntern("Login successfull");
    } else {
      logIntern("Login failed");
    }
  }

  @IBAction func logOut(sender: AnyObject) {
    let context = view.mainFrame.javaScriptContext;

    let scriptFunction: JSValue = context.objectForKeyedSubscript("logIn");
    if scriptFunction.isUndefined() {
      logIntern("Error: logIn() not found");
      return;
    }

    let result = scriptFunction.callWithArguments([userNameTextField.stringValue, passwordTextField.stringValue]);

    if result.toBool() {
      logIntern("Login successfull");
    } else {
      logIntern("Login failed");
    }
  }

  @IBAction func getStatements(sender: AnyObject) {
    let context = view.mainFrame.javaScriptContext;

    let scriptFunction: JSValue = context.objectForKeyedSubscript("getStatements");
    if scriptFunction.isUndefined() {
      logIntern("Error: getStatements() not found");
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
      logIntern("Successfully received statements");
    } else {
      logIntern("Getting statements failed");
    }
  }

  /// MARK: Data Source Code

  func numberOfRowsInTableView(tableView: NSTableView) -> Int
  {
    if tableView == functionNamesTableView {
      return functionNames.count;
    }
    return variables.count;
  }

  func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
    if tableView == functionNamesTableView {
      return functionNames[row];
    }

    return variables[row][tableColumn!.identifier];
  }

}

