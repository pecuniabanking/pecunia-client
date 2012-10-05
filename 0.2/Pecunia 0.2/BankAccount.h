//
//  BankAccount.h
//  MacBanking
//
//  Created by Frank Emminghaus on 01.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <aqbanking/banking.h>
#import "Category.h"
@class ABAccount;
@class BankQueryResult;

@interface BankAccount : Category {
	NSDate	*newLatestTransferDate;
	
	BOOL	collTransfer;
}

-(NSString*)bankCode;
-(NSDate*)latestTransferDate;
-(ABAccount*)abAccount;
-(void)updateChanges;

-(void)evaluateStatements: (NSArray*)stats onlyLatest:(BOOL)onlyLatest;
-(int)updateFromQueryResult: (BankQueryResult*)result;

@property (nonatomic, retain) NSDate * latestTransferDate;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * bankName;
@property (nonatomic, retain) NSString * bankCode;
@property (nonatomic, retain) NSString * accountNumber;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSDecimalNumber * balance;

+(BankAccount*)accountWithNumber:(NSString*)number bankCode:(NSString*)code;

@end

