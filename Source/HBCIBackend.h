/**
 * Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
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
#import "MessageLog.h"
#import "Transfer.h"
#import "StandingOrder.h"
#import "SupportedTransactionInfo.h"

#define PecuniaStatementsNotification         @"PecuniaStatementsNotification"
#define PecuniaStatementsFinalizeNotification @"PecuniaStatementsFinalizeNotification"
#define PecuniaInstituteMessageNotification   @"PecuniaInstMessageNotification"

@class BankInfo;
@class TransactionLimits;
@class BankUser;
@class BankAccount;
@class PecuniaError;
@class BankParameter;
@class CustomerMessage;
@class TanMediaList;
@class BankSetupInfo;
@class CCSettlementList;
@class CreditCardSettlement;
@class AccountStatement;
@class AccountStatementParameters;

@protocol HBCIBackend

- (PecuniaError *)initalizeHBCI;

// Information Methods
- (NSArray *)supportedVersions;
- (BankInfo *)infoForBankCode: (NSString *)bankCode;
- (BankSetupInfo *)getBankSetupInfo: (NSString *)bankCode;
- (NSString *)bankNameForCode: (NSString *)bankCode;
- (NSString *)bankNameForIBAN: (NSString *)iban;
- (NSString *)bicForIBAN: (NSString*)iban;
- (BankParameter *)getBankParameterForUser: (BankUser *)user;
- (NSDictionary *)countries;

// TAN Methods & Media
- (PecuniaError *)updateTanMethodsForUser: (BankUser *)user;
- (PecuniaError *)updateTanMediaForUser: (BankUser *)user;

// Supported Transactions
- (BOOL)isTransferSupported: (TransferType)tt forAccount: (BankAccount *)account;
- (BOOL)isTransactionSupported: (TransactionType)tt forAccount: (BankAccount *)account;
- (BOOL)isTransactionSupported: (TransactionType)tt forUser: (BankUser *)user;
- (NSArray *)allowedCountriesForAccount: (BankAccount *)account;
- (TransactionLimits *)limitsForType: (TransferType)tt account: (BankAccount *)account country: (NSString *)ctry;
- (TransactionLimits *)standingOrderLimitsForAccount: (BankAccount *)account action: (StandingOrderAction)action;
- (NSArray *)getSupportedBusinessTransactions: (BankAccount *)account;
- (PecuniaError*)updateSupportedTransactionsForUser:(BankUser *)user;

// Accounts
- (PecuniaError *)addAccount: (BankAccount *)account forUser: (BankUser *)user;
- (PecuniaError *)changeAccount: (BankAccount *)account;
- (PecuniaError *)setAccounts: (NSArray *)bankAccounts;
- (NSArray *)getAccountsForUser: (BankUser *)user;

// Get Statements & Orders
- (void)getStatements: (NSArray *)resultList;
- (void)getStandingOrders: (NSArray *)resultList;

// Get Balance
- (PecuniaError *)getBalanceForAccount: (BankAccount *)account;

// Send Transfers
- (BOOL)sendTransfers: (NSArray *)transfers;
- (PecuniaError *)sendCollectiveTransfer: (NSArray *)transfers;

// Standing Orders
- (PecuniaError *)sendStandingOrders: (NSArray *)orders;

// Bank User Handling
- (PecuniaError *)addBankUser: (BankUser *)user;
- (BOOL)deleteBankUser: (BankUser *)user;
- (PecuniaError *)updateBankDataForUser: (BankUser *)user;
- (NSArray *)getOldBankUsers;
- (PecuniaError *)synchronizeUser: (BankUser *)user;

// Customer Message
- (PecuniaError *)sendCustomerMessage: (CustomerMessage *)msg;

// PIN/TAN Handling
- (PecuniaError *)changePinTanMethodForUser: (BankUser *)user;
- (PecuniaError *)changePinForUser: (BankUser *)user toPin: (NSString *)newPin;

// Credit Card Settlements
- (CreditCardSettlement *)getCreditCardSettlement: (NSString *)settleId forAccount: (BankAccount *)account;
- (CCSettlementList *)getCCSettlementListForAccount: (BankAccount *)account;

// AccountStatements
- (AccountStatement *)getAccountStatement: (int)number year: (int)year account: (BankAccount *)account;
- (AccountStatementParameters *)getAccountStatementParametersForUser: (BankUser *)user;

// Misc
- (PecuniaError *)setLogLevel: (HBCILogLevel)level;


@end
