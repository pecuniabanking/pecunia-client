//
//  BankQueryResult.h
//  Pecunia
//
//  Created by Frank Emminghaus on 11.08.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface BankQueryResult : NSObject {
	NSString		*accountNumber;
	NSString		*bankCode;
	NSString		*userId;
	NSString		*currency;
	NSDecimalNumber	*balance;
	NSDecimalNumber	*oldBalance;
	NSMutableArray	*statements;
	NSMutableArray  *standingOrders;
	BOOL			isImport;
	BankAccount		*account;
}

@property (copy) NSString *accountNumber;
@property (copy) NSString *bankCode;
@property (copy) NSString *currency;
@property (copy) NSString *userId;
@property (copy) NSDecimalNumber *balance;
@property (copy) NSDecimalNumber *oldBalance;
@property (retain) NSMutableArray *statements;
@property (retain) NSMutableArray *standingOrders;
@property (assign) BankAccount *account;
@property (assign) BOOL isImport;



@end
