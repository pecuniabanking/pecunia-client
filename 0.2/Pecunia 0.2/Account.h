//
//  Account.h
//  MacBanking
//
//  Created by Frank Emminghaus on 06.09.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "User.h"

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

@interface Account : NSObject {
	unsigned int	uid;
	AB_ACCOUNT_TYPE	type;
	NSString*		name;
	NSString*		bankName;
	NSString*		bankCode;
	NSString*		accountNumber;
	NSString*		ownerName;
	NSString*		currency;
	NSString*		country;
	User*			user;

	double			balance;
	NSMutableArray	*transactions;
}

-(BOOL)isEqual: (id)obj;
-(void)updateTransactions: (NSArray*)transactions;
-(void)saveContent;

-(id)initWithAB: (const AB_ACCOUNT*)acc;
-(void)setBankName: (NSString*)x;
-(void)setBankCode: (NSString*)x;
-(void)setAccountNumber: (NSString*)x;
-(void)setBalance: (double)x withCurrency: curr;

-(NSString*)bankName;
-(NSString*)bankCode;
-(NSString*)accountNumber;
-(NSString*)name;
-(NSString*)ownerName;
-(NSString*)currency;
-(NSString*)country;
-(NSArray*)transactions;

-(double) balance;
-(void) dealloc;

-(NSComparisonResult)compareByBank: (Account*)x;
+(SEL)getCBBSelector;
@end
