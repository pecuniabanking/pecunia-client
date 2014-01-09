/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#define PecuniaStatementsNotification       @"PecuniaStatementsNotification"
#define PecuniaInstituteMessageNotification @"PecuniaInstMessageNotification"

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

@protocol HBCIBackend

- (PecuniaError *)initalizeHBCI;

- (NSArray *)supportedVersions;

- (BankInfo *)infoForBankCode: (NSString *)bankCode inCountry: (NSString *)country;
- (BankSetupInfo *)getBankSetupInfo: (NSString *)bankCode;
- (NSString *)bankNameForCode: (NSString *)bankCode inCountry: (NSString *)country;
- (NSString *)bankNameForIBAN: (NSString *)iban;
- (NSString *)bicForIBAN: (NSString*)iban;
- (BankParameter *)getBankParameterForUser: (BankUser *)user;
- (PecuniaError *)updateTanMethodsForUser: (BankUser *)user;
- (PecuniaError *)updateTanMediaForUser: (BankUser *)user;
- (PecuniaError *)sendCollectiveTransfer: (NSArray *)transfers;

- (BOOL)checkAccount: (NSString *)accountNumber forBank: (NSString *)bankCode;
- (BOOL)checkIBAN: (NSString *)iban;

- (BOOL)isTransferSupported: (TransferType)tt forAccount: (BankAccount *)account;
- (BOOL)isStandingOrderSupportedForAccount: (BankAccount *)account;
- (BOOL)isTransactionSupported: (TransactionType)tt forAccount: (BankAccount *)account;
- (BOOL)isTransactionSupported: (TransactionType)tt forUser: (BankUser *)user;
- (NSArray *)allowedCountriesForAccount: (BankAccount *)account;
- (TransactionLimits *)limitsForType: (TransferType)tt account: (BankAccount *)account country: (NSString *)ctry;
- (TransactionLimits *)standingOrderLimitsForAccount: (BankAccount *)account action: (StandingOrderAction)action;

- (void)getStatements: (NSArray *)resultList;
- (void)getStandingOrders: (NSArray *)resultList;
- (PecuniaError *)getBalanceForAccount: (BankAccount *)account;

- (BOOL)sendTransfers: (NSArray *)transfers;
- (PecuniaError *)sendStandingOrders: (NSArray *)orders;
- (PecuniaError *)changePinTanMethodForUser: (BankUser *)user;
- (PecuniaError *)changePinForUser: (BankUser *)user toPin: (NSString *)newPin;
- (PecuniaError *)sendCustomerMessage: (CustomerMessage *)msg;

- (PecuniaError *)addAccount: (BankAccount *)account forUser: (BankUser *)user;
- (PecuniaError *)changeAccount: (BankAccount *)account;
- (PecuniaError *)setAccounts: (NSArray *)bankAccounts;
- (NSArray *)getAccountsForUser: (BankUser *)user;

- (PecuniaError *)addBankUser: (BankUser *)user;
- (BOOL)deleteBankUser: (BankUser *)user;
- (PecuniaError *)updateBankDataForUser: (BankUser *)user;
- (NSArray *)getSupportedBusinessTransactions: (BankAccount *)account;

- (PecuniaError *)setLogLevel: (LogLevel)level;

- (CreditCardSettlement *)getCreditCardSettlement: (NSString *)settleId forAccount: (BankAccount *)account;
- (CCSettlementList *)getCCSettlementListForAccount: (BankAccount *)account;

- (NSArray *)getOldBankUsers;
- (NSDictionary *)countries;

@end
