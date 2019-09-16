/**
 * Copyright (c) 2015, 2019, Pecunia Project. All rights reserved.
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

open class AuthRequest {

  var passwordTextField: NSTextField!;

  open var errorOccured = false;

  public static func new() -> AuthRequest {
    return AuthRequest();
  }

  open func finishPasswordEntry() -> Void {
  }

  open func getPin(_ bankCode: String, userId: String) -> String {
    return passwordTextField.stringValue;
  }

}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, JSLogger, NSFilePresenter {

  @IBOutlet weak var window: NSWindow!;
  @IBOutlet weak var pluginFileTextField: NSTextField!;
  @IBOutlet var logTextView: NSTextView!;
  @IBOutlet weak var autoLoadCheckbox: NSButton!

  @IBOutlet weak var detailsTextField: NSTextField!;
  @IBOutlet weak var userNameTextField: NSTextField!;
  @IBOutlet weak var passwordTextField: NSTextField!;
  @IBOutlet weak var bankCodeTextField: NSTextField!
  @IBOutlet weak var fromDatePicker: NSDatePicker!
  @IBOutlet weak var toDatePicker: NSDatePicker!
  @IBOutlet weak var accountsTextField: NSTextField!
  @IBOutlet weak var logLevelSelector: NSPopUpButton!

  fileprivate var context: PluginContext? = nil;
  fileprivate var webBrowser: NSWindow? = nil;
  fileprivate let authRequest = AuthRequest();

  fileprivate var redirecting = false;
  fileprivate var lastChangeDate: Date? = nil;

  func applicationDidFinishLaunching(_ aNotification: Notification) {

    toDatePicker.dateValue = Date();
    authRequest.passwordTextField = passwordTextField;

    let defaults = UserDefaults.standard;

    // Initialize webInspector.
    defaults.set(true, forKey: "WebKitDeveloperExtras");
    defaults.synchronize();

    if let name = defaults.string(forKey: "pptScriptPath") {
      pluginFileTextField.stringValue = name;

        do {
            if let attributes : NSDictionary? = try FileManager.default.attributesOfItem(atPath: pluginFileTextField.stringValue) as NSDictionary?? {
                if let _attr = attributes {
                    lastChangeDate = _attr.fileModificationDate();// as! NSDate?;
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }

    if let user = defaults.string(forKey: "pptLoginUser") {
      userNameTextField.stringValue = user;
    }

    if let password = defaults.string(forKey: "pptLoginPassword") {
      passwordTextField.stringValue = password;
    }

    if let bankCode = defaults.string(forKey: "pptBankCode") {
      bankCodeTextField.stringValue = bankCode;
    }

    /*
    if let fromDate: AnyObject = defaults.object(forKey: "pptFromDate"), as AnyObject? fromDate.isKind(of: Date) {
      fromDatePicker.dateValue = fromDate as! Date;
    }

    if let toDate: AnyObject = defaults.object(forKey: "pptToDate"), as AnyObject? toDate.isKind(of: Date) {
      toDatePicker.dateValue = toDate as! Date;
    }
    */
    
    if let accounts = defaults.string(forKey: "pptAccounts") {
      accountsTextField.stringValue = accounts;
    }

    if let logLevel: AnyObject = defaults.object(forKey: "pptLogLevel") as AnyObject? {
      logLevelSelector.selectItem(at: (logLevel as! NSNumber).intValue);
    } else {
      logLevelSelector.selectItem(at: 3);
    }

    if defaults.bool(forKey: "pptAutoLoad") {
      autoLoadCheckbox.state = NSControl.StateValue.on;
      if FileManager.default.fileExists(atPath: pluginFileTextField.stringValue) {
        loadScript(self);
        NSFileCoordinator.addFilePresenter(self);
      }
    }

    logIntern("Ready");
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
    NSFileCoordinator.removeFilePresenter(self);
  }

  @IBAction func selectScriptFile(_ sender: AnyObject) {
    NSFileCoordinator.removeFilePresenter(self);

    let panel = NSOpenPanel();
    panel.title = "Select Plugin File (*.js)";
    panel.canChooseDirectories = false;
    panel.canChooseFiles = true;
    panel.allowsMultipleSelection = false;
    panel.allowedFileTypes = ["js"];

    let runResult = panel.runModal();
    if runResult == NSApplication.ModalResponse.OK && panel.url != nil {
      pluginFileTextField.stringValue = panel.url!.path;

      let defaults = UserDefaults.standard;
      defaults.set(panel.url!.path, forKey: "pptScriptPath");

      NSFileCoordinator.addFilePresenter(self);
    }
  }

  @IBAction func close(_ sender: AnyObject) {
    NSApplication.shared.terminate(self);
  }

  // MARK: - File Presenter protocol

  var presentedItemURL: URL? {
    return URL(fileURLWithPath: pluginFileTextField.stringValue);
  }

  var operationQueue = OperationQueue();
  var presentedItemOperationQueue: OperationQueue {
    return operationQueue;
  }

  var pendingRefresh: dispatch_cancelable_block_t? = nil;

  func presentedItemDidChange() {
    do {
        if let attributes : NSDictionary? = try FileManager.default.attributesOfItem(atPath: pluginFileTextField.stringValue) as NSDictionary?? {
            
            var date : Date?;
            if let _attr = attributes {
                date = _attr.fileModificationDate();// as! NSDate?;
            }
            
            if lastChangeDate != nil && lastChangeDate == date {
                return;
            }
            lastChangeDate = date;
        }
    } catch {
        
    }

    DispatchQueue.main.async(execute: {
      self.pendingRefresh = nil;
      self.logIntern("Reloading plugin");
      self.loadScript(self);
    });
  }

  // MARK: - Logging

  fileprivate let logFont = NSFont(name: "Menlo", size: 13);

  @objc func logError(_ message: String) -> Void {
    let text = String(format: "[Error] %@\n", message);
    logTextView.textStorage!.append(NSAttributedString(string: text,
      attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): logFont!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor.red])));
  };

  @objc func logWarning(_ message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 1 {
      return;
    }

    let text = String(format: "[Warning] %@\n", message);
    logTextView.textStorage!.append(NSAttributedString(string: text,
      attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): logFont!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor(red: 0.95, green: 0.75, blue: 0, alpha: 1)])));
  };

  @objc func logInfo(_ message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 2 {
      return;
    }

    let text = String(format: "[Info] %@\n", message);
    logTextView.textStorage!.append(NSAttributedString(string: text,
      attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): logFont!])));
  };

  @objc func logDebug(_ message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 3 {
      return;
    }

    let text = String(format: "[Debug] %@\n", message);
    logTextView.textStorage!.append(NSAttributedString(string: text,
      attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): logFont!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor.darkGray])));
  };

  @objc func logVerbose(_ message: String) -> Void {
    if logLevelSelector.indexOfSelectedItem < 4 {
      return;
    }

    let text = String(format: "[Verbose] %@\n", message);
    logTextView.textStorage!.append(NSAttributedString(string: text,
      attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): logFont!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor.gray])));
  };

  func logIntern(_ message: String) -> Void {
    let text = String(format: "%@\n", message);
    logTextView.textStorage!.append(NSAttributedString(string: text,
      attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): logFont!, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): NSColor(calibratedRed: 0.3, green: 0.5, blue: 0.3, alpha: 1)])));
  };

  // MARK: - User Interaction

  @IBAction func clearLog(_ sender: AnyObject) {
    logTextView.string = "";
  }

  @IBAction func logLevelChanged(_ sender: AnyObject) {
    let defaults = UserDefaults.standard;
    defaults.set(logLevelSelector.indexOfSelectedItem, forKey: "pptLogLevel");
  }

  @IBAction func loadScript(_ sender: AnyObject) {
    logIntern("Loading script...");

    if webBrowser == nil {
      let frame = NSRect(x: 0, y: 0, width: 900, height: 900);
        /*
        webBrowser = NSWindow(contentRect: frame, styleMask: NSWindowStyleMask(rawValue: NSWindow.StyleMask.RawValue(UInt8(NSTitledWindowMask.rawValue) | UInt8(NSClosableWindowMask.rawValue)
            | UInt8(NSMiniaturizableWindowMask.rawValue) | UInt8(NSResizableWindowMask.rawValue) | UInt8(NSFullSizeContentViewWindowMask.rawValue))),
        backing: .buffered, defer: false);
        */
        webBrowser = NSWindow(contentRect: frame, styleMask: [NSWindow.StyleMask.closable, NSWindow.StyleMask.fullSizeContentView, NSWindow.StyleMask.resizable, NSWindow.StyleMask.resizable, NSWindow.StyleMask.titled ],
                              backing: .buffered, defer: false);
      webBrowser?.isReleasedWhenClosed = false;
    }

    context = PluginContext(pluginFile: pluginFileTextField.stringValue, logger: self,
      hostWindow: webBrowser!);
    if context == nil {
      detailsTextField.stringValue = "Loading failed";
      logError("Loading plugin script failed.");
      return;
    }

    let bundle = Bundle(for: AppDelegate.self);
    do {
        if let scriptPath : String = bundle.path(forResource: "debug-helper", ofType: "js", inDirectory: "") {
          let script : NSString = try NSString(contentsOfFile: scriptPath, encoding: String.Encoding.utf8.rawValue);
          context?.addDebugScript(script as String);
        }
    }
    catch {/* error handling here */}
    //      if let script = String(contentsOfFile: scriptPath, encoding: NSUTF8StringEncoding, error: nil) {
    //      context?.addDebugScript(script);
    //    }
    

    var text: String;
    let (name, _, description, _, _, _) = context!.pluginInfo();

    if name.count == 0 || name == "undefined" {
      logIntern("Plugin name missing or empty");
      text = "<plugin name not found>";
    } else {
      if !name.hasPrefix("pecunia.plugin.") {
        logIntern("Warning: plugin name doesn't contain 'pecunia.plugin.' prefix and will not be recognized");
      }
      text = name;
    }

    if description.count == 0 || description == "undefined" {
      logIntern("Warning: plugin description not found");
      text += ", <description not found>";
    } else {
      text += ", " + description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
    }

    detailsTextField.stringValue = text;

    logIntern("Loading done");
  }


  @IBAction func getStatements(_ sender: AnyObject) {
    if context == nil {
      logError("Plugin not loaded");
      return;
    }

    let user = userNameTextField.stringValue;
    let password = passwordTextField.stringValue;
    let bankCode = bankCodeTextField.stringValue;
    let fromDate = fromDatePicker.dateValue;
    let toDate = toDatePicker.dateValue;
    let accountString = accountsTextField.stringValue;

    let defaults = UserDefaults.standard;
    defaults.set(user, forKey: "pptLoginUser");
    defaults.set(password, forKey: "pptLoginPassword");
    defaults.set(bankCode, forKey: "pptBankCode");
    defaults.set(fromDate, forKey: "pptFromDate");
    defaults.set(toDate, forKey: "pptToDate");
    defaults.set(accountString, forKey: "pptAccounts");

    
    var accounts = accountString.components(separatedBy: ",");
    if accounts.count == 0 {
      logError("No accounts specified");
      return;
    }

    accounts = accounts.filter{ $0 != " " };
/*    for (var i = 0; i < accounts.count; i++) {
      accounts[i] = String(filter(accounts[i]) { $0 != " " });
    }
*/
    let query = UserQueryEntry(bankCode: bankCode, password: password, accountNumbers: accounts, auth: authRequest);
    context!.getStatements(user, query: query, fromDate: fromDate, toDate: toDate) { (values: [BankQueryResult]) -> Void in
        self.logIntern("");
        self.logIntern("Results (\(values.count)):");
        for value in values {
          if value.account != nil {
            self.logIntern("  Result for \(value.account!.accountNumber) (bank code: \(value.account!.bankCode)):");
          } else {
            self.logIntern("  Result for unknown account:");
          }
          self.logIntern("    type: \(value.type)");
          self.logIntern("    ccNumber: \(String(describing: value.ccNumber))");
          self.logIntern("    lastSettleDate:\(String(describing: value.lastSettleDate)) ");
          self.logIntern("    balance: \(String(describing: value.balance))");
          self.logIntern("    oldBalance: \(String(describing: value.oldBalance))");
          self.logIntern("    statements (\(value.statements.count)):");

          for statement in value.statements {
            self.logIntern("      isPreliminary: \(statement.isPreliminary)");
            self.logIntern("      date: \(String(describing: statement.date))");
            self.logIntern("      valutaDate: \(String(describing: statement.valutaDate))");
            self.logIntern("      value: \(String(describing: statement.value))");
            self.logIntern("      origValue: \(String(describing: statement.origValue))");
            self.logIntern("      purpose: \(String(describing: statement.purpose))");
            self.logIntern("");
          }

          self.logIntern("    standing orders (\(value.standingOrders.count)):");
          for order in value.standingOrders {
            self.logIntern("      order \(order)");
          }

          self.logIntern("");
        }

        self.logIntern("--------------------------------------------------------------------------");
        self.logIntern("");
    };

  }

  @IBAction func dumpHTML(_ sender: AnyObject) {
    if context != nil {
      let html = context!.getCurrentHTML();
      logIntern(html);
    }
  }

  @IBAction func showBrowser(_ sender: AnyObject) {
    if webBrowser != nil {
      webBrowser!.orderFrontRegardless();
    } else {
      logError("Plugin not loaded");
    }
  }
  
  @IBAction func autoLoadChanged(_ sender: AnyObject) {
    let defaults = UserDefaults.standard;
    if autoLoadCheckbox.state == NSControl.StateValue.on {
      defaults.set(true, forKey: "pptAutoLoad");
      NSFileCoordinator.addFilePresenter(self);
    } else {
      defaults.set(false, forKey: "pptAutoLoad");
      NSFileCoordinator.removeFilePresenter(self);
    }
  }

}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
