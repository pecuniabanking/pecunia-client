//
//  ChipcardManager.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 24.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

var _manager:ChipcardManager!

@objc public class CardBankData : NSObject  {
    var name:String;
    var bankCode:String;
    var country:String;
    var host:String;
    var userId:String;
    
    init(name:String, bankCode:String, country:String, host:String, userId:String) {
        self.name = name; self.bankCode = bankCode; self.country = country; self.host = host; self.userId = userId;
    }
    
    
}

@objc public class ChipcardManager : NSObject {
    var card: HBCISmartcardDDV!;
    
    public override init() {
        super.init();
    }
    
    func stringToBytes(s:NSString) ->NSData {
        let buffer = UnsafeMutablePointer<UInt8>.alloc(s.length/2);
        
        for var i = 0; i < s.length/2; i++ {
            var value:UInt32 = 0;
            let hexString = s.substringWithRange(NSMakeRange(2*i, 2));
            let scanner = NSScanner(string: hexString);
            scanner.scanHexInt(&value);
            buffer[i] = UInt8(value & 0xff);
        }
        
        let result = NSData(bytes: buffer, length: s.length/2);
        buffer.destroy();
        return result;
    }
    
    func bytesToString(data:NSData) ->NSString {
        let ret = NSMutableString();
        let p = UnsafeMutablePointer<UInt8>(data.bytes);
        for var i = 0; i<data.length; i++ {
            ret.appendFormat("%0.2X", p[i]);
        }
        return ret;
    }
    
    public func isCardConnected() ->Bool {
        if card != nil {
            return card.isConnected();
        }
        return false;
    }
    
    
    public func getReaders() ->Array<String>? {
        return HBCISmartcardDDV.readers();
    }
    
    public func connectCard(userIdName:String?) ->Bool {
        // check if reader is still available
        if !card.isReaderConnected() {
            let alert = NSAlert();
            alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
            alert.messageText = NSLocalizedString("AP366", comment: "");
            alert.runModal();
            return false;            
        }
        
        if !card.isConnected() {
            var result = card.connect(1);
            if result == HBCISmartcard.ConnectResult.not_supported {
                let alert = NSAlert();
                alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                alert.messageText = NSLocalizedString("AP365", comment: "");
                alert.runModal();
                return false;
            }
            if result == HBCISmartcard.ConnectResult.no_card {
                // no card inserted. Open dialog to wait for it
                let controller = ChipcardRequestController(windowNibName: "ChipcardRequestController");
                controller._userIdName = userIdName;
                if NSApp.runModalForWindow(controller.window!) == 1 {
                    // cancelled
                    return false;
                }
                result = controller.connectResult;
            }
            
            // verify card
            let notificationController = NotificationWindowController(message: NSLocalizedString("AP351", comment:""), title: NSLocalizedString("AP357", comment:""));
            notificationController.showWindow(self);
            notificationController.window?.makeKeyAndOrderFront(self);
            if !card.verifyPin() {
                notificationController.window?.close();
                return false;
            }
            notificationController.window?.close();
        }
        return true;
    }
    
    public func requestCardForUser(user:BankUser) ->Bool {
        if card == nil {
            // no card  object created yet
            if let readers = HBCISmartcardDDV.readers() {
                if readers.count == 0 {
                    // no card readers found
                    let alert = NSAlert();
                    alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                    alert.messageText = NSLocalizedString("AP364", comment: "");
                    alert.runModal();
                    return false;
                }
                let idx = user.ddvReaderIdx.integerValue
                if idx >= readers.count {
                    return false;
                }
                let readerName = readers[idx];
                card = HBCISmartcardDDV(readerName: readerName);
            } else {
                let alert = NSAlert();
                alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                alert.messageText = NSLocalizedString("AP364", comment: "");
                alert.runModal();
                return false;
            }
        }
        
        // connect card
        if !connectCard(user.name) {
            return false;
        }
        
        // check user
        if let bankData = card.getBankData(1) {
            if bankData.userId == user.userId {
                return true;
            } else {
                // card is connected but wrong user
                logError("HBCIChipcard: card inserted but wrong user(%@)", bankData.userId);
                let alert = NSAlert();
                alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                let msg = String(format: NSLocalizedString("AP362", comment: ""), bankData.userId, user.userId);
                alert.messageText = msg;
                alert.runModal();
                return false;
            }
        } else {
            logError("Chipcard: bank data could not be read");
            let alert = NSAlert();
            alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
            alert.messageText = NSLocalizedString("AP363", comment: "");
            alert.runModal();
            return false;
        }
    }
    
