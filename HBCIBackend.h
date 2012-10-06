//
//  HBCIBackend.h
//  Pecunia
//
//  Created by Frank Emminghaus on 29.07.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageLog.h"
#import "Transfer.h"
#import "StandingOrder.h"

#define PecuniaStatementsNotification @"PecuniaStatementsNotification"

@class BankInfo;
@class TransactionLimits;
@class User;
@class BankAccount;
@class PecuniaError;
@class BankParameter;

@protocol HBCIBackend

-(NSArray*)initHBCI;

-(NSArray*)supportedVersions;

-(BankInfo*)infoForBankCode: (NSString*)bankCode inCountry:(NSString*)country;
-(NSString*)bankNameForCode:(NSString*)bankCode inCountry:(NSString*)country;
-(NSString*)bankNameForBIC:(NSString*)bic inCountry:(NSString*)country;
-(BankParameter*)getBankParameterForUser:(User*)user;

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

-(PecuniaError*)addAccount: (BankAccount*)account forUser: (User*)user;
-(PecuniaError*)changeAccount:(BankAccount*)account;
-(PecuniaError*)setAccounts:(NSArray*)bankAccounts;
-(NSArray*)getAccountsForUser: (User*)user;

-(PecuniaError*)addBankUser:(User*)user;
-(BOOL)deleteBankUser:(User*)user;
-(PecuniaError*)updateBankDataForUser:(User*)user;

-(PecuniaError*)setLogLevel:(LogLevel)level;

-(NSArray*)users;
-(NSDictionary*)countries;

@end
