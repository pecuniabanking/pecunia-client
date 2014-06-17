/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
    AccountStatement_MT940 = 1,
    AccountStatement_ISO8583,
    AccountStatement_PDF
} AccountStatementFormat;

@class BankAccount, BankStatement;

@interface AccountStatement : NSManagedObject

@property (nonatomic, retain) NSData * document;
@property (nonatomic) AccountStatementFormat format;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSString * conditions;
@property (nonatomic, retain) NSString * advertisement;
@property (nonatomic, retain) NSString * iban;
@property (nonatomic, retain) NSString * bic;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * confirmationCode;
@property (nonatomic, retain) BankAccount *account;
@property (nonatomic, retain) NSSet *statements;
@end

@interface AccountStatement (CoreDataGeneratedAccessors)

- (void)addStatementsObject:(BankStatement *)value;
- (void)removeStatementsObject:(BankStatement *)value;
- (void)addStatements:(NSSet *)values;
- (void)removeStatements:(NSSet *)values;

@end
