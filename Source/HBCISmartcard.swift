//
//  HBCISmartcard.swift
//  HBCISmartCard
//
//  Created by Frank Emminghaus on 15.06.15.
//  Copyright (c) 2015 Frank Emminghaus. All rights reserved.
//

import Foundation
//import PCSC

class HBCISmartcard {
    let readerName:String;
    var version:UInt8 = 0;
    var _hCard:SCARDHANDLE?
    var _ioctl_verify:DWORD?
    var _ioctl_pinprops:DWORD?
    var _ioctl_readerdirect:DWORD?
    var connected:Bool;
    
    static var _hContext:SCARDCONTEXT?
    
    // constants
    let CM_IOCTL_GET_FEATURE_REQUEST:DWORD = 0x42000D48;
    
    let APDU_CLA_STD:UInt8 = 0x00
    let APDU_CLA_SM_PROPR:UInt8 = 0x04;
    let APDU_CLA_SM1:UInt8 = 0x08;
    
    let APDU_INS_SELECT_FILE:UInt8 = 0xA4;
    let APDU_INS_READ_RECORD:UInt8 = 0xB2;
    let APDU_INS_GET_CHALLENGE:UInt8 = 0x84;
    let APDU_INS_VERIFY:UInt8 = 0x20;
    let APDU_INS_WRITE_RECORD:UInt8 = 0xDC;
    let APDU_INS_PUT_DATA:UInt8 = 0xDA;
    let APDU_INS_AUTH_INT:UInt8 = 0x88;
    let APDU_SEL_RET_NOTHING:UInt8 = 0x0C;
    
    enum ConnectResult {
        case connected, reconnected, no_card, no_context, not_supported, error
    }


    class func establishReaderContext() ->Bool {
        if _hContext == nil {
            var context:SCARDCONTEXT = 0;
            let rv = SCardEstablishContext(UInt32(SCARD_SCOPE_SYSTEM), nil, nil, &context);
            if rv != SCARD_S_SUCCESS {
                logError("HBCIChipcard: could not establish connection to chipcard driver");
                return false;
            } else {
                _hContext = context;
            }
        }
        return true;
    }
    
    class func readers() ->Array<String>? {
        var numReaders:DWORD = 0;
        var result = Array<String>();
        
        if _hContext == nil && !establishReaderContext() {
            return nil;
        }
        
        if let context = _hContext {
            var rv = SCardListReaders(context, nil, nil, &numReaders);
            if rv != SCARD_S_SUCCESS {
                logError("HBCIChipcard: could not list available readers");
                return nil;
            }
            
            let pReaders = UnsafeMutablePointer<Int8>.alloc(Int(numReaders));
            rv = SCardListReaders(context, nil, pReaders, &numReaders);
            
            var p = pReaders;
            while p.memory != 0 {
                if let s = NSString(CString: p, encoding: NSISOLatin1StringEncoding) {
                    result.append(s as String);
                }
                p = p.advancedBy(Int(strlen(p))+1);
            }
            pReaders.destroy();
        }
        return result;
    }
    
    class func releaseReaderContext() ->Bool {
        if let context = _hContext {
            if SCardReleaseContext(context) != SCARD_S_SUCCESS {
                return false;
            }
            _hContext = 0;
        }
        return true;
    }
    
    init(readerName:String) {
        self.readerName = readerName;
        connected = false;
    }
    
    func convertToUInt32(x:Int32) ->UInt32 {
        if x >= 0 {
            return UInt32(x);
        } else {
            let i = 0x100000000+Int(x);
            return UInt32(i);
        }
    }
    
    func checkResult(result:NSData?) ->Bool {
        if let data = result {
            var p = UnsafePointer<UInt8>(data.bytes).advancedBy(data.length-2);
            var status = UInt16(p.memory) << 8;
            p = p.advancedBy(1);
            status = status + (UInt16(p.memory) & 0xff);
            
            if status & 0xFFFF == 0x9000 {
                return true;
            } else {
                logError("Smartcard command failed with result %d", arguments: status);
            }
        }
        return false;
    }
    
