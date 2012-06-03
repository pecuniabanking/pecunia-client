/**
 * Copyright (c) 2007, 2012, Pecunia Project. All rights reserved.
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
    // TODO: missing business transactions: SEPA company transfer/debit.
	TransferTypeStandard,
	TransferTypeEU,
	TransferTypeDated,
	TransferTypeInternal,
    TransferTypeDebit,
    TransferTypeSEPA
} TransferType;

@interface Transfer : NSManagedObject {
	unsigned int jobId;
}

-(NSString*)purpose;
-(void) copyFromTemplate:(TransferTemplate*)t withLimits:(TransactionLimits*)limits;
-(void)setJobId: (unsigned int)jid;
-(unsigned int)jobId;


@property (nonatomic, retain) NSNumber * chargedBy;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * isSent;
@property (nonatomic, retain) NSNumber * isTemplate;
@property (nonatomic, retain) NSString * purpose1;
@property (nonatomic, retain) NSString * purpose2;
@property (nonatomic, retain) NSString * purpose3;
@property (nonatomic, retain) NSString * purpose4;
@property (nonatomic, retain) NSString * remoteAccount;
@property (nonatomic, retain) NSString * remoteAddrCity;
@property (nonatomic, retain) NSString * remoteAddrPhone;
@property (nonatomic, retain) NSString * remoteAddrStreet;
@property (nonatomic, retain) NSString * remoteAddrZip;
@property (nonatomic, retain) NSString * remoteBankCode;
@property (nonatomic, retain) NSString * remoteBankName;
@property (nonatomic, retain) NSString * remoteBIC;
@property (nonatomic, retain) NSString * remoteCountry;
@property (nonatomic, retain) NSString * remoteIBAN;
@property (nonatomic, retain) NSString * remoteName;
@property (nonatomic, retain) NSString * remoteSuffix;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * subType;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * usedTAN;
@property (nonatomic, retain) NSDecimalNumber * value;
@property (nonatomic, retain) NSDate * valutaDate;
@property (nonatomic, retain) BankAccount * account;

@end
