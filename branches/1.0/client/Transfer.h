//
//  Transfer.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;
@class TransferTemplate;
@class TransactionLimits;

typedef enum {
	TransferTypeLocal=0,
	TransferTypeEU,
	TransferTypeDated,
	TransferTypeInternal
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