    func extractDataFromResult(result:NSData) ->NSData {
        return NSData(bytes: result.bytes, length: result.length-2);
    }
    
    func verifyPin() ->Bool {
        var offset = 0;
        let pSendBuffer = UnsafeMutablePointer<UInt8>.alloc(Int(MAX_BUFFER_SIZE));
        let pRecBuffer = UnsafeMutablePointer<UInt8>.alloc(Int(MAX_BUFFER_SIZE));
        let pin_verify = UnsafeMutablePointer<PIN_VERIFY_STRUCTURE>(pSendBuffer);

        //_:[UInt8] = [ 0x00, 0x20, 0x00, 0x81, 0x08, 0x25, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff ];
        
        pin_verify.memory.bTimerOut = 15;
        pin_verify.memory.bTimerOut2 = 5;
        pin_verify.memory.bmFormatString = 0x89;
        pin_verify.memory.bmPINBlockString = 0x07;
        pin_verify.memory.bmPINLengthFormat = 0x10;
        pin_verify.memory.wPINMaxExtraDigit = 0x0408;
        pin_verify.memory.bEntryValidationCondition = 0x02;
        pin_verify.memory.bNumberMessage = 0x01;
        pin_verify.memory.wLangId = 0x0904;
        pin_verify.memory.bMsgIndex = 0x00;
        pin_verify.memory.bTeoPrologue.0 = 0x00;
        pin_verify.memory.bTeoPrologue.1 = 0x00;
        pin_verify.memory.bTeoPrologue.2 = 0x00;
        pin_verify.memory.ulDataLength = 13;
        
        // copy command
        let p = withUnsafePointer(&pin_verify.memory.abData, { (ptr) -> UnsafeMutablePointer<UInt8> in return unsafeBitCast(ptr, UnsafeMutablePointer<UInt8>.self)});
        
        p[offset++] = APDU_CLA_STD;
        p[offset++] = APDU_INS_VERIFY;
        p[offset++] = 0x00;
        p[offset++] = 0x81;
        p[offset++] = 0x08;
        p[offset++] = 0x25;
        p[offset++] = 0xff;
        p[offset++] = 0xff;
        p[offset++] = 0xff;
        p[offset++] = 0xff;
        p[offset++] = 0xff;
        p[offset++] = 0xff;
        p[offset++] = 0xff;

        var length = DWORD(sizeof(PIN_VERIFY_STRUCTURE) + offset - 1);
        
        if let hCard = _hCard, ioctl_verify = _ioctl_verify {
            let rv = SCardControl132(hCard, ioctl_verify, pSendBuffer, length, pRecBuffer, DWORD(MAX_BUFFER_SIZE), &length);
            if rv == SCARD_S_SUCCESS {
                if pRecBuffer[0] == 0x90 && pRecBuffer[1] == 0x00 {
                    pRecBuffer.destroy();
                    pSendBuffer.destroy();
                    return true;
                }
            }
        }
        pRecBuffer.destroy();
        pSendBuffer.destroy();
        return false;
    }
    
    func retrieveCapabilities() ->Bool {
        var length:DWORD = 0;
        
        if let hCard = _hCard {
            let pRecBuffer = UnsafeMutablePointer<UInt8>.alloc(Int(MAX_BUFFER_SIZE));
            let rv = SCardControl132(hCard, CM_IOCTL_GET_FEATURE_REQUEST, nil, 0, pRecBuffer, DWORD(MAX_BUFFER_SIZE), &length);
            if rv != SCARD_S_SUCCESS {
                // log
                pRecBuffer.destroy();
                return false;
            }
            
            if (Int(length) % sizeof(PCSC_TLV_STRUCTURE)) != 0 {
                // log
                pRecBuffer.destroy();
                return false;
            }
            
            let count = Int(length) / sizeof(PCSC_TLV_STRUCTURE);
            
            var p = UnsafeMutablePointer<PCSC_TLV_STRUCTURE>(pRecBuffer);
            for var i = 0; i<count; i++ {
                switch(p.memory.tag) {
                case UInt8(FEATURE_VERIFY_PIN_DIRECT): _ioctl_verify = p.memory.value.bigEndian;
                //case UInt8(FEATURE_IFD_PIN_PROPERTIES): _ioctl_pinprops = p.memory.value.bigEndian;
                //case UInt8(FEATURE_MCT_READER_DIRECT): _ioctl_readerdirect = p.memory.value.bigEndian;
                default: break;
                }
                p = p.advancedBy(1);
            }
            pRecBuffer.destroy();

            if _ioctl_verify == nil {
                // log
                logError("HBCIChipcard: IOCTL for verify could not be retrieved");
                return false;
            }
        }
        return true;
    }
    
