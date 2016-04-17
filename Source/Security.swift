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

// Class for parallel running banking requests each with its own authentication need.
internal var serialQueue: dispatch_queue_t = dispatch_queue_create("de.pecunia.auth-queue", DISPATCH_QUEUE_SERIAL);

@objc public class AuthRequest : NSObject {

    private var service: String = "";
    private var account: String = "";

    private var passwordController: PasswordController?;

    public var errorOccured = false;

    public func finishPasswordEntry() -> Void {
        if errorOccured {
            Security.deletePasswordForService(service, account: account);
        }

        if passwordController != nil {
            if !errorOccured {
                let password = passwordController!.result();
                Security.setPassword(password, forService: service, account: account,
                    store: passwordController!.savePassword);
            }

            passwordController!.close();
            passwordController = nil;
        }
    }
    
    public func getPin(bankCode: String, userId: String) -> String {
        service = "Pecunia PIN";
        let s = "PIN_\(bankCode)_\(userId)";
        if s != account {
            if passwordController != nil {
                finishPasswordEntry();
            }
            account = s;
        }

        // Serialize password retrieval (especially password dialogs).
        var result = "<abort>";
        dispatch_sync(serialQueue) {
            let password = Security.passwordForService(self.service, account: self.account);
            if password != nil {
                result = password!;
                return;
            }

            if self.passwordController == nil {
                let user = BankUser.findUserWithId(userId, bankCode: bankCode);
                self.passwordController = PasswordController(text: String(format: NSLocalizedString("AP171", comment: ""),
                    user != nil ? user!.name : userId), title: NSLocalizedString( "AP181", comment: ""));
            } else {
                self.passwordController!.retry();
            }

            let res = NSApp.runModalForWindow(self.passwordController!.window!);
            self.passwordController!.closeWindow();
            if res == 0 {
                let pin = self.passwordController!.result();
                Security.setPassword(pin, forService: self.service, account: self.account, store: false);
                result = pin;
            } else {
                Security.deletePasswordForService(self.service, account: self.account);
                self.errorOccured = true; // Don't save the PIN.
                result = "<abort>";
            }
        }

        return result;
    }

}

@objc public class Security : NSObject {

    public static var currentSigningOption: SigningOption? = nil;

    private static var currentPwService = "";
    private static var currentPwAccount = "";

    private static var passwordCache: [String: String] = [:];
    private static var passwordController: PasswordController?;

    public static func getPasswordForDataFile() -> String {
        currentPwService = "Pecunia";
        currentPwAccount = "DataFile";
        var password = passwordForService(currentPwService, account: currentPwAccount);
        if password == nil {
            if passwordController == nil {
                passwordController = PasswordController(text: NSLocalizedString( "AP163", comment: ""),
                    title: NSLocalizedString("AP162", comment: ""));
            } else {
                passwordController!.retry();
            }

            if NSApp.runModalForWindow(passwordController!.window!) > 0 {
                password = nil;
            } else {
                password = passwordController!.result();
            }

            passwordController!.closeWindow();
        }

        if password == nil || password!.length == 0 {
            return "<abort>"; // Hopefully nobody uses this as password.
        }

        return password!;
    }

