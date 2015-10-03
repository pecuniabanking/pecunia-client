//
//  HBCISmartCardDDV.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 19.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation


class HBCISmartcardDDV : HBCISmartcard {
    var cardType:CardType;
    var cardID:NSData?
    var cardNumber:NSString?
    
    enum CardType {
        case CARDTYPE_UNKNOWN, CARDTYPE_DDV0, CARDTYPE_DDV1, CARDTYPE_RSA
    }

    // constants
    let DDV_EF_ID  = 0x19
    let DDV_EF_BANK = 0x1A
    let DDV_EF_MAC = 0x1B
    let DDV_EF_SEQ = 0x1C
    
    let APDU_CLA_EXT:UInt8 = 0xB0
    let APDU_INS_GET_KEYINFO:UInt8 = 0xEE;
    
    let APDU_SM_RESP_DESCR:UInt8 = 0xBA;
    let APDU_SM_CRT_CC:UInt8 = 0xB4;
    let APDU_SM_REF_INIT_DATA:UInt8 = 0x87;
    let APDU_SM_VALUE_LE:UInt8 = 0x96;
    
    let KEY_TYPE_DF:UInt8 = 0x80;

    override init(readerName:String) {
        cardType = CardType.CARDTYPE_UNKNOWN;
        super.init(readerName: readerName);
    }
    
    override func connect(tries:Int) -> ConnectResult {
        let result = super.connect(tries);
        if result == ConnectResult.connected || result == ConnectResult.reconnected {
            // get card type
            cardType = getCardType();
            if cardType != CardType.CARDTYPE_DDV0 && cardType != CardType.CARDTYPE_DDV1 {
                // Card is not supported
                disconnect();
                return ConnectResult.not_supported;
            }
            return result;
        }
        return result;
    }
    
    func trim(s:NSString) ->String {
        return s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
    }

