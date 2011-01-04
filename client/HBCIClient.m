//
//  HBCIClient.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "HBCIClient.h"
#import "HBCIBridge.h"
#import "Passport.h"
#import "BankInfo.h"
#import "HBCIError.h"
#import "PecuniaError.h"
#import "Account.h"
#import "BankQueryResult.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "Transfer.h"
#import "MOAssistant.h"
#import "TransferResult.h"
#import "BankingController.h"
#import "WorkerThread.h"

#import "ABController.h";

static HBCIClient *client = nil;

@implementation HBCIClient

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	
	bridge = [[ABController alloc ] init ];
	
/*	
	bridge = [[HBCIBridge alloc ] initWithClient: self ];
	[bridge startup ];
	passports = [[NSMutableArray alloc ] initWithCapacity: 10 ];
	accounts = [[NSMutableArray alloc ] initWithCapacity: 10 ];
	bankInfo = [[NSMutableDictionary alloc ] initWithCapacity: 10];
	countryInfos = [[NSMutableDictionary alloc ] initWithCapacity: 50];
	[self readCountryInfos ];
*/ 
	return self;
}

-(void)dealloc
{
	[bridge release ];
	[passports release ];
	[accounts release ];
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

-(NSArray*)initHBCI
{
	return passports;
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


-(void)asyncCommandCompletedWithResult:(id)result error:(PecuniaError*)err
{
/*	
	if(err == nil && result != nil) {
		BankQueryResult *res;

		for(res in result) {
			// find corresponding incoming structure
			BankQueryResult *iResult;
			for(iResult in bankQueryResults) {
				if([iResult.accountNumber isEqual: res.accountNumber ] && [iResult.bankCode isEqual: res.bankCode ]) break;
			}
			// saldo of the last statement is current saldo
			if ([res.statements count ] > 0) {
				BankStatement *stat = [res.statements objectAtIndex: [res.statements count ] - 1 ];
				iResult.balance = stat.saldo;
				
				// ensure order by refining posting date
				int seconds;
				NSDate *oldDate = [NSDate distantPast ];
				for(stat in res.statements) {
					if([stat.date compare: oldDate ] != NSOrderedSame) {
						seconds = 0;
						oldDate = stat.date;
					} else seconds += 100;
					if(seconds > 0) stat.date = [[[NSDate alloc ] initWithTimeInterval: seconds sinceDate: stat.date ] autorelease ];
				}
				iResult.statements = res.statements;
			}
		}
	}
	if(err) {
		[err alertPanel ];	
		[asyncCommandSender statementsNotification: nil ];
	} else [asyncCommandSender statementsNotification: bankQueryResults ];
	[bankQueryResults release ];
*/ 
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

-(NSArray*)users
{
	return [bridge users ];
}

-(void)startLog:(id <MessageLog>)logger withLevel:(LogLevel)level withDetails:(BOOL)details
{
	[bridge startLog:logger withLevel:level withDetails:details ];
}

-(void)endLog
{
	[bridge endLog ];
}

-(NSString*)addBankUser:(ABUser*)user
{
	return [bridge addBankUser: user ];
}

-(BOOL)removeBankUser:(ABUser*)user
{
	return [bridge removeBankUser: user ];
}

-(NSString*)getSystemIDForUser:(ABUser*)user
{
	return [bridge getSystemIDForUser:user ];
}


@end
