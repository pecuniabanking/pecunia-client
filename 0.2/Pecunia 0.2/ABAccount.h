//
//  ABAccount.h
//  MacBanking
//
//  Created by Frank Emminghaus on 06.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "User.h"
#import "Transfer.h"

/*
#define _uid		@"UID"
#define _type		@"Type"
#define _name		@"Name"
#define _bankName	@"BankName"
#define _bankCode	@"BankCode"
#define _accNumber	@"AccountNumber"
#define _owner		@"Owner"
#define _curr		@"Curr"
#define _country	@"Country"
#define _trans		@"Transactions"
#define _balance	@"Balance"
*/
@class BankAccount;
@class TransactionLimits;

@interface ABAccount : NSObject {
	unsigned int	uid;
	AB_ACCOUNT_TYPE	type;
	NSString*		name;
	NSString*		bankName;
	NSString*		bankCode;
	NSString*		accountNumber;
	NSString*		ownerName;
	NSString*		currency;
	NSString*		country;
	NSString*		iban;
	NSString*		bic;
	BOOL			collTransfer;
	
//	TransactionLimits	*limits;
	NSArray			*allowedCountries;
	BankAccount		*cdAccount;
	AB_ACCOUNT		*abAcc;
	BOOL			substInternalTransfers;
}

@property (nonatomic, assign) BOOL substInternalTransfers;
@property (nonatomic, assign) AB_ACCOUNT_TYPE type;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *accountNumber;
@property (nonatomic, copy) NSString *ownerName;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *iban;
@property (nonatomic, copy) NSString *bic;
@property (nonatomic, assign) BOOL collTransfer;

-(void)setFlags: (uint32_t)flags;
-(uint32_t)flags;
-(unsigned int)uid;

-(BOOL)isEqual: (id)obj;
-(id)initWithAB: (const AB_ACCOUNT*)acc;

// Others
-(AB_ACCOUNT*)abRef;
-(void)setRef: (const AB_ACCOUNT*)ref;
-(void)createAB: (AB_ACCOUNT*)acc;
-(void)updateChanges;
-(TransactionLimits*)limitsForType: (TransferType)tt country: (NSString*)ctry;
-(BOOL)isTransferSupportedForType: (TransferType)tt;
-(NSArray*)allowedCountries;

-(BOOL)substInternalTransfers;
-(int)removeUser: (User*)user;

-(BankAccount*)cdAccount;
-(void)setCDAccount: (BankAccount*)account;
-(void) dealloc;

-(NSComparisonResult)compareByBank: (ABAccount*)x;
+(SEL)getCBBSelector;
@end