    /*
    public static func getNewPassword(data: CallbackData) -> String {
        if let password = passwordForService("Pecunia", account: "DataFile") {
            return password;
        }

        // A local controller here. The member var is used for repeating password queries for the data file.
        let controller = NewPasswordController(text: data.message, title: NSLocalizedString( "AP180", comment: ""));
        if NSApp.runModalForWindow(controller!.window!) != 0 {
            return "<abort>";
        }

        if let password = controller?.result() {
            setPassword(password, forService: "Pecunia", account: "DataFile", store: false);
            return password;
        }
        return "<abort>";
    }

    public static func getTanMethod(data: CallbackData) -> String {
        if currentSigningOption?.tanMethod != nil {
            return currentSigningOption!.tanMethod;
        }

        // TODO: old code, shouldn't be used anymore but stays in as fallback.
        let user = BankUser.findUserWithId(data.userId, bankCode: data.bankCode);
        if user.preferredTanMethod != nil {
            return user.preferredTanMethod.method;
        }

        var tanMethods: [TanMethodOld] = [];
        let methods = data.proposal.componentsSeparatedByString("|");
        for method in methods {
            let tanMethod = TanMethodOld();
            let list = method.componentsSeparatedByString(":");
            tanMethod.function = NSNumber(integer: Int(list[0])!);
            tanMethod.description = list[1];
            tanMethods.append(tanMethod);
        }

        let controller = TanMethodListController(methods: tanMethods);
        if NSApp.runModalForWindow(controller.window!) != 0 {
            return "<abort>";
        }
        return controller.selectedMethod.stringValue;
    }

    public static func removePin(data: CallbackData) -> Void {
        currentPwService = "Pecunia PIN";
        let s = "PIN_\(data.bankCode)_\(data.userId)";
        deletePasswordForService("Pecunia PIN", account: s);
    }

    public static func getTan(data: CallbackData) -> String {
        let user = BankUser.findUserWithId(data.userId, bankCode:data.bankCode);
        if data.proposal != nil && !data.proposal.isEmpty {
            // Flicker code.
            let controller = ChipTanWindowController(code: data.proposal, message: data.message);
            if NSApp.runModalForWindow(controller.window!) == 0 {
                return controller.tan;
            } else {
                return "<abort>";
            }
        }

        let tanWindow = TanWindow(text: String(format: NSLocalizedString("AP172", comment: ""),
            user != nil ? user.name : data.userId, data.message));
        let res = NSApp.runModalForWindow(tanWindow.window!);
        tanWindow.close();
        if res == 0 {
            return tanWindow.result();
        } else {
            return "<abort>";
        }
    }

    public static func getTanMedia(data: CallbackData) -> String {
        if currentSigningOption?.tanMediumName != nil {
            return currentSigningOption!.tanMediumName;
        }

        let controller = TanMediaWindowController(user: data.userId, bankCode: data.bankCode, message: data.message);
        if NSApp.runModalForWindow(controller.window!) == 0 {
            return controller.tanMedia;
        } else {
            return "<abort>";
        }
    }
    */
    
    // TODO: for all keychain functions, they could use a more generic implementation like Locksmith (see Github).
    public static func setPassword(password: String, forService service: String, account: String, store: Bool) -> Bool {
        let key = service + "/" + account;
        passwordCache[key] = password;
        if !store {
            return true;
        }

        let serviceAsUtf8 = (service as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let serviceLength = UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));
        let accountAsUtf8 = (account as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let accountLength = UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));
        let passwordAsUtf8 = (password as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let passwordLength = UInt32(password.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));

        let status = SecKeychainAddGenericPassword(nil, serviceLength, serviceAsUtf8,
            accountLength, accountAsUtf8, passwordLength + 1, passwordAsUtf8, nil); // TODO: why passwordlength + 1?
        if status != noErr {
            passwordCache.removeValueForKey(key);
        }
        return status == noErr;
    }

    public static func passwordForService(service: String, account: String) -> String? {
        let key = service + "/" + account;
        if let password = passwordCache[key] {
            return password;
        }

        let serviceAsUtf8 = (service as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let serviceLength = UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));
        let accountAsUtf8 = (account as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let accountLength = UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));

        var passwordLength: UInt32 = 0;
        var passwordData: UnsafeMutablePointer<Void> = nil;

        let status = SecKeychainFindGenericPassword(nil, serviceLength, serviceAsUtf8, accountLength, accountAsUtf8,
            &passwordLength, &passwordData, nil);


        if (status != noErr) {
            return nil;
        }

        if let password = NSString(UTF8String: UnsafeMutablePointer<Int8>(passwordData)) {
            passwordCache[key] = password as String;

            SecKeychainItemFreeContent(nil, passwordData);
            return password as String;
        }
        return nil;
    }

    public static func deletePasswordForService(service: String, account: String) -> Void {
        let key = service + "/" + account;
        passwordCache.removeValueForKey(key);

        let serviceAsUtf8 = (service as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let serviceLength = UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));
        let accountAsUtf8 = (account as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let accountLength = UInt32(account.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));

        var itemRef: SecKeychainItem? = nil;
        let status = SecKeychainFindGenericPassword(nil, serviceLength, serviceAsUtf8, accountLength,
            accountAsUtf8, nil, nil, &itemRef);

        if status == noErr {
            if itemRef != nil {
                SecKeychainItemDelete(itemRef!);
            }
        }
    }

    public static func deletePasswordsForService(service: String) -> Void {
        let serviceAsUtf8 = (service as NSString).cStringUsingEncoding(NSUTF8StringEncoding);
        let serviceLength = UInt32(service.lengthOfBytesUsingEncoding(NSUTF8StringEncoding));
        var status: OSStatus;
        var itemRef: SecKeychainItem? = nil;

        passwordCache.removeAll(keepCapacity: false);

        repeat {
            status = SecKeychainFindGenericPassword(nil, serviceLength, serviceAsUtf8, 0, nil, nil,
                nil, &itemRef);

            if status == noErr && itemRef != nil {
                SecKeychainItemDelete(itemRef!);
                itemRef = nil;
            }
        } while status == noErr && itemRef != nil;
    }
}
