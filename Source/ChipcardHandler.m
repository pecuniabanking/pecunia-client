/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
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

#import "ChipcardHandler.h"
#include "ctapi-tools.h"
#include "bcs.h"
#include "hbci.h"
#include "seccos.h"
#include "ddvcard.h"
#include "MessageLog.h"

ChipcardHandler *_handler = nil;

@implementation ChipcardHandler

- (unsigned char *)stringToBytes: (NSString *)s {
    unsigned char *res = calloc(s.length/2, sizeof(unsigned char));
    
    for (NSUInteger i = 0; i < s.length/2; i++) {
        unsigned int value;
        NSScanner *scanner = [NSScanner scannerWithString: [s substringWithRange:NSMakeRange(2*i, 2)]];
        [scanner scanHexInt:&value];
        res[i] = (char)value;
    }
    return res;
}

- (NSString *)bytesToString: (NSData *)data {
    NSMutableString *ret = [NSMutableString string];
    unsigned char *bytes = (unsigned char *)data.bytes;
    for (NSUInteger i = 0; i<data.length; i++) {
        [ret appendFormat:@"%0.2X", bytes[i]];
    }
    return ret;
}


- (NSString *)initializeChipcard: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for chipcard initialization");
        return nil;
    }
    
    NSArray *params = [paramString componentsSeparatedByString:@"|"];
    
    if (params.count != 2) {
        LogError(@"wrong parameters for chipcard initialization");
        return nil;
    }
    
    IU16 port = [params[0] integerValue];
    IU16 ctNum = [params[1] integerValue];
    
    if(!CTAPI_initCTAPI(port, ctNum)) {
        LogError(@"Chipcard terminal not found or could not be initialized");
        return nil;
    }
    
    if (!BCS_resetCT()) {
        LogError(@"Error resetting chipcard terminal");
        return nil;
    }
    
    if (!BCS_requestCard(NULL, 60)) {
        LogError(@"Error while waiting for chipcard");
        return nil;
    }
    
    /* reset should not be done anymore 
    if(!BCS_resetCard()) {
        LogError(@"Chipcard could not be reset");
        return nil;
    }
    */
    
    HBCI_getCardType();
    
    if (HBCI_cardtype==HBCI_CARD_TYPE_UNKNOWN) {
        LogError(@"Unknown chipcard type");
        return nil;
    } else if (HBCI_cardtype==HBCI_CARD_TYPE_RSA) {
        LogError(@"this seems to be an RSA card, which is not supported yet");
        return nil;
    }

    unsigned char buffer[300];
    size_t        size;
    if (!SECCOS_readRecordBySFI(DDV_EF_ID,1,buffer,&size)) {
        LogError(@"error reading chipcard serial number (EF_ID)");
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:buffer length:size];
    NSString *cid = [self bytesToString:data];
    
    char cardid[16];
    for (int i=0;i<8;i++) {
        cardid[(i<<1)]  =((buffer[i+1]>>4)&0x0F) +0x30;
        cardid[(i<<1)+1]=((buffer[i+1])   &0x0F) +0x30;
    }
    
    NSString *cardId = [[NSString alloc] initWithBytes:cardid length:16 encoding:NSISOLatin1StringEncoding];
    
    return [NSString stringWithFormat:@"%@|%@", cid, cardId];
}

