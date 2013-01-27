/**
 * Copyright (c) 2007, 2013, Pecunia Project. All rights reserved.
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
#import "Category.h"

@class BankQueryResult;
@class PurposeSplitRule;
@class BankStatement;
@class BankUser;

typedef enum {
    CTM_none = 0,
    CTM_all,
    CTM_ask
} CollectiveTransferMethod;

typedef enum {
    AccountType_Standard = 0,
    AccountType_CreditCart
} BankAccountType;


@interface BankAccount : Category<NSCopying> {
	NSDate				*newLatestTransferDate;
	PurposeSplitRule	*purposeSplitRule;
	NSArray				*dbStatements;
	NSInteger           unread;
}

-(NSString*)bankCode;
-(NSDate*)latestTransferDate;


- (void)evaluateQueryResult: (BankQueryResult*)res;
- (int)updateFromQueryResult: (BankQueryResult*)result;
- (void)updateStandingOrders: (NSArray*)orders;
- (void)copyStatement: (BankStatement*)stat;
- (void)copyStatementsToManualAccounts: (NSArray*)statements;
- (void)updateBalanceWithValue: (NSDecimalNumber*)value;
- (void)repairStatementBalances;
- (NSDate*)nextDateForDate: (NSDate*)date;
- (NSInteger)calcUnread;
- (BankUser*)defaultBankUser;
- (NSUInteger)balanceHistoryToDates: (NSArray**)dates
                           balances: (NSArray**)balances
                      balanceCounts: (NSArray**)counts
                       withGrouping: (GroupingInterval)interval;

+(BankAccount*)bankRootForCode:(NSString*)bankCode;
+(BankAccount*)accountWithNumber:(NSString*)number bankCode:(NSString*)code;
+(BankAccount*)accountWithNumber:(NSString*)number subNumber:(NSString*)subNumber bankCode:(NSString*)code;
+(NSInteger)maxUnread;

@property (nonatomic, strong) NSArray *dbStatements;
@property (nonatomic, strong) PurposeSplitRule *purposeSplitRule;

@property (nonatomic, strong) NSDate * latestTransferDate;
@property (nonatomic, strong) NSString * country;
@property (nonatomic, strong) NSString * bankName;
@property (nonatomic, strong) NSString * bankCode;
@property (nonatomic, strong) NSString * bic;
@property (nonatomic, strong) NSString * iban;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * customerId;
@property (nonatomic, strong) NSString * accountNumber;
@property (nonatomic, strong) NSString * owner;
@property (nonatomic, strong) NSNumber * uid;
@property (nonatomic, strong) NSNumber * type;
@property (nonatomic, strong) NSDecimalNumber * balance;
@property (nonatomic, strong) NSNumber * noAutomaticQuery;
@property (nonatomic, strong) NSNumber * collTransferMethod;
@property (nonatomic, strong) NSNumber * isManual;
@property (nonatomic, strong) NSNumber * isStandingOrderSupported;
@property (nonatomic, strong) NSString * splitRule;
@property (nonatomic, strong) NSString * accountSuffix;
@property (nonatomic, assign) NSInteger unread;
@property (nonatomic, strong) NSSet* users;

@end

// coalesce these into one @interface BankAccount (CoreDataGeneratedAccessors) section
@interface BankAccount (CoreDataGeneratedAccessors)
@end
