/**
 * Copyright (c) 2007, 2014, Pecunia Project. All rights reserved.
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

typedef NS_ENUM(NSInteger, TransactionType) {
    TransactionType_TransferStandard = 0,
    TransactionType_TransferEU,
    TransactionType_TransferDated,
    TransactionType_TransferInternal,
    TransactionType_TransferDebit,
    TransactionType_TransferSEPA,
    TransactionType_StandingOrder,
    TransactionType_BankStatements,
    TransactionType_CCStatements,
    TransactionType_CCSettlementList,
    TransactionType_CCSettlement,
    TransactionType_ChangePin,
    TransactionType_StandingOrderSEPA,
    TransactionType_TransferSEPAScheduled,
    TransactionType_TransferCollectiveCreditSEPA,
    TransactionType_AccountStatements
};

@class BankAccount;
@class BankUser;
@class PecuniaError;

@interface SupportedTransactionInfo : NSManagedObject {
}

@property (nonatomic, strong) NSNumber *allowsChange;
@property (nonatomic, strong) NSNumber *allowsCollective;
@property (nonatomic, strong) NSNumber *allowsDated;
@property (nonatomic, strong) NSNumber *allowsList;
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSNumber *allowesDelete;

@property (nonatomic, strong) BankAccount *account;
@property (nonatomic, strong) BankUser    *user;

+ (SupportedTransactionInfo *)infoForType: (TransactionType)type account: (BankAccount *)account;
+ (NSArray *)supportedTransactionsForAccount: (BankAccount *)account;
+ (PecuniaError *)updateSupportedTransactionInfoForUser: (BankUser *)user
                                                account: (BankAccount *)account
                                               withJobs: (NSArray *)supportedJobNames;

- (NSString *)description;
- (NSString *)descriptionWithIndent: (NSString *)indent;

@end
