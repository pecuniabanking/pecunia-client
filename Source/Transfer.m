/**
 * Copyright (c) 2007, 2014, Pecunia Project. All rights reserved.
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

#import "Transfer.h"
#import "TransferTemplate.h"
#import "TransactionLimits.h"

@implementation Transfer

@dynamic chargedBy;
@dynamic currency;
@dynamic date;
@dynamic isSent;
@dynamic isTemplate;
@dynamic purpose1;
@dynamic purpose2;
@dynamic purpose3;
@dynamic purpose4;
@dynamic remoteAccount;
@dynamic remoteAddrCity;
@dynamic remoteAddrPhone;
@dynamic remoteAddrStreet;
@dynamic remoteAddrZip;
@dynamic remoteBankCode;
@dynamic remoteBankName;
@dynamic remoteBIC;
@dynamic remoteCountry;
@dynamic remoteIBAN;
@dynamic remoteName;
@dynamic remoteSuffix;
@dynamic status;
@dynamic subType;
@dynamic type;
@dynamic usedTAN;
@dynamic value;
@dynamic valutaDate;
@dynamic account;

@synthesize changeState;

- (id)initWithEntity: (NSEntityDescription *)entity insertIntoManagedObjectContext: (NSManagedObjectContext *)context;
{
    self = [super initWithEntity: entity insertIntoManagedObjectContext: context];
    if (self != nil) {
        changeState = TransferChangeUnchanged;
    }
    return self;
}

- (NSString *)purpose
{
    NSMutableString *s = [NSMutableString stringWithCapacity: 100];
    if (self.purpose1) {
        [s appendString: self.purpose1];
    }
    if (self.purpose2) {
        [s appendString: @" "]; [s appendString: self.purpose2];
    }
    if (self.purpose3) {
        [s appendString: @" "]; [s appendString: self.purpose3];
    }
    if (self.purpose4) {
        [s appendString: @" "]; [s appendString: self.purpose4];
    }

    return s;
}

- (void)copyFromTemplate: (TransferTemplate *)t withLimits: (TransactionLimits *)limits
{
    NSString   *s;
    NSUInteger maxLen = [limits maxLenRemoteName] * [limits maxLinesRemoteName];
    s = t.remoteName;
    if (maxLen > 0 && [s length] > maxLen) {
        s = [s substringToIndex: maxLen];
    }
    self.remoteName = s;

    maxLen = [limits maxLenPurpose];
    int num = [limits maxLinesPurpose];

    s = t.purpose1;
    if (maxLen > 0 && [s length] > maxLen) {
        s = [s substringToIndex: maxLen];
    }
    self.purpose1 = s;

    if (num == 0 || num > 1) {
        s = t.purpose2;
        if (maxLen > 0 && [s length] > maxLen) {
            s = [s substringToIndex: maxLen];
        }
        self.purpose2 = s;
    }

    if (num == 0 || num > 2) {
        s = t.purpose3;
        if (maxLen > 0 && [s length] > maxLen) {
            s = [s substringToIndex: maxLen];
        }
        self.purpose3 = s;
    }

    if (num == 0 || num > 3) {
        s = t.purpose4;
        if (maxLen > 0 && [s length] > maxLen) {
            s = [s substringToIndex: maxLen];
        }
        self.purpose4 = s;
    }

    self.remoteAccount = t.remoteAccount;
    self.remoteBankCode = t.remoteBankCode;
    self.remoteIBAN = t.remoteIBAN;
    self.remoteBIC = t.remoteBIC;
    // No value by intention.
}

- (void)copyFromTransfer: (Transfer *)other withLimits: (TransactionLimits *)limits
{
    NSString   *s;
    NSUInteger maxLen = (limits != nil) ? limits.maxLenRemoteName * limits.maxLinesRemoteName : 65535;
    s = other.remoteName;
    if (maxLen > 0 && s.length > maxLen) {
        s = [s substringToIndex: maxLen];
    }
    self.remoteName = s;

    maxLen = (limits != nil) ? limits.maxLenPurpose : 65535;
    int num = (limits != nil) ? limits.maxLinesPurpose : 65535;

    s = other.purpose1;
    if (maxLen > 0 && s.length > maxLen) {
        s = [s substringToIndex: maxLen];
    }
    self.purpose1 = s;

    if (num == 0 || num > 1) {
        s = other.purpose2;
        if (s.length > maxLen) {
            s = [s substringToIndex: maxLen];
        }
        self.purpose2 = s;
    }

    if (num == 0 || num > 2) {
        s = other.purpose3;
        if (s.length > maxLen) {
            s = [s substringToIndex: maxLen];
        }
        self.purpose3 = s;
    }

    if (num == 0 || num > 3) {
        s = other.purpose4;
        if (s.length > maxLen) {
            s = [s substringToIndex: maxLen];
        }
        self.purpose4 = s;
    }

    //self.remoteAccount = other.remoteAccount;
    //self.remoteBankCode = other.remoteBankCode;
    if (other.remoteIBAN == nil) {
        // try to convert
        NSDictionary *ibanResult = [IBANtools convertToIBAN: other.remoteAccount
                                                   bankCode: other.remoteBankCode
                                                countryCode: @"de"
                                            validateAccount: YES];
        if ([ibanResult[@"result"] intValue] == IBANToolsResultDefaultIBAN ||
            [ibanResult[@"result"] intValue] == IBANToolsResultOk) {
            self.remoteIBAN = ibanResult[@"iban"];
            
            if (self.remoteIBAN != nil) {
                InstituteInfo *info = [HBCIBackend.backend infoForIBAN: self.remoteIBAN];
                if (info != nil) {
                    self.remoteBIC = info.bic;
                }
            }
        }
    } else {
        self.remoteIBAN = other.remoteIBAN;
        self.remoteBIC = other.remoteBIC;
    }
    self.value = other.value;
}

- (BOOL)isSEPA
{
    TransferType type = [self.type intValue];
    return type == TransferTypeSEPA || type == TransferTypeSEPAScheduled || type == TransferTypeCollectiveCreditSEPA;
}

- (BOOL)isSEPAorEU
{
    TransferType type = [self.type intValue];
    return self.isSEPA || type == TransferTypeEU || type == TransferTypeInternalSEPA;
}

- (void)setJobId: (unsigned int)jid
{
    jobId = jid;
}

- (unsigned int)jobId
{
    return jobId;
}

@end