    func isConnected() ->Bool {
        var state:DWORD = 0;
        var prot:DWORD = 0;
        var length:DWORD = 0;
        var attrLen = DWORD(MAX_ATR_SIZE);
        
        
        // get card status
        if let hCard = _hCard {
            let pAttr = UnsafeMutablePointer<UInt8>.alloc(Int(attrLen));
            
            let rv = SCardStatus(hCard, nil, &length, &state, &prot, pAttr, &attrLen);
            
            // pAttr not needed (yet)
            pAttr.destroy();
            
            if rv != SCARD_S_SUCCESS {
                return false;
            }
            if (state & DWORD(SCARD_ABSENT)) != 0 {
                return false;
            }
            return true;
        }
        return false;
    }
    
    // check if reader ist still connected
    func isReaderConnected() ->Bool {
        if let readers = HBCISmartcard.readers() {
            return readers.contains(readerName);
        }
        return false;
    }
    
    func connect(tries:Int) ->ConnectResult {
        var prot:DWORD = 0;
        var n = 0;
        var reconnected = false;
        var rv:Int32 = 0;
        
        if !HBCISmartcard.establishReaderContext() {
            return ConnectResult.no_context;
        }
        
        if let context = HBCISmartcard._hContext {
            while n < tries {
                // once connection was successful, following accesses have to be done with
                // a reconnect
                if let hCard = _hCard {
                    rv = SCardReconnect(hCard, DWORD(SCARD_SHARE_EXCLUSIVE), DWORD(SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1), DWORD(SCARD_RESET_CARD), &prot);
                    if rv == SCARD_S_SUCCESS {
                        reconnected = true;
                    }
                } else {
                    var hCard:SCARDHANDLE = 0;
                    rv = SCardConnect(context, readerName.cStringUsingEncoding(NSISOLatin1StringEncoding)!, DWORD(SCARD_SHARE_EXCLUSIVE), DWORD(SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1), &hCard, &prot);
                    if rv == SCARD_S_SUCCESS {
                        _hCard = hCard;
                    }
                }
                if convertToUInt32(rv) == SCARD_E_NO_SMARTCARD {
                    if n < tries-1 {
                        // wait 500ms
                        let a = UnsafeMutablePointer<timespec>.alloc(1);
                        let b = UnsafeMutablePointer<timespec>.alloc(1);
                        a.memory.tv_sec = 0;
                        a.memory.tv_nsec = 500000000;
                        nanosleep(a, b);
                        a.destroy();
                        b.destroy();
                    }
                    n++;
                } else {
                    break;
                }
            }
            
            if n < tries && rv == SCARD_S_SUCCESS {
                if isConnected() && retrieveCapabilities() {
                    if reconnected {
                        return ConnectResult.reconnected;
                    } else {
                        return ConnectResult.connected;
                    }
                }
            } else {
                if convertToUInt32(rv) == SCARD_E_NO_SMARTCARD {
                    return ConnectResult.no_card;
                }
            }
            //logError("HBCISmartcard: connection error: %x", rv);
            NSLog("HBCISmartcard: connection error: 0x%X", rv);
            return ConnectResult.error;
        } else {
            return ConnectResult.no_context;
        }
    }
    
    func disconnect() {
        if let hCard = _hCard {
            SCardDisconnect(hCard, DWORD(SCARD_UNPOWER_CARD));
        }
    }
    
