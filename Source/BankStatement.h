/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

@class BankAccount;
@class ClassificationContext;
@class BankingCategory;
@class StatCatAssignment;
@class SepaData;

typedef enum {
    StatementType_Standard = 0,
    StatementType_CreditCard
} BankStatementType;

@interface BankStatement : NSManagedObject {
}

- (BOOL)matches: (BankStatement *)stat;
- (BOOL)matchesAndRepair: (BankStatement *)stat;

- (NSComparisonResult)compareValuta: (BankStatement *)stat;

- (void)assignToCategory: (BankingCategory *)cat;
- (void)assignAmount: (NSDecimalNumber *)value toCategory: (BankingCategory *)targetCategory withInfo:(NSString *)info;
- (BOOL)updateAssigned;
- (BOOL)hasAssignment;
- (NSDecimalNumber *)residualAmount;
- (StatCatAssignment *)bankAssignment;
- (NSArray *)categoryAssignments;
- (void)changeValueTo: (NSDecimalNumber *)val;

- (void)addToAccount: (BankAccount *)account;
- (void)sanitize;
- (void)extractSEPADataUsingContext: (NSManagedObjectContext *)context;

- (NSString *)floatingPurpose;
- (NSString *)nonfloatingPurpose;

+ (void)initCategoriesCache;

@property (nonatomic, strong) NSDate *valutaDate;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *docDate;

@property (nonatomic, strong) NSDecimalNumber *value;
@property (nonatomic, strong) NSDecimalNumber *origValue;
@property (nonatomic, strong) NSDecimalNumber *nassValue;
@property (nonatomic, strong) NSDecimalNumber *charge;
@property (nonatomic, strong) NSDecimalNumber *saldo;


@property (nonatomic, strong) NSString *remoteName;
@property (nonatomic, strong) NSString *remoteIBAN;
@property (nonatomic, strong) NSString *remoteBIC;
@property (nonatomic, strong) NSString *remoteBankCode;
@property (nonatomic, strong) NSString *remoteBankName;
@property (nonatomic, strong) NSString *remoteAccount;
@property (nonatomic, strong) NSString *remoteCountry;
@property (nonatomic, strong) NSString *purpose;
@property (nonatomic, strong) NSString *localSuffix;
@property (nonatomic, strong) NSString *remoteSuffix;

@property (nonatomic, strong) NSString *ccNumberUms;
@property (nonatomic, strong) NSString *ccChargeKey;
@property (nonatomic, strong) NSString *ccChargeForeign;
@property (nonatomic, strong) NSString *ccChargeTerminal;
@property (nonatomic, strong) NSString *ccSettlementRef;
@property (nonatomic, strong) NSString *origCurrency;
@property (nonatomic, strong) NSNumber *isSettled;


@property (nonatomic, strong, readonly) NSString *categoriesDescription;

@property (nonatomic, strong) NSString *localBankCode, *localAccount;
@property (nonatomic, strong) NSString *customerReference;
@property (nonatomic, strong) NSString *bankReference;
@property (nonatomic, strong) NSString *transactionText;
@property (nonatomic, strong) NSNumber *transactionCode;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *primaNota;

@property (nonatomic, weak, readonly) NSString *note;

@property (nonatomic, strong) NSString *additional;
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSNumber *isAssigned;             // assigned to >= 100%
@property (nonatomic, strong) NSNumber *isManual;
@property (nonatomic, strong) NSNumber *isStorno;
@property (nonatomic, strong) NSNumber *isNew;
@property (nonatomic, strong) NSNumber *isPreliminary;

@property (nonatomic, strong) NSString *ref1;
@property (nonatomic, strong) NSString *ref2;
@property (nonatomic, strong) NSString *ref3;
@property (nonatomic, strong) NSString *ref4;

@property (nonatomic, strong) BankAccount *account;
@property (nonatomic, strong) SepaData    *sepa;
@property (nonatomic, strong) NSSet       *tags;

@end

// coalesce these into one @interface BankStatement (CoreDataGeneratedAccessors) section
@interface BankStatement (CoreDataGeneratedAccessors)
@end
