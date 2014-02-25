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

#import <Cocoa/Cocoa.h>

@class BankAccount;
@class TransferTemplate;
@class TransactionLimits;

typedef enum {
    TransferTypeOldStandard,
    TransferTypeEU,
    TransferTypeOldStandardScheduled,
    TransferTypeInternal,
    TransferTypeDebit,
    TransferTypeSEPA,
    TransferTypeSEPAScheduled,
    TransferTypeCollectiveCredit,
    TransferTypeCollectiveDebit,
    TransferTypeCollectiveCreditSEPA
} TransferType;

typedef enum {
    TransferChangeUnchanged,
    TransferChangeEditing,
    TransferChangeNew
} TransferChangeState;

@interface Transfer : NSManagedObject {
    unsigned int jobId;
}

- (NSString *)purpose;
- (void)copyFromTemplate: (TransferTemplate *)t withLimits: (TransactionLimits *)limits;
- (void)copyFromTransfer: (Transfer *)other withLimits: (TransactionLimits *)limits;
- (void)setJobId: (unsigned int)jid;
- (unsigned int)jobId;


@property (nonatomic, strong) NSNumber        *chargedBy;
@property (nonatomic, strong) NSString        *currency;
@property (nonatomic, strong) NSDate          *date;
@property (nonatomic, strong) NSNumber        *isSent;
@property (nonatomic, strong) NSNumber        *isTemplate;
@property (nonatomic, strong) NSString        *purpose1;
@property (nonatomic, strong) NSString        *purpose2;
@property (nonatomic, strong) NSString        *purpose3;
@property (nonatomic, strong) NSString        *purpose4;
@property (nonatomic, strong) NSString        *remoteAccount;
@property (nonatomic, strong) NSString        *remoteAddrCity;
@property (nonatomic, strong) NSString        *remoteAddrPhone;
@property (nonatomic, strong) NSString        *remoteAddrStreet;
@property (nonatomic, strong) NSString        *remoteAddrZip;
@property (nonatomic, strong) NSString        *remoteBankCode;
@property (nonatomic, strong) NSString        *remoteBankName;
@property (nonatomic, strong) NSString        *remoteBIC;
@property (nonatomic, strong) NSString        *remoteCountry;
@property (nonatomic, strong) NSString        *remoteIBAN;
@property (nonatomic, strong) NSString        *remoteName;
@property (nonatomic, strong) NSString        *remoteSuffix;
@property (nonatomic, strong) NSNumber        *status;
@property (nonatomic, strong) NSNumber        *subType;
@property (nonatomic, strong) NSNumber        *type;
@property (nonatomic, strong) NSString        *usedTAN;
@property (nonatomic, strong) NSDecimalNumber *value;
@property (nonatomic, strong) NSDate          *valutaDate;
@property (nonatomic, strong) BankAccount     *account;

@property (nonatomic, assign) TransferChangeState changeState; // Temporary flag used while editing transfers.

@end
