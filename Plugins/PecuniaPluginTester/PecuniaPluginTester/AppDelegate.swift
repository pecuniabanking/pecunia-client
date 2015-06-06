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
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, JSLogger, NSFilePresenter {

  @IBOutlet weak var window: NSWindow!;
  @IBOutlet weak var pluginFileTextField: NSTextField!;
  @IBOutlet var logTextView: NSTextView!;
  @IBOutlet weak var autoLoadCheckbox: NSButton!

  @IBOutlet weak var detailsTextField: NSTextField!;
  @IBOutlet weak var userNameTextField: NSTextField!;
  @IBOutlet weak var passwordTextField: NSTextField!;
  @IBOutlet weak var fromDatePicker: NSDatePicker!
  @IBOutlet weak var toDatePicker: NSDatePicker!
  @IBOutlet weak var accountsTextField: NSTextField!
  @IBOutlet weak var logLevelSelector: NSPopUpButton!

  private var context: PluginContext? = nil;
  private var webBrowser: NSWindow? = nil;

  private var redirecting = false;
  private var lastChangeDate: NSDate? = nil;

  func applicationDidFinishLaunching(aNotification: NSNotification) {

    toDatePicker.dateValue = NSDate();

    let defaults = NSUserDefaults.standardUserDefaults();

    // Initialize webInspector.
    defaults.setBool(true, forKey: "WebKitDeveloperExtras");
    defaults.synchronize();

    if let name = defaults.stringForKey("pptScriptPath") {
      pluginFileTextField.stringValue = name;

      var error: NSError?;
      if let attributes = NSFileManager.defaultManager().attributesOfItemAtPath(pluginFileTextField.stringValue, error: &error) {
        lastChangeDate = attributes[NSFileModificationDate] as! NSDate?;
      }
    }

    if let user = defaults.stringForKey("pptLoginUser") {
      userNameTextField.stringValue = user;
    }

    if let password = defaults.stringForKey("pptLoginPassword") {
      passwordTextField.stringValue = password;
    }

    if let fromDate: AnyObject = defaults.objectForKey("pptFromDate") where fromDate.isKindOfClass(NSDate) {
      fromDatePicker.dateValue = fromDate as! NSDate;
    }

    if let toDate: AnyObject = defaults.objectForKey("pptToDate")  where toDate.isKindOfClass(NSDate) {
      toDatePicker.dateValue = toDate as! NSDate;
    }

    if let accounts = defaults.stringForKey("pptAccounts") {
      accountsTextField.stringValue = accounts;
    }

    if let logLevel: AnyObject = defaults.objectForKey("pptLogLevel") {
      logLevelSelector.selectItemAtIndex((logLevel as! NSNumber).integerValue);
    } else {
      logLevelSelector.selectItemAtIndex(3);
    }

    if defaults.boolForKey("pptAutoLoad") {
      autoLoadCheckbox.state = NSOnState;
      if NSFileManager.defaultManager().fileExistsAtPath(pluginFileTextField.stringValue) {
        loadScript(self);
        NSFileCoordinator.addFilePresenter(self);
      }
    }

    logIntern("Ready");
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
    NSFileCoordinator.removeFilePresenter(self);
  }

  @IBAction func selectScriptFile(sender: AnyObject) {
    NSFileCoordinator.removeFilePresenter(self);

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

      NSFileCoordinator.addFilePresenter(self);
    }
  }

  @IBAction func close(sender: AnyObject) {
    NSApplication.sharedApplication().terminate(self);
  }

  // MARK: - File Presenter protocol

  var presentedItemURL: NSURL? {
    return NSURL(fileURLWithPath: pluginFileTextField.stringValue);
  }

  var operationQueue = NSOperationQueue();
  var presentedItemOperationQueue: NSOperationQueue {
    return operationQueue;
  }

  var pendingRefresh: dispatch_cancelable_block_t? = nil;

  func presentedItemDidChange() {
    var error: NSError?;
    if let attributes = NSFileManager.defaultManager().attributesOfItemAtPath(pluginFileTextField.stringValue, error: &error) {
      let date = attributes[NSFileModificationDate] as! NSDate?;
      if lastChangeDate != nil && lastChangeDate == date {
        return;
      }
      lastChangeDate = date;
    }

    dispatch_async(dispatch_get_main_queue(), {
      self.pendingRefresh = nil;
      self.logIntern("Reloading plugin");
      self.loadScript(self);
    });
  }

  // MARK: - Logging

  private let logFont = NSFont(name: "LucidaConsole", size: 13);

  @objc func logError(message: String) -> Void {
    let text = String(format: "[Error] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.redColor()]));
  };

  @objc func logWarning(message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 1 {
      return;
    }

    let text = String(format: "[Warning] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor(red: 0.95, green: 0.75, blue: 0, alpha: 1)]));
  };

  @objc func logInfo(message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 2 {
      return;
    }

    let text = String(format: "[Info] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!]));
  };

  @objc func logDebug(message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 3 {
      return;
    }

    let text = String(format: "[Debug] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.darkGrayColor()]));
  };

  @objc func logVerbose(message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 4 {
      return;
    }

    let text = String(format: "[Verbose] %@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor.grayColor()]));
  };

  func logIntern(message: String) -> Void {
    let text = String(format: "%@\n", message);
    logTextView.textStorage!.appendAttributedString(NSAttributedString(string: text,
      attributes: [NSFontAttributeName: logFont!, NSForegroundColorAttributeName: NSColor(calibratedRed: 0.3, green: 0.5, blue: 0.3, alpha: 1)]));
  };

  // MARK: - User Interaction

  @IBAction func clearLog(sender: AnyObject) {
    logTextView.string = "";
  }

  @IBAction func logLevelChanged(sender: AnyObject) {
    let defaults = NSUserDefaults.standardUserDefaults();
    defaults.setInteger(logLevelSelector.indexOfSelectedItem, forKey: "pptLogLevel");
  }

  @IBAction func loadScript(sender: AnyObject) {
    logIntern("Loading script...");

    if webBrowser == nil {
      let frame = NSRect(x: 0, y: 0, width: 900, height: 900);
      webBrowser = NSWindow(contentRect: frame, styleMask: NSTitledWindowMask | NSClosableWindowMask
        | NSMiniaturizableWindowMask | NSResizableWindowMask | NSFullSizeContentViewWindowMask,
        backing: .Buffered, defer: false);
      webBrowser?.releasedWhenClosed = false;
    }

    context = PluginContext(pluginFile: pluginFileTextField.stringValue, logger: self,
      hostWindow: webBrowser!);
    if context == nil {
      detailsTextField.stringValue = "Loading failed";
      logError("Loading plugin script failed.");
      return;
    }

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

    logIntern("Loading done");
  }


  @IBAction func getStatements(sender: AnyObject) {
    if context == nil {
      logError("Plugin not loaded");
      return;
    }

    let user = userNameTextField.stringValue;
    let password = passwordTextField.stringValue;
    let fromDate = fromDatePicker.dateValue;
    let toDate = toDatePicker.dateValue;
    let accountString = accountsTextField.stringValue;

    let defaults = NSUserDefaults.standardUserDefaults();
    defaults.setObject(user, forKey: "pptLoginUser");
    defaults.setObject(password, forKey: "pptLoginPassword");
    defaults.setObject(fromDate, forKey: "pptFromDate");
    defaults.setObject(toDate, forKey: "pptToDate");
    defaults.setObject(accountString, forKey: "pptAccounts");

    var accounts = accountString.componentsSeparatedByString(",");
    if count(accounts) == 0 {
      logError("No accounts specified");
      return;
    }

    for (var i = 0; i < count(accounts); i++) {
      accounts[i] = String(filter(accounts[i]) { $0 != " " });
    }

    context!.getStatements(user, bankCode: "12003000", password: password, fromDate: fromDate,
      toDate: toDate, accounts: accounts) { (values: [BankQueryResult]) -> Void in
        let text = values.description;
        self.logIntern("");
        self.logIntern("Results (\(values.count)):");
        for value in values {
          if value.account != nil {
            self.logIntern("  Result for \(value.account!.accountNumber) (bank code: \(value.account!.bankCode)):");
          } else {
            self.logIntern("  Result for unknown account:");
          }
          self.logIntern("    type: \(value.type)");
          self.logIntern("    ccNumber: \(value.ccNumber)");
          self.logIntern("    lastSettleDate:\(value.lastSettleDate) ");
          self.logIntern("    balance: \(value.balance)");
          self.logIntern("    oldBalance: \(value.oldBalance)");
          self.logIntern("    statements (\(value.statements.count)):");

          for statement in value.statements {
            self.logIntern("      isPreliminary: \(statement.isPreliminary)");
            self.logIntern("      date: \(statement.date)");
            self.logIntern("      valutaDate: \(statement.valutaDate)");
            self.logIntern("      value: \(statement.value)");
            self.logIntern("      origValue: \(statement.origValue)");
            self.logIntern("      purpose: \(statement.purpose)");
            self.logIntern("");
          }

          self.logIntern("    standing orders (\(value.standingOrders.count)):");
          for order in value.standingOrders {
            self.logIntern("      order");
          }

          self.logIntern("");
        }

        self.logIntern("--------------------------------------------------------------------------");
        self.logIntern("");
    };

  }

  @IBAction func dumpHTML(sender: AnyObject) {
    if context != nil {
      let html = context!.getCurrentHTML();
      logIntern(html);
    }
  }

  @IBAction func showBrowser(sender: AnyObject) {
    if webBrowser != nil {
      webBrowser!.orderFrontRegardless();
    } else {
      logError("Plugin not loaded");
    }
  }
  
  @IBAction func autoLoadChanged(sender: AnyObject) {
    let defaults = NSUserDefaults.standardUserDefaults();
    if autoLoadCheckbox.state == NSOnState {
      defaults.setBool(true, forKey: "pptAutoLoad");
      NSFileCoordinator.addFilePresenter(self);
    } else {
      defaults.setBool(false, forKey: "pptAutoLoad");
      NSFileCoordinator.removeFilePresenter(self);
    }
  }

}