    func sendAPDU(command:NSData) ->NSData? {
        var length = DWORD(MAX_BUFFER_SIZE);
        var result:NSData?
        
        if let hCard = _hCard {
            let pioRecvPci = UnsafeMutablePointer<SCARD_IO_REQUEST>.alloc(1);
            let pRecBuffer = UnsafeMutablePointer<UInt8>.alloc(Int(MAX_BUFFER_SIZE));
            
            let rv = SCardTransmit(hCard, &g_rgSCardT1Pci, UnsafePointer<UInt8>(command.bytes), DWORD(command.length), pioRecvPci, pRecBuffer, &length);
            if rv == SCARD_S_SUCCESS {
                result = NSData(bytes: pRecBuffer, length: Int(length));
            }
            pioRecvPci.destroy();
            pRecBuffer.destroy();
        }
        return result;
    }
    
    func selectRoot() ->Bool {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_SELECT_FILE, 0x00, APDU_SEL_RET_NOTHING, 0x02, 0x3F, 0x00 ];
        let apdu = NSData(bytes: command, length: 7);
        let result = sendAPDU(apdu);
        return checkResult(result);
    }
    
    func selectFileByName(fileName:NSData) ->Bool {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_SELECT_FILE, 0x04, APDU_SEL_RET_NOTHING, UInt8(fileName.length) ];
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.appendData(fileName);
        let result = sendAPDU(apdu);
        return checkResult(result);
    }
    
    func readRecordWithSFI(recordNumber:Int, sfi:Int) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_READ_RECORD, UInt8(recordNumber), UInt8((sfi<<3) | 0x04), 0x00];
        let apdu = NSData(bytes: command, length: 5);
        let result = sendAPDU(apdu);
        if checkResult(result) {
            return extractDataFromResult(result!);
        }
        return nil;
    }
    
    func writeRecordWithSFI(recordNumber:Int, sfi:Int, data:NSData) ->Bool {
        let command:[UInt8] = [APDU_CLA_STD, APDU_INS_WRITE_RECORD, UInt8(recordNumber), UInt8((sfi<<3) | 0x04), UInt8(data.length) ];
        
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.appendData(data);
        if let result = sendAPDU(apdu) {
            return checkResult(result);
        }
        return false;
     }
    
    func putData(tag:Int, data:NSData) ->Bool {
        let command:[UInt8] = [APDU_CLA_STD, APDU_INS_WRITE_RECORD, UInt8((tag>>8) & 0xff), UInt8(tag & 0xff), UInt8(data.length) ];
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.appendData(data);
        if let result = sendAPDU(apdu) {
            return checkResult(result);
        }
        return false;
    }

    func readRecord(recordNumber:Int) ->NSData? {
        return readRecordWithSFI(recordNumber, sfi: 0);
    }
    
    func selectSubFileWithId(fileId:Int) ->Bool {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_SELECT_FILE, 0x02, APDU_SEL_RET_NOTHING, 0x02, UInt8((fileId>>8) & 0xFF), UInt8(fileId & 0xFF) ];
        let apdu = NSData(bytes: command, length: 7);
        let result = sendAPDU(apdu);
        return checkResult(result);
    }
    
    func getChallenge(size:UInt8) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_GET_CHALLENGE, 0x00, 0x00, size ];
        let apdu = NSData(bytes: command, length: 5);
        if let result = sendAPDU(apdu) {
            if checkResult(result) {
                return extractDataFromResult(result);
            }
        }
        return nil;
    }
    
    func internal_authenticate(keyNum:UInt8, keyType:UInt8, data:NSData) ->NSData? {
        let command:[UInt8] = [ APDU_CLA_STD, APDU_INS_AUTH_INT, 0x00, keyType | keyNum, UInt8(data.length) ];
        let apdu = NSMutableData(bytes: command, length: 5);
        apdu.appendData(data);
        // append zero at the end
        var x:UInt8 = 0;
        apdu.appendBytes(&x, length: 1);
        if let result = sendAPDU(apdu) {
            if checkResult(result) {
                return extractDataFromResult(result);
            }
        }
        return nil;
    }
    
}
