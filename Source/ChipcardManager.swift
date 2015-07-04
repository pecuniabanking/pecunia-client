//
//  ChipcardManager.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 24.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation

var _manager:ChipcardManager!

@objc public class ChipcardManager {
    var card:HBCISmartcardDDV!
    
    public init() {
    }
    
    func stringToBytes(s:NSString) ->NSData {
        var buffer = UnsafeMutablePointer<UInt8>.alloc(s.length/2);
        
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
        var ret = NSMutableString();
        var p = UnsafeMutablePointer<UInt8>(data.bytes);
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
    
    public func initializeChipcard(paramString:NSString) ->NSString? {
        let params = paramString.componentsSeparatedByString("|");
        
        if params.count != 2 {
            logError("wrong parameters for chipcard initialization");
            return nil;
        }
        
        let readerNum = params[1].integerValue;
        
        if let readers = HBCISmartcard.readers() {
            if readers.count == 0 {
                logError("No reader found");
                return nil;
            }
            
            if readerNum > readers.count-1 {
                logError("Reader %d is not available", arguments:readerNum);
                return nil;
            }
            
            let name = readers[readerNum];
            
            card = HBCISmartcardDDV(readerName: name);
            if !card.connect(120) {
                logError("Card could not be connected");
                return nil;
            }
            
            if !card.getCardID() {
                logError("Card ID could not be read");
                return nil;
            }
            
            if let cid = card.cardID, cnumber = card.cardNumber {
                return NSString(format: "%@|%@", bytesToString(cid), cnumber);
            }
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
    }
    
    public func enterPin(paramString:NSString) ->Bool {
        return card.verifyPin();
    }
    
    public func saveSigId(paramString:NSString) ->Bool {
        let sigid = paramString.integerValue;
        
        if !card.writeSignatureId(sigid) {
            logError("Error while saving new signature id to chipcard");
            return false;
        }
        return true;
    }
    
    public func sign(paramString:NSString) ->NSString? {
        let hash = stringToBytes(paramString);
        
        if let sig = card.sign(hash) {
            return bytesToString(sig);
        }
        return nil;
    }
    
    public func encrypt(paramString:NSString) ->NSString? {
        let keyNum = paramString.integerValue;
        
        if let keys = card.getEncryptionKeys(UInt8(keyNum)) {
            return NSString(format: "%@|%@", bytesToString(keys.plain), bytesToString(keys.encrypted));
        }
        return nil;
    }
    
    public func decrypt(paramString:NSString) ->NSString? {
        let params = paramString.componentsSeparatedByString("|");
        if params.count != 2 {
            logError("missing parameters for decrypt");
            return nil;
        }
        
        let keyNum = params[0].integerValue;
        let encKey = params[1] as! NSString;
        
        if let plain = card.decryptKey(UInt8(keyNum), encrypted: stringToBytes(encKey)) {
            return bytesToString(plain);
        }
        return nil;
    }
    
    public func close() {
        card.disconnect();
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