    func getInfoForKey(keyNum:UInt8, keyType:UInt8) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_EXT, APDU_INS_GET_KEYINFO, keyType, keyNum, 0x00 ];
        let apdu = NSData(bytes: command, length: 5);
        let result = sendAPDU(apdu);
        if checkResult(result) {
            return extractDataFromResult(result!);
        }
        return nil;
    }
    
    func getCardType() ->CardType {
        let files:[[UInt8]] = [
            [ 0xd2,0x76,0x00,0x00,0x25,0x48,0x42,0x01,0x00 ],
            [ 0xd2,0x76,0x00,0x00,0x25,0x48,0x42,0x02,0x00 ],
            [ 0xd2,0x76,0x00,0x00,0x74,0x48,0x42,0x01,0x10 ]
        ];
        
        var i = 0;
        for i = 0; i<3; i++ {
            if !selectRoot() {
                continue;
            }
            let fileName = NSData(bytes: files[i], length: 9);
            if selectFileByName(fileName) {
                break;
            }
        }
        
        switch(i) {
        case 0: return CardType.CARDTYPE_DDV0;
        case 1: return CardType.CARDTYPE_DDV1;
        case 2: return CardType.CARDTYPE_RSA;
        default: return CardType.CARDTYPE_UNKNOWN;
        }
    }
    
    func getCardID() ->Bool {
        let result = readRecordWithSFI(1, sfi: DDV_EF_ID);
        if let res = result {
            cardID = res;
            
            let cardid = UnsafeMutablePointer<UInt8>.alloc(16);
            let p = UnsafePointer<UInt8>(res.bytes);
            for var i = 0; i<8; i++ {
                _ = p[i+1] >> 4;
                cardid[i<<1] = ((p[i+1] >> 4) & 0x0F) + 0x30;
                cardid[(i<<1)+1] = ((p[i+1]) & 0x0F) + 0x30;
            }
            cardNumber = NSString(bytes: cardid, length: 16, encoding: NSISOLatin1StringEncoding);
            cardid.destroy();
            return true;
        }
        return false;
    }
    
    func getBankData(idx:Int) ->HBCICardBankData? {
        if let result = readRecordWithSFI(idx, sfi: DDV_EF_BANK) {
            var p = UnsafeMutablePointer<UInt8>(result.bytes);
            var name, host, hostAdd, country, userId, bankCode:NSString!

            name = NSString(bytes: p, length: 20, encoding: NSISOLatin1StringEncoding);
            if name == nil {
                return nil;
            }
            p = p.advancedBy(25);
            host = NSString(bytes: p, length: 28, encoding: NSISOLatin1StringEncoding);
            if host == nil {
                return nil;
            }
            p = p.advancedBy(28);
            hostAdd = NSString(bytes: p, length: 2, encoding: NSISOLatin1StringEncoding);
            if hostAdd == nil {
                return nil;
            }
            p = p.advancedBy(2);
            country = NSString(bytes: p, length: 3, encoding: NSISOLatin1StringEncoding);
            if country == nil {
                return nil;
            }
            p = p.advancedBy(3);
            userId = NSString(bytes: p, length: 30, encoding: NSISOLatin1StringEncoding);
            if userId == nil {
                return nil;
            }
            
            p = UnsafeMutablePointer<UInt8>(result.bytes).advancedBy(20);
            let blz = UnsafeMutablePointer<UInt8>.alloc(8);
            for var i = 0; i < 4; i++ {
                var nibble:UInt8 = 0;
                nibble=(p[i]>>4)&0x0F;
                if (nibble>0x09) {
                    nibble^=0x0F;
                }
                blz[i<<1]=nibble+0x30;
                
                nibble=p[i]&0x0F;
                if (nibble>0x09) {
                    nibble^=0x0F;
                }
                blz[(i<<1)+1]=nibble+0x30;
            }
            blz.destroy();
            bankCode = NSString(bytes: blz, length: 8, encoding: NSISOLatin1StringEncoding);
            if bankCode == nil {
                return nil;
            }
            
            return HBCICardBankData(name: trim(name), bankCode: trim(bankCode), country: trim(country), host: trim(host), hostAdd: trim(hostAdd), userId: trim(userId));
        }
        return nil;
    }
    
    func getKeyData() ->Array<HBCICardKeyData> {
        var keys = Array<HBCICardKeyData>();
        
        if cardType == CardType.CARDTYPE_DDV0 {
            if selectSubFileWithId(0x13) {
                if let record = readRecord(1) {
                    let p = UnsafeMutablePointer<UInt8>(record.bytes);
                    let key = HBCICardKeyData(keyNumber: p[0], keyVersion: p[4], keyLength: p[1], algorithm: p[2]);
                    keys.append(key);
                }
            }
            if selectSubFileWithId(0x14) {
                if let record = readRecord(1) {
                    let p = UnsafeMutablePointer<UInt8>(record.bytes);
                    let key = HBCICardKeyData(keyNumber: p[0], keyVersion: p[3], keyLength: p[1], algorithm: p[2]);
                    keys.append(key);
                }
            }
        } else if cardType == CardType.CARDTYPE_DDV1 {
            if let info = getInfoForKey(2, keyType: KEY_TYPE_DF) {
                let p = UnsafeMutablePointer<UInt8>(info.bytes);
                let key = HBCICardKeyData(keyNumber: 2, keyVersion: p[info.length - 1], keyLength: 0, algorithm: 0);
                keys.append(key);
            }
            if let info = getInfoForKey(3, keyType: KEY_TYPE_DF) {
                let p = UnsafeMutablePointer<UInt8>(info.bytes);
                let key = HBCICardKeyData(keyNumber: 3, keyVersion: p[info.length - 1], keyLength: 0, algorithm: 0);
                keys.append(key);
            }
        } else {
            // not supported
        }
        
        return keys;
    }
    
    func getSignatureId() ->UInt16 {
        if let result = readRecordWithSFI(1, sfi: DDV_EF_SEQ) {
            let p = UnsafeMutablePointer<UInt8>(result.bytes);
            return (UInt16(p[0])<<8) | (UInt16(p[1]) & 0xff);
        }
        return 0;
    }
    
    func writeSignatureId(sigid:Int) ->Bool {
        let buffer:[UInt8] = [ UInt8(sigid >> 8), UInt8(sigid & 0xff) ];
        let data = NSData(bytes: buffer, length: 2);
        return writeRecordWithSFI(1, sfi: DDV_EF_SEQ, data: data);
    }
    
    func sign(hash:NSData) ->NSData? {
        let pHash = UnsafeMutablePointer<UInt8>(hash.bytes);
        
        // write right key part
        let rKey = NSData(bytes: pHash.advancedBy(8), length: 12);
        if !writeRecordWithSFI(1, sfi: DDV_EF_MAC, data: rKey) {
            return nil;
        }
        
        if cardType == CardType.CARDTYPE_DDV0 {
            let lKey = NSData(bytes: pHash, length: 8);
            
            // store left part
            if !putData(0x0100, data: lKey) {
                return nil;
            }
            
            // re-read right part and signature
            let command:[UInt8] = [ APDU_CLA_SM_PROPR, APDU_INS_READ_RECORD, 1, UInt8(Int(DDV_EF_MAC<<3) | 0x04), 0x00 ];
            let apdu = NSData(bytes: command, length: 5);
            if let result = sendAPDU(apdu) {
                let p = UnsafeMutablePointer<UInt8>(result.bytes).advancedBy(12);
                return NSData(bytes: p, length: 8);
            }
            return nil;
        } else {
            // DDV-1
            let command1:[UInt8] = [
                APDU_CLA_SM1, APDU_INS_READ_RECORD, 1, UInt8(Int(DDV_EF_MAC<<3) | 0x04), 0x11, APDU_SM_RESP_DESCR, 0x0C, APDU_SM_CRT_CC,
                0x0A, APDU_SM_REF_INIT_DATA, 0x08
            ];
            let command2:[UInt8] = [ APDU_SM_VALUE_LE, 0x01, 0x00, 0x00 ];
            
            let apdu = NSMutableData(bytes: command1, length: 11);
            apdu.appendBytes(pHash, length: 8);
            apdu.appendBytes(command2, length: 4);
            
            if let result = sendAPDU(apdu) {
                let p = UnsafeMutablePointer<UInt8>(result.bytes).advancedBy(16);
                return NSData(bytes: p, length: 8);
            }
        }
        return nil;
    }
    
    func getEncryptionKeys(keyNum:UInt8) ->(plain:NSData, encrypted:NSData)? {
        // get 16 byte key from 8 byte keys
        if let plain1 = getChallenge(8) {
            if let encr1 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: plain1) {
                if let plain2 = getChallenge(8) {
                    if let encr2 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: plain2) {
                        // now build keys and return
                        let plain = NSMutableData();
                        plain.appendData(plain1);
                        plain.appendData(plain2);
                        
                        let encrypted = NSMutableData();
                        encrypted.appendData(encr1);
                        encrypted.appendData(encr2);
                        return (plain, encrypted);
                    }
                }
            }
        }
        return nil;
    }
    
    func decryptKey(keyNum:UInt8, encrypted:NSData) ->NSData? {
        // decrypt 2 8-byte parts
        let encr1 = NSData(bytes: encrypted.bytes, length: 8);
        let p = UnsafePointer<UInt8>(encrypted.bytes).advancedBy(8);
        let encr2 = NSData(bytes: p, length: 8);
        
        if let plain1 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: encr1) {
            if let plain2 = internal_authenticate(keyNum, keyType: KEY_TYPE_DF, data: encr2) {
                let result = NSMutableData();
                result.appendData(plain1);
                result.appendData(plain2);
                return result;
            }
        }
        return nil;
    }
}
