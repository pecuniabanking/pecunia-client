/**
 * Copyright (c) 2007, 2015, Pecunia Project. All rights reserved.
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

#import "BankingCategory.h"

@class BankQueryResult;
@class BankStatement;
@class BankUser;
@class DepotValueEntry;

typedef enum {
    CTM_none = 0,
    CTM_all,
    CTM_ask
} CollectiveTransferMethod;

/*
 Klassifizierung der Konten. Innerhalb der vorgegebenen Codebereiche sind kreditinstitutsindividuell bei Bedarf weitere Kontoarten möglich.
 Codierung:
 1 – 9: Kontokorrent-/Girokonto
 10 – 19: Sparkonto
 20 –29: Festgeldkonto (Termineinlagen)
 30 – 39: Wertpapierdepot
 40 – 49: Kredit-/Darlehenskonto
 50 – 59: Kreditkartenkonto
 60 – 69: Fonds-Depot bei einer Kapitalanlagegesellschaft
 70 – 79: Bausparvertrag
 80 – 89: Versicherungsvertrag
 90 – 99: Sonstige (nicht zuordenbar)
*/

typedef enum {
    AccountType_Standard = 0,
    AccountType_Savings,
    AccountType_TermDeposit,
    AccountType_Depot,
    AccountType_LoanAccount,
    AccountType_CreditCard,
    AccountType_FundDepot,
    AccountType_HomeLoanAccount,
    AccountType_InsuranceContract,
    AccountType_Others
} BankAccountType;


@interface BankAccount : BankingCategory<NSCopying> {
    NSDate           *newLatestTransferDate;
    NSArray          *dbStatements;
    NSInteger        unread;
}

@property (nonatomic, strong) NSArray         *dbStatements;

@property (nonatomic, strong) NSDate          *latestTransferDate;
@property (nonatomic, strong) NSString        *country;
@property (nonatomic, strong) NSString        *bankName;
@property (nonatomic, strong) NSString        *bankCode;
@property (nonatomic, strong) NSString        *bic;
@property (nonatomic, strong) NSString        *iban;
@property (nonatomic, strong) NSString        *userId;
@property (nonatomic, strong) NSString        *customerId;
@property (nonatomic, strong) NSString        *accountNumber;
@property (nonatomic, strong) NSString        *owner;
@property (nonatomic, strong) NSNumber        *uid;
@property (nonatomic, strong) NSNumber        *type;
@property (nonatomic, strong) NSDecimalNumber *balance;
@property (nonatomic, strong) NSNumber        *noAutomaticQuery;
@property (nonatomic, strong) NSNumber        *collTransferMethod;
@property (nonatomic, strong) NSNumber        *isManual;
@property (nonatomic, strong) NSNumber        *isStandingOrderSupported;
@property (nonatomic, strong) NSString        *splitRule;
@property (nonatomic, strong) NSString        *accountSuffix;
@property (nonatomic, assign) NSInteger       unread;
@property (nonatomic, strong) NSSet           *users;
@property (nonatomic, readonly) NSString      *localAccountName;
@property (nonatomic, strong) DepotValueEntry *depotValueEntry;

- (void)evaluateQueryResult: (BankQueryResult *)res;
- (int)updateFromQueryResult: (BankQueryResult *)result;
- (void)updateStandingOrders: (NSArray *)orders;
- (void)copyStatement: (BankStatement *)stat;
- (void)copyStatementsToManualAccounts: (NSArray *)statements;
- (void)updateBalanceWithValue: (NSDecimalNumber *)value;
- (void)moveStatementsFromAccount: (BankAccount *)sourceAccount;

- (BankAccountType)accountType;

// correction functions
- (void)updateStatementBalances;
- (void)doMaintenance;

- (NSDate *)nextDateForDate: (NSDate *)date;
- (NSInteger)calcUnread;
- (BankUser *)defaultBankUser;

- (NSString*)description;
- (NSString*)descriptionWithIndent: (NSString *)indent;
- (NSString*)typeName;

+ (BankAccount *)bankRootForCode: (NSString *)bankCode;
+ (BankAccount *)findAccountWithNumber: (NSString *)number bankCode: (NSString *)code;
+ (BankAccount *)findAccountWithNumber: (NSString *)number subNumber: (NSString *)subNumber bankCode: (NSString *)code;
+ (NSInteger)maxUnread;
+ (NSString *)findFreeAccountNumber;

@end

// coalesce these into one @interface BankAccount (CoreDataGeneratedAccessors) section
@interface BankAccount (CoreDataGeneratedAccessors)
@end