- (NSString *)readBankData: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for readBankData");
        return nil;
    }
    
    unsigned char idx = [paramString integerValue];
    
    HBCI_BankData *data = calloc(sizeof(HBCI_BankData), 1);;
    if (!DDV_readBankData(idx, data)) {
        LogError(@"unable to read institute data from chipcard");
        return nil;
    }
    
    NSString *country = [[NSString alloc] initWithCString:(char*)data->country encoding:NSISOLatin1StringEncoding];
    NSString *blz = [[NSString alloc] initWithCString:(char*)data->blz encoding:NSISOLatin1StringEncoding];
    NSString *host = [[NSString alloc] initWithCString:(char*)data->commaddr encoding:NSISOLatin1StringEncoding];
    NSString *userid = [[NSString alloc] initWithCString:(char*)data->userid encoding:NSISOLatin1StringEncoding];
    
    country = [country stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    blz = [blz stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    host = [host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    userid = [userid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return [NSString stringWithFormat:@"%@|%@|%@|%@", country, blz, host, userid];
}

- (NSString *)readKeyData: (NSString *)paramString {
    IU16 sigid = DDV_readSigId();
    
    if (sigid==(IU16)0xFFFF) {
        LogError(@"could not read signature id");
        return nil;
    }
    
    // reading key data from chipcard
    HBCI_KeyInfo **keydata=calloc(sizeof(HBCI_KeyInfo*),2);
    size_t       size;
    if (!DDV_readKeyData(keydata,&size) || size!=2) {
        LogError(@"error reading key information from chipcard");
        return nil;
    }

    return [NSString stringWithFormat:@"%d|%i|%i|%i|%i", sigid, keydata[0]->keynum, keydata[0]->keyversion, keydata[1]->keynum, keydata[1]->keyversion];
}

- (BOOL)enterPin: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for enterPin");
        return NO;
    }
 
    NSArray *params = [paramString componentsSeparatedByString:@"|"];
    if (params.count < 2) {
        LogError(@"missing parameters for enterPin");
        return NO;
    }
    
    int useSoftPin = [params[0] intValue];
    int useBio = [params[1] intValue];
    
    if (useSoftPin!=0 && useSoftPin!=1) {
        unsigned short int fus=BCS_requestFunctionalUnits();
        useSoftPin=(fus&BCS_HAS_FU_KEYBD)?0:1;
        
        LogInfo(@"using softpin: %s", (useSoftPin==0)?"no":"yes");
    }

    if (useBio!=0 && useBio!=1) {
        unsigned short int fus=BCS_requestFunctionalUnits();
        useBio=(fus&BCS_HAS_FU_BIO_FINGER)?1:0;
        
        LogInfo(@"using bio: %s", (useBio==0)?"no":"yes");
    }

    if (useSoftPin==0) {
        if (!DDV_verifyHBCIPin_1(useBio==1)) {
            LogError(@"error while entering PIN");
            return NO;
        }
    } else {
        const char *softpin = [params[2] UTF8String];
        if (!DDV_verifyHBCIPin_2((unsigned char*)softpin)) {
            LogError(@"error while verifying PIN");
            return NO;
        }
    }

    return YES;
}

- (BOOL)saveBankData: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for saveBankData");
        return NO;
    }
    
    NSArray *params = [paramString componentsSeparatedByString:@"|"];
    if (params.count != 5) {
        LogError(@"missing parameters for saveBankData");
        return NO;
    }
    
    int idx = [params[0] intValue];
    
    HBCI_BankData *entry=calloc(sizeof(HBCI_BankData), 1);
    if (!DDV_readBankData(idx,entry)) {
        LogError(@"error while reading bank data from chipcard");
        return NO;
    }

    strcpy((char*)entry->country, [params[1] UTF8String]);
    strcpy((char*)entry->blz, [params[2] UTF8String]);
    strcpy((char*)entry->commaddr, [params[3] UTF8String]);
    strcpy((char*)entry->userid, [params[4] UTF8String]);
    
    if (!DDV_writeBankData(idx,entry)) {
        LogError(@"error while saving bank data to chipcard");
    }
    
    free(entry);
    return YES;
}

- (BOOL)saveSigId: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for saveSigId");
        return NO;
    }
    
    int sigid = [paramString intValue];
    
    if (!DDV_writeSigId((unsigned short int)sigid)) {
        LogError(@"error while saving new signature id to chipcard");
        return NO;
    }

    return YES;
}

- (NSString *)sign: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for sign");
        return nil;
    }
    
    unsigned char *hash = [self stringToBytes:paramString];
    unsigned char signature[8];
    size_t        siglen;
    
    if (!DDV_signData(hash,&siglen,signature)) {
        LogError(@"error while signing data");
        free(hash);
        return nil;
    }
    free(hash);
    NSData *data = [NSData dataWithBytes:signature length:siglen];
    return [self bytesToString:data];
}

- (NSString *)encrypt: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for encrypt");
        return nil;
    }
    
    int keynum = [paramString intValue];
    
    unsigned char enckey[16];
    unsigned char plainkey[16];
    
    if (!DDV_getEncryptionKeys(keynum,plainkey,enckey)) {
        LogError(@"error while getting keys for encryption");
        return nil;
    }
    
    NSData *plainData = [NSData dataWithBytes:plainkey length:16];
    NSData *encData = [NSData dataWithBytes:enckey length:16];
    return [NSString stringWithFormat:@"%@|%@", [self bytesToString:plainData], [self bytesToString:encData]];
}

- (NSString *)decrypt: (NSString *)paramString {
    if (paramString == nil) {
        LogError(@"missing parameters for decrypt");
        return nil;
    }
    
    NSArray *params = [paramString componentsSeparatedByString:@"|"];
    if (params.count != 2) {
        LogError(@"missing parameters for decrypt");
        return nil;
    }

    int keynum = [params[0] intValue];
    
    unsigned char *enckey = [self stringToBytes:params[1]];
    unsigned char plainkey[16];
    
    if (!DDV_decryptKey(keynum,enckey,plainkey)) {
        LogError(@"error while decrypting key");
        free(enckey);
        return nil;
    }
    free(enckey);
    NSData *plainData = [NSData dataWithBytes:plainkey length:16];
    return [self bytesToString:plainData];
}

- (void)close {
    BCS_ejectCard(NULL,1,BCS_EJECT_KEEP,BCS_EJECT_DONT_BLINK,BCS_EJECT_DONT_BEEP);
    BCS_resetCT();
    CTAPI_closeCTAPI();
}

+ (ChipcardHandler *)handler {
    if (_handler == nil) {
        _handler = [[ChipcardHandler alloc] init];
    }
    return _handler;
}

@end
