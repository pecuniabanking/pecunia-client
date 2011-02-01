//
//  ABAccount.h
//  Pecunia
//
//  Created by Frank Emminghaus on 06.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Transfer.h"

typedef enum {
	AccountType_Unknown=0,
	AccountType_Bank,
	AccountType_CreditCard,
	AccountType_Checking,
	AccountType_Savings,
	AccountType_Investment,
	AccountType_Cash,
	AccountType_MoneyMarket
} AccountType;


@class BankAccount;
@class TransactionLimits;
@class ABUser;

@interface ABAccount : NSObject {
	unsigned int	uid;
	AccountType		type;
	NSString*		name;
	NSString*		bankName;
	NSString*		bankCode;
	NSString*		accountNumber;
	NSString*		ownerName;
	NSString*		currency;
	NSString*		country;
	NSString*		iban;
	NSString*		bic;
	NSString*		userId;
	NSString*		customerId;
	NSString*		accountSuffix;
	BOOL			collTransfer;
	
	NSArray			*allowedCountries;
	BOOL			substInternalTransfers;
}

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *customerId;
@property (nonatomic, assign) BOOL substInternalTransfers;
@property (nonatomic, assign) unsigned int uid;
@property (nonatomic, assign) AccountType type;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *accountNumber;
@property (nonatomic, copy) NSString *ownerName;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *iban;
@property (nonatomic, copy) NSString *bic;
@property (nonatomic, copy) NSString *accountSuffix;
@property (nonatomic, assign) BOOL collTransfer;

-(BOOL)isEqual: (id)obj;

// Others

-(void) dealloc;

@end



