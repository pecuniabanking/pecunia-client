/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#define PecuniaStatementsNotification @"PecuniaStatementsNotification"
#define PecuniaInstituteMessageNotification @"PecuniaInstMessageNotification"

@class BankInfo;
@class TransactionLimits;
@class User;
@class BankUser;
@class BankAccount;
@class PecuniaError;
@class BankParameter;
@class CustomerMessage;
@class TanMediaList;

@protocol HBCIBackend

-(NSArray*)initHBCI;

-(NSArray*)supportedVersions;

-(BankInfo*)infoForBankCode: (NSString*)bankCode inCountry:(NSString*)country;
-(NSString*)bankNameForCode:(NSString*)bankCode inCountry:(NSString*)country;
-(NSString*)bankNameForBIC:(NSString*)bic inCountry:(NSString*)country;
-(BankParameter*)getBankParameterForUser:(User*)user;
-(PecuniaError*)updateTanMethodsForUser:(BankUser*)user;
- (PecuniaError*)updateTanMediaForUser:(BankUser*)user;

-(BOOL)checkAccount: (NSString*)accountNumber forBank: (NSString*)bankCode inCountry: (NSString*)country;
-(BOOL)checkIBAN: (NSString*)iban;

-(BOOL)isTransferSupported:(TransferType)tt forAccount:(BankAccount*)account;
-(BOOL)isStandingOrderSupportedForAccount:(BankAccount*)account;
-(NSArray*)allowedCountriesForAccount:(BankAccount*)account;
-(TransactionLimits*)limitsForType:(TransferType)tt account:(BankAccount*)account country:(NSString*)ctry;
-(TransactionLimits*)standingOrderLimitsForAccount:(BankAccount*)account action:(StandingOrderAction)action;

-(void)getStatements:(NSArray*)resultList;
-(void)getStandingOrders:(NSArray*)resultList;

-(BOOL)sendTransfers:(NSArray*)transfers;
-(PecuniaError*)sendStandingOrders:(NSArray*)orders;
-(PecuniaError*)changePinTanMethodForUser:(User*)user;
-(PecuniaError*)sendCustomerMessage:(CustomerMessage*)msg;

-(PecuniaError*)addAccount: (BankAccount*)account forUser: (User*)user;
-(PecuniaError*)changeAccount:(BankAccount*)account;
-(PecuniaError*)setAccounts:(NSArray*)bankAccounts;
-(NSArray*)getAccountsForUser: (User*)user;

-(PecuniaError*)addBankUser:(User*)user;
-(BOOL)deleteBankUser:(User*)user;
-(PecuniaError*)updateBankDataForUser:(User*)user;
-(NSArray*)getSupportedBusinessTransactions: (BankAccount*)account;

-(PecuniaError*)setLogLevel:(LogLevel)level;

-(NSArray*)users;
-(NSDictionary*)countries;

@end
