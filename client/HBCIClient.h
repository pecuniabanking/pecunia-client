//
//  HBCIClient.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Transfer.h"
#import "StandingOrder.h"
#import "MessageLog.h"

@class BankInfo;
@class ABUser;
@class PecuniaError;
@class BankAccount;
@class Account;
@class ABController;
@class TransactionLimits;

@interface HBCIClient : NSObject {
	ABController	*bridge;
	
	NSMutableDictionary	*bankInfo;
	NSMutableDictionary *countryInfos;
	NSArray				*bankQueryResults;
	int					currentQuery;
	id					asyncCommandSender;
}

-(void)readCountryInfos;
-(NSDictionary*)countryInfos;

-(NSArray*)accounts;
-(NSArray*)accountsByUser:(ABUser*)user;
-(NSArray*)users;

// HBCI Methods
-(BankInfo*)infoForBankCode: (NSString*)bankCode inCountry:(NSString*)country;
-(NSString*)bankNameForCode:(NSString*)bankCode inCountry:(NSString*)country;
-(NSString*)bankNameForBIC:(NSString*)bic inCountry:(NSString*)country;
-(void)getStatements:(NSArray*)resultList;
-(void)getStandingOrders:(NSArray*)accounts;
-(BOOL)checkAccount: (NSString*)accountNumber forBank: (NSString*)bankCode inCountry: (NSString*)country;
-(BOOL)checkIBAN: (NSString*)iban;
-(void)asyncCommandCompletedWithResult:(id)result error:(PecuniaError*)err;
-(BOOL)isTransferSupported:(TransferType)tt forAccount:(BankAccount*)account;
-(BOOL)isStandingOrderSupportedForAccount:(BankAccount*)account;
-(BOOL)sendTransfers:(NSArray*)transfers;
-(NSArray*)allowedCountriesForAccount:(BankAccount*)account;
-(NSDictionary*)allCountries;
-(TransactionLimits*)limitsForType:(TransferType)tt account:(BankAccount*)account country:(NSString*)ctry;
-(TransactionLimits*)standingOrderLimitsForAccount:(BankAccount*)account action:(StandingOrderAction)action;
-(BOOL)updateStandingOrders:(NSArray*)orders;

-(BOOL)addAccount: (BankAccount*)account forUser: (ABUser*)user;
-(BOOL)changeAccount:(BankAccount*)account;

-(NSString*)addBankUser:(ABUser*)user;
-(BOOL)deleteBankUser:(ABUser*)user;
-(NSString*)getSystemIDForUser:(ABUser*)user;

-(void)setLogLevel:(LogLevel)level;


+(HBCIClient*)hbciClient;

@end
