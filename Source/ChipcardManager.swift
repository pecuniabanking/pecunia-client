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

@objc open class CardBankData : NSObject  {
    var name:String;
    var bankCode:String;
    var country:String;
    var host:String;
    var userId:String;
    
    init(name:String, bankCode:String, country:String, host:String, userId:String) {
        self.name = name; self.bankCode = bankCode; self.country = country; self.host = host; self.userId = userId;
    }
    
    
}

@objc open class ChipcardManager : NSObject {
    var card: HBCISmartcardDDV!;
    
    public override init() {
        super.init();
    }
    
    func stringToBytes(_ s:NSString) ->Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: s.length/2);
        
        for i in 0 ..< s.length/2 {
            var value:UInt32 = 0;
            let hexString = s.substring(with: NSMakeRange(2*i, 2));
            let scanner = Scanner(string: hexString);
            scanner.scanHexInt32(&value);
            buffer[i] = UInt8(value & 0xff);
        }
        
        let result = Data(bytes: UnsafePointer<UInt8>(buffer), count: s.length/2);
        buffer.deinitialize();
        return result;
    }
    
    func bytesToString(_ data:Data) ->NSString {
        let ret = NSMutableString();
        let p = UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count));
        for i in 0 ..< data.count {
            ret.appendFormat("%0.2X", p[i]);
        }
        return ret;
    }
    
    open func isCardConnected() ->Bool {
        if card != nil {
            return card.isConnected();
        }
        return false;
    }
    
    
    open func getReaders() ->Array<String>? {
        return HBCISmartcardDDV.readers();
    }
    
    open func connectCard(_ userIdName:String?) throws {
        // check if reader is still available
        if !card.isReaderConnected() {
            throw NSError.errorWithMsg(msgId: "AP366", titleId: "AP368");
            /*
            let alert = NSAlert();
            alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
            alert.messageText = NSLocalizedString("AP366", comment: "");
            alert.runModal();
            return false;
            */
        }
        
        if !card.isConnected() {
            var result = card.connect(1);
            if result == HBCISmartcard.ConnectResult.not_supported {
                throw NSError.errorWithMsg(msgId: "AP365", titleId: "AP368");
                /*
                let alert = NSAlert();
                alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                alert.messageText = NSLocalizedString("AP365", comment: "");
                alert.runModal();
                return false;
                */
            }
            if result == HBCISmartcard.ConnectResult.no_card {
                // no card inserted. Open dialog to wait for it
                let controller = ChipcardRequestController(windowNibName: "ChipcardRequestController");
                controller._userIdName = userIdName;
                if NSApp.runModal(for: controller.window!) == 1 {
                    // cancelled
                    throw HBCIError.userAbort;
                    //return false;
                }
                result = controller.connectResult;
            }
            
            // verify card
            let controller = ChipcardPinRequestController(windowNibName: "ChipcardPinRequestController");
            if NSApp.runModal(for: controller.window!) == 1 {
                // verification not o.k.
                throw NSError.errorWithMsg(msgId: "AP369", titleId: "AP368");
            }
            /*
            let notificationController = NotificationWindowController(message: NSLocalizedString("AP351", comment:""), title: NSLocalizedString("AP357", comment:""));
            notificationController?.showWindow(self);
            notificationController?.window?.makeKeyAndOrderFront(self);
            if !card.verifyPin() {
                notificationController?.window?.close();
                throw NSError.errorWithMsg(msgId: "AP369", titleId: "AP368");
            }
            notificationController?.window?.close();
            */
        }
    }
    
    open func requestCardForUser(_ user:BankUser) throws {
        if card == nil {
            // no card  object created yet
            if let readers = HBCISmartcardDDV.readers() {
                if readers.count == 0 {
                    // no card readers found
                    throw NSError.errorWithMsg(msgId: "AP364", titleId: "AP368");
                    /*
                    let alert = NSAlert();
                    alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                    alert.messageText = NSLocalizedString("AP364", comment: "");
                    alert.runModal();
                    return false;
                    */
                }
                var idx = user.ddvReaderIdx.intValue
                if idx >= readers.count {
                    logWarning("Index in user information is wrong");
                    idx = 0;
                }
                let readerName = readers[idx];
                card = HBCISmartcardDDV(readerName: readerName);
            } else {
                throw NSError.errorWithMsg(msgId: "AP364", titleId: "AP368");
                /*
                let alert = NSAlert();
                alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                alert.messageText = NSLocalizedString("AP364", comment: "");
                alert.runModal();
                return false;
                */
            }
        }
        
        // connect card
        try connectCard(user.name);
        
        // check user
        if let bankData = card.getBankData(1) {
            if bankData.userId == user.userId {
                return;
            } else {
                // card is connected but wrong user
                logError("HBCIChipcard: card inserted but wrong user(%@)", bankData.userId);
                throw NSError.errorWithMsg(msgId: "AP362", titleId: "AP368");
                /*
                let alert = NSAlert();
                alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
                let msg = String(format: NSLocalizedString("AP362", comment: ""), bankData.userId, user.userId);
                alert.messageText = msg;
                alert.runModal();
                return false;
                */
            }
        } else {
            logError("Chipcard: bank data could not be read");
            throw NSError.errorWithMsg(msgId: "AP363", titleId: "AP368");
            /*
            let alert = NSAlert();
            alert.alertStyle = NSAlertStyle.CriticalAlertStyle;
            alert.messageText = NSLocalizedString("AP363", comment: "");
            alert.runModal();
            return false;
            */
        }
    }
    
    open func requestCardForReader(_ readerName:String) throws {
        if card == nil {
            card = HBCISmartcardDDV(readerName: readerName);
        } else if card.readerName != readerName {
            card.disconnect();
            card = HBCISmartcardDDV(readerName: readerName);
        }
        
        // connect card
        try connectCard(nil);
    }
    
    open func initializeChipcard(_ paramString:NSString) ->NSString? {
        let params = paramString.components(separatedBy: "|");
        
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
    
    open func getBankData() ->CardBankData? {
        if let data = card.getBankData(1) {
            return CardBankData(name: data.name, bankCode: data.bankCode, country: data.country, host: data.host, userId: data.userId);
        }
        return nil;
    }
    
    open func writeBankData(_ data:CardBankData) ->Bool {
        let hbciData = HBCICardBankData(name: data.name, bankCode: data.bankCode, country: data.country, host: data.host, hostAdd: "", userId: data.userId, commtype: 0);
        return card.writeBankData(1, data: hbciData);
    }
    
    open func readBankData(_ paramString:NSString) ->NSString? {
        let idx = paramString.integerValue;
        
        if let data = card.getBankData(idx) {
            return NSString(format: "%@|%@|%@|%@", data.country, data.bankCode, data.host, data.userId);
        }
        return nil;
    }
    
    open func readKeyData(_ paramString:NSString) ->NSString? {
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
    
    open func enterPin(_ paramString:NSString) ->Bool {
        //return card.verifyPin();
        // card should already been verified
        return true;
    }
    
    open func saveSigId(_ paramString:NSString) ->Bool {
        //let sigid = paramString.integerValue;
        /*
        if !card.writeSignatureId(sigid) {
            logError("Error while saving new signature id to chipcard");
            return false;
        }
        */
        return true;
    }
    
    open func sign(_ paramString:NSString) ->NSString? {
        //let hash = stringToBytes(paramString);
        /*
        if let sig = card.sign(hash) {
            return bytesToString(sig);
        }
        */
        return nil;
    }
    
    open func encrypt(_ paramString:NSString) ->NSString? {
        //let keyNum = paramString.integerValue;
        /*
        if let keys = card.getEncryptionKeys(UInt8(keyNum)) {
            return NSString(format: "%@|%@", bytesToString(keys.plain), bytesToString(keys.encrypted));
        }
        */
        return nil;
    }
    
    open func decrypt(_ paramString:NSString) ->NSString? {
        let params = paramString.components(separatedBy: "|");
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
    
    open func close() {
        if card != nil {
            card.disconnect();
            card = nil;
        }
    }
    
    open static var manager:ChipcardManager {
        get {
            if let manager = _manager {
                return manager;
            } else {
                _manager = ChipcardManager();
                return _manager;
            }
        }
    }
    
    
    
}
