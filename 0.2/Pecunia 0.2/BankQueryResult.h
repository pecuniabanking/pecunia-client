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
	NSString		*currency;
	NSDecimalNumber	*balance;
	NSMutableArray	*statements;
	BOOL			isImport;
	BankAccount		*account;
}

@property (copy) NSString *accountNumber;
@property (copy) NSString *bankCode;
@property (copy) NSString *currency;
@property (copy) NSDecimalNumber *balance;
@property (retain) NSMutableArray *statements;
@property (assign) BankAccount *account;
@property (assign) BOOL isImport;




@end
