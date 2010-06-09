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

-(BOOL)isEqual: (id)obj;
-(id)initWithAB: (const AB_ACCOUNT*)acc;

// Accessors
- (AB_ACCOUNT_TYPE)type;
- (void)setType:(AB_ACCOUNT_TYPE)value;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)bankName;
- (void)setBankName:(NSString *)value;

- (NSString *)bankCode;
- (void)setBankCode:(NSString *)value;

- (NSString *)accountNumber;
- (void)setAccountNumber:(NSString *)value;

- (NSString *)ownerName;
- (void)setOwnerName:(NSString *)value;

- (NSString *)currency;
- (void)setCurrency:(NSString *)value;

- (NSString *)country;
- (void)setCountry:(NSString *)value;

- (NSString *)iban;
- (void)setIban:(NSString *)value;

- (NSString *)bic;
- (void)setBic:(NSString *)value;

- (BOOL)collTransfer;
- (void)setCollTransfer:(BOOL)value;

-(void)setFlags: (uint32_t)flags;
-(uint32_t)flags;


// Others
-(AB_ACCOUNT*)abRef;
-(void)setRef: (const AB_ACCOUNT*)ref;
-(void)initAB: (AB_ACCOUNT*)acc;
-(void)updateChanges;
-(TransactionLimits*)limitsForType: (TransferType)tt country: (NSString*)ctry;
-(BOOL)isTransferSupportedForType: (TransferType)tt;
-(NSArray*)allowedCountries;

-(BOOL)substInternalTransfers;
-(int)removeUser: (User*)user;

-(unsigned int)uid;
-(AB_ACCOUNT_TYPE)type;
-(BankAccount*)cdAccount;
-(void)setCDAccount: (BankAccount*)account;
-(void) dealloc;

-(NSComparisonResult)compareByBank: (ABAccount*)x;
+(SEL)getCBBSelector;
@end
