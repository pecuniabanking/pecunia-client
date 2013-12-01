/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

#import "HBCIClient.h"
#import "Account.h"
#import "CustomerMessage.h"

static HBCIClient *client = nil;

@implementation HBCIClient

- (id)init
{
    self = [super init];
    if (self != nil) {
        controller = [[HBCIController alloc] init];
    }
    return self;
}

- (PecuniaError *)initalizeHBCI
{
    return [controller initalizeHBCI];
}

- (NSArray *)supportedVersions
{
    return [controller supportedVersions];
}

- (BankInfo *)infoForBankCode: (NSString *)bankCode inCountry: (NSString *)country
{
    return [controller infoForBankCode: bankCode inCountry: country];
}

- (BankParameter *)getBankParameterForUser: (BankUser *)user
{
    return [controller getBankParameterForUser: user];
}

- (NSString *)bankNameForCode: (NSString *)bankCode inCountry: (NSString *)country
{
    return [controller bankNameForCode: bankCode inCountry: country];
}

- (NSString *)bankNameForIBAN: (NSString *)iban
{
    return [controller bankNameForIBAN: iban];
}

- (PecuniaError *)addAccount: (BankAccount *)account forUser: (BankUser *)user
{
    return [controller addAccount: account forUser: user];
}

- (PecuniaError *)changeAccount: (BankAccount *)account
{
    return [controller changeAccount: account];
}

- (PecuniaError *)setAccounts: (NSArray *)bankAccounts
{
    return [controller setAccounts: bankAccounts];
}

- (BOOL)isTransferSupported: (TransferType)tt forAccount: (BankAccount *)account
{
    return [controller isTransferSupported: tt forAccount: account];
}

- (BOOL)isStandingOrderSupportedForAccount: (BankAccount *)account
{
    return [controller isStandingOrderSupportedForAccount: account];
}

- (NSArray *)allowedCountriesForAccount: (BankAccount *)account
{
    return [controller allowedCountriesForAccount: account];
}

- (NSDictionary *)countries
{
    return [controller countries];
}

- (TransactionLimits *)limitsForType: (TransferType)tt account: (BankAccount *)account country: (NSString *)ctry
{
    return [controller limitsForType: tt account: account country: ctry];
}

- (TransactionLimits *)standingOrderLimitsForAccount: (BankAccount *)account action: (StandingOrderAction)action
{
    return [controller standingOrderLimitsForAccount: account action: action];
}

+ (HBCIClient *)hbciClient
{
    if (client == nil) {
        client = [[HBCIClient alloc] init];
    }
    return client;
}

- (void)getStatements: (NSArray *)resultList
{
    [controller getStatements: resultList];
    // get statements in separate thread
    //	[bridge performSelector:@selector(statementsForAccounts:) onThread:[WorkerThread thread ] withObject:resultList waitUntilDone:NO ];
    //	[bridge statementsForAccounts:resultList ];
}

- (void)getStandingOrders: (NSArray *)resultList
{
    [controller getStandingOrders: resultList];
}

- (PecuniaError *)sendStandingOrders: (NSArray *)orders
{
    return [controller sendStandingOrders: orders];
}

- (BOOL)sendTransfers: (NSArray *)transfers
{
    return [controller sendTransfers: transfers];
}

- (BOOL)checkAccount: (NSString *)accountNumber forBank: (NSString *)bankCode
{
    return [controller checkAccount: accountNumber forBank: bankCode];
}

- (BOOL)checkIBAN: (NSString *)iban
{
    return [controller checkIBAN: iban];
}

- (PecuniaError *)changePinTanMethodForUser: (BankUser *)user
{
    return [controller changePinTanMethodForUser: user];
}

- (PecuniaError *)addBankUser: (BankUser *)user
{
    return [controller addBankUser: user];
}

- (BOOL)deleteBankUser: (BankUser *)user
{
    return [controller deleteBankUser: user];
}

- (PecuniaError *)updateBankDataForUser: (BankUser *)user
{
    return [controller updateBankDataForUser: user];
}

- (PecuniaError *)setLogLevel: (LogLevel)level
{
    return [controller setLogLevel: level];
}

- (NSArray *)getAccountsForUser: (BankUser *)user
{
    return [controller getAccountsForUser: user];
}

- (PecuniaError *)sendCustomerMessage: (CustomerMessage *)msg
{
    return [controller sendCustomerMessage: msg];
}

- (NSArray *)getSupportedBusinessTransactions: (BankAccount *)account
{
    return [controller getSupportedBusinessTransactions: account];
}

- (PecuniaError *)updateTanMethodsForUser: (BankUser *)user
{
    return [controller updateTanMethodsForUser: user];
}

- (PecuniaError *)updateTanMediaForUser: (BankUser *)user
{
    return [controller updateTanMediaForUser: user];
}

- (BankSetupInfo *)getBankSetupInfo: (NSString *)bankCode
{
    return [controller getBankSetupInfo: bankCode];
}

- (PecuniaError *)getBalanceForAccount: (BankAccount *)account
{
    return [controller getBalanceForAccount: account];
}

- (NSArray *)getOldBankUsers
{
    return [controller getOldBankUsers];
}

- (PecuniaError *)sendCollectiveTransfer: (NSArray *)transfers
{
    return [controller sendCollectiveTransfer: (NSArray *)transfers];
}

- (CreditCardSettlement *)getCreditCardSettlement: (NSString *)settleId forAccount: (BankAccount *)account
{
    return [controller getCreditCardSettlement: settleId forAccount: account];
}

- (CCSettlementList *)getCCSettlementListForAccount: (BankAccount *)account
{
    return [controller getCCSettlementListForAccount: account];
}

- (BOOL)isTransactionSupported: (TransactionType)tt forAccount: (BankAccount *)account
{
    return [controller isTransactionSupported: tt forAccount: account];
}

- (BOOL)isTransactionSupported: (TransactionType)tt forUser: (BankUser *)user
{
    return [controller isTransactionSupported:tt forUser:user];
}

- (PecuniaError *)changePinForUser: (BankUser *)user toPin: (NSString *)newPin
{
    return [controller changePinForUser:user toPin:newPin];
}


@end
