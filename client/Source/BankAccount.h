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
#import "Category.h"

@class BankQueryResult;
@class PurposeSplitRule;
@class BankStatement;
@class BankUser;

@interface BankAccount : Category<NSCopying> {
	NSDate				*newLatestTransferDate;
	PurposeSplitRule	*purposeSplitRule;
	NSArray				*dbStatements;
	NSInteger           unread;
}

-(NSString*)bankCode;
-(NSDate*)latestTransferDate;


-(void)evaluateQueryResult: (BankQueryResult*)res;
-(int)updateFromQueryResult: (BankQueryResult*)result;
-(void)updateStandingOrders:(NSArray*)orders;
-(void)copyStatement:(BankStatement*)stat;
-(void)copyStatementsToManualAccounts:(NSArray*)statements;
-(void)updateBalanceWithValue:(NSDecimalNumber*)value;
-(void)repairStatementBalances;
-(NSDate*)nextDateForDate:(NSDate*)date;
-(NSInteger)calcUnread;
-(BankUser*)defaultBankUser;

+(BankAccount*)bankRootForCode:(NSString*)bankCode;
+(BankAccount*)accountWithNumber:(NSString*)number bankCode:(NSString*)code;
+(BankAccount*)accountWithNumber:(NSString*)number subNumber:(NSString*)subNumber bankCode:(NSString*)code;
+(NSInteger)maxUnread;

@property (nonatomic, retain) NSArray *dbStatements;
@property (nonatomic, retain) PurposeSplitRule *purposeSplitRule;

@property (nonatomic, retain) NSDate * latestTransferDate;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * bankName;
@property (nonatomic, retain) NSString * bankCode;
@property (nonatomic, retain) NSString * bic;
@property (nonatomic, retain) NSString * iban;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * customerId;
@property (nonatomic, retain) NSString * accountNumber;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSDecimalNumber * balance;
@property (nonatomic, retain) NSNumber * noAutomaticQuery;
@property (nonatomic, retain) NSNumber * collTransfer;
@property (nonatomic, retain) NSNumber * isManual;
@property (nonatomic, retain) NSNumber * isStandingOrderSupported;
@property (nonatomic, retain) NSString * splitRule;
@property (nonatomic, retain) NSString * accountSuffix;
@property (nonatomic, assign) NSInteger unread;
@property (nonatomic, retain) NSSet* users;

@end

// coalesce these into one @interface BankAccount (CoreDataGeneratedAccessors) section
@interface BankAccount (CoreDataGeneratedAccessors)
@end
