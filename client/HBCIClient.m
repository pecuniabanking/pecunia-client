//
//  HBCIClient.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "HBCIClient.h"
#import "BankInfo.h"
#import "PecuniaError.h"
#import "BankQueryResult.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "Transfer.h"
#import "MOAssistant.h"
#import "TransferResult.h"
#import "BankingController.h"
#import "WorkerThread.h"
#import "ABUser.h"
#import "ABAccount.h"
#import "ABController.h";

static HBCIClient *client = nil;

@implementation HBCIClient

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	
	bridge = [[ABController alloc ] init ];	
	return self;
}

-(void)dealloc
{
	[bridge release ];
	[bankInfo release ];
	[countryInfos release ];
	[super dealloc ];
}

-(void)readCountryInfos
{
	NSString *path = [[NSBundle mainBundle ] pathForResource: @"CountryInfo" ofType: @"txt" ];
	NSString *data = [NSString stringWithContentsOfFile:path ];
	NSArray *lines = [data componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet ] ];
	NSString *line;
	for(line in lines) {
		NSArray *infos = [line componentsSeparatedByString: @";" ];
		[countryInfos setObject: infos forKey: [infos objectAtIndex: 2 ] ];
	}
}

-(NSDictionary*)countryInfos
{
	return countryInfos;
}

-(BankInfo*)infoForBankCode: (NSString*)bankCode inCountry:(NSString*)country
{
	return [bridge infoForBankCode:bankCode inCountry:country ];
}

-(NSString*)bankNameForCode:(NSString*)bankCode inCountry:(NSString*)country
{
	return [bridge bankNameForCode:bankCode inCountry:country ];
}

-(NSString*)bankNameForBIC:(NSString*)bic inCountry:(NSString*)country
{
	return [bridge bankNameForBic:bic inCountry:country ];
}


-(BOOL)addAccount: (BankAccount*)account forUser: (ABUser*)user
{
	return [bridge addAccount:account forUser:user ];
}

-(BOOL)changeAccount:(BankAccount*)account
{
	return [bridge changeAccount:account ];
}


-(BOOL)isTransferSupported:(TransferType)tt forAccount:(BankAccount*)account
{
	return [bridge isTransferSupported: tt forAccount: account ];
}

-(BOOL)isStandingOrderSupportedForAccount:(BankAccount*)account
{
	return [bridge isStandingOrderSupportedForAccount:account ];
}


-(NSArray*)allowedCountriesForAccount:(BankAccount*)account
{
	return [bridge allowedCountriesForAccount:account ];
}

-(NSDictionary*)allCountries
{
	return [bridge countries ];
}


-(TransactionLimits*)limitsForType:(TransferType)tt account:(BankAccount*)account country:(NSString*)ctry
{
	return [bridge limitsForType:tt account:account country:ctry ];
}

-(TransactionLimits*)standingOrderLimitsForAccount:(BankAccount*)account action:(StandingOrderAction)action
{
	return [bridge standingOrderLimitsForAccount:account action:action ];
}


+(HBCIClient*)hbciClient
{
	if(client == nil) client = [[HBCIClient alloc ] init ];
	return client;
}

-(NSArray*)accounts
{
	return [bridge accounts ];
}

-(void)getStatements:(NSArray*)resultList
{
	// get statements in separate thread
	[bridge performSelector:@selector(statementsForAccounts:) onThread:[WorkerThread thread ] withObject:resultList waitUntilDone:NO ];
//	[bridge statementsForAccounts:resultList ];
}

-(void)getStandingOrders:(NSArray*)accts
{
	[bridge standingOrdersForAccounts:accts ];
}

-(BOOL)updateStandingOrders:(NSArray*)orders
{
	return [bridge updateStandingOrders:orders ];
}

-(BOOL)sendTransfers:(NSArray*)transfers
{
	return [bridge sendTransfers:transfers ];
}

-(BOOL)checkAccount: (NSString*)accountNumber forBank: (NSString*)bankCode inCountry: (NSString*)country
{
	return [bridge checkAccount:accountNumber forBank:bankCode inCountry:country ];
}


-(BOOL)checkIBAN: (NSString*)iban
{
	return [bridge checkIBAN:iban ];
}

-(void)changePinTanMethodForUser:(ABUser*)user method:(int)method
{
	[bridge changePinTanMethodForUser:user method:method ];
}


-(NSArray*)users
{
	return [bridge users ];
}

-(NSString*)addBankUser:(ABUser*)user
{
	return [bridge addBankUser: user ];
}

-(NSString*)addBankUserCocoa
{
	return [bridge addBankUserCocoa ];
}


-(BOOL)deleteBankUser:(ABUser*)user
{
	return [bridge deleteBankUser: user ];
}

-(NSString*)getSystemIDForUser:(ABUser*)user
{
	return [bridge getSystemIDForUser:user ];
}

-(void)setLogLevel:(LogLevel)level
{
	[bridge setLogLevel:level ];
}

-(NSArray*)accountsByUser:(ABUser*)user
{
	NSMutableArray *accounts = [NSMutableArray arrayWithCapacity:10 ];
	for(ABAccount *account in [self accounts ]) {
		if ([account.customerId isEqualToString: user.customerId ] &&
			[account.userId isEqualToString:user.userId ]) {
			[accounts addObject: account ];
		}
	}
	return accounts;
}

@end