    public func requestCardForReader(readerName:String) ->Bool {
        if card == nil {
            card = HBCISmartcardDDV(readerName: readerName);
        } else if card.readerName != readerName {
            card.disconnect();
            card = HBCISmartcardDDV(readerName: readerName);
        }
        
        // connect card
        return connectCard(nil);
    }
    
    public func initializeChipcard(paramString:NSString) ->NSString? {
        let params = paramString.componentsSeparatedByString("|");
        
        if params.count != 2 {
            logError("wrong parameters for chipcard initialization");
            return nil;
        }
        
        // card should already be initialized...
        if card == nil {
            return nil;
        }
        
        /*
        if !card.getCardID() {
            logError("Card ID could not be read");
            return nil;
        }
            
        if let cid = card.cardID, cnumber = card.cardNumber {
            return NSString(format: "%@|%@", bytesToString(cid), cnumber);
        }
        */
        return nil;
    }
    
    public func getBankData() ->CardBankData? {
        if let data = card.getBankData(1) {
            return CardBankData(name: data.name, bankCode: data.bankCode, country: data.country, host: data.host, userId: data.userId);
        }
        return nil;
    }
    
    public func readBankData(paramString:NSString) ->NSString? {
        let idx = paramString.integerValue;
        
        if let data = card.getBankData(idx) {
            return NSString(format: "%@|%@|%@|%@", data.country, data.bankCode, data.host, data.userId);
        }
        return nil;
    }
    
    public func readKeyData(paramString:NSString) ->NSString? {
        /*
        let sigid = card.getSignatureId();
        
        if sigid == 0xffff {
            logError("Could not read signature id");
            return nil;
        }
        
        let keys = card.getKeyData();
        if keys.count != 2 {
            logError("Error reading key information from chipcard");
            return nil;
        }
        return NSString(format: "%d|%i|%i|%i|%i", sigid, keys[0].keyNumber, keys[0].keyVersion, keys[1].keyNumber, keys[1].keyVersion);
        */
        return nil;
    }
    
    public func enterPin(paramString:NSString) ->Bool {
        //return card.verifyPin();
        // card should already been verified
        return true;
    }
    
    public func saveSigId(paramString:NSString) ->Bool {
        //let sigid = paramString.integerValue;
        /*
        if !card.writeSignatureId(sigid) {
            logError("Error while saving new signature id to chipcard");
            return false;
        }
        */
        return true;
    }
    
    public func sign(paramString:NSString) ->NSString? {
        //let hash = stringToBytes(paramString);
        /*
        if let sig = card.sign(hash) {
            return bytesToString(sig);
        }
        */
        return nil;
    }
    
    public func encrypt(paramString:NSString) ->NSString? {
        //let keyNum = paramString.integerValue;
        /*
        if let keys = card.getEncryptionKeys(UInt8(keyNum)) {
            return NSString(format: "%@|%@", bytesToString(keys.plain), bytesToString(keys.encrypted));
        }
        */
        return nil;
    }
    
    public func decrypt(paramString:NSString) ->NSString? {
        let params = paramString.componentsSeparatedByString("|");
        if params.count != 2 {
            logError("missing parameters for decrypt");
            return nil;
        }
        
        //let keyNum = Int(params[0])!;
        //let encKey = params[1] as NSString;
        /*
        if let plain = card.decryptKey(UInt8(keyNum), encrypted: stringToBytes(encKey)) {
            return bytesToString(plain);
        }
        */
        return nil;
    }
    
    public func close() {
        if card != nil {
            card.disconnect();
            card = nil;
        }
    }
    
    public class func manager() ->ChipcardManager {
        if let manager = _manager {
            return manager;
        } else {
            _manager = ChipcardManager();
            return _manager;
        }
    }
    
    
    
    
}
