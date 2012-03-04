//
//  HBCIClient.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//


#import "HBCIClient.h"
#import "User.h"
#import "Account.h"
#import "CustomerMessage.h"

static HBCIClient *client = nil;

@implementation HBCIClient

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	
#ifdef HBCI4JAVA
	controller = [[HBCIController alloc] init];
#endif
	
#ifdef AQBANKING
	controller = [[ABController alloc] init];
#endif

	return self;
}

-(void)dealloc
{
#ifdef HBCI4JAVA
    // Cast needed as the protocol itself doesn't support -release.
	[(HBCIController*)controller release];
#endif
	
#ifdef AQBANKING
	[(ABController*)controller release];
#endif

	[super dealloc ];
}

-(NSArray*)initHBCI
{
	return [controller initHBCI ];
}

-(NSArray*)supportedVersions
{
	return [controller supportedVersions ];
}

-(BankInfo*)infoForBankCode: (NSString*)bankCode inCountry:(NSString*)country
{
	return [controller infoForBankCode:bankCode inCountry:country ];	
}

-(BankParameter*)getBankParameterForUser:(User*)user
{
	return [controller getBankParameterForUser:user ];
}


-(NSString*)bankNameForCode:(NSString*)bankCode inCountry:(NSString*)country
{
	return [controller bankNameForCode:bankCode inCountry:country ];
}

-(NSString*)bankNameForBIC:(NSString*)bic inCountry:(NSString*)country
{
	return [controller bankNameForBIC:bic inCountry:country ];
}

-(PecuniaError*)addAccount: (BankAccount*)account forUser: (User*)user
{
	return [controller addAccount:account forUser:user ];
}

-(PecuniaError*)changeAccount:(BankAccount*)account
{
	return [controller changeAccount:account ];
}

-(PecuniaError*)setAccounts:(NSArray*)bankAccounts
{
	return [controller setAccounts:bankAccounts ];
}

-(BOOL)isTransferSupported:(TransferType)tt forAccount:(BankAccount*)account
{
	return [controller isTransferSupported: tt forAccount: account ];
}

-(BOOL)isStandingOrderSupportedForAccount:(BankAccount*)account
{
	return [controller isStandingOrderSupportedForAccount:account ];
}


-(NSArray*)allowedCountriesForAccount:(BankAccount*)account
{
	return [controller allowedCountriesForAccount:account ];
}

-(NSDictionary*)countries
{
	return [controller countries ];
}

-(TransactionLimits*)limitsForType:(TransferType)tt account:(BankAccount*)account country:(NSString*)ctry
{
	return [controller limitsForType:tt account:account country:ctry ];
}

-(TransactionLimits*)standingOrderLimitsForAccount:(BankAccount*)account action:(StandingOrderAction)action
{
	return [controller standingOrderLimitsForAccount:account action:action ];
}

+(HBCIClient*)hbciClient
{
	if(client == nil) client = [[HBCIClient alloc ] init ];
	return client;
}

-(void)getStatements:(NSArray*)resultList
{
	[controller getStatements:resultList ];
	// get statements in separate thread
//	[bridge performSelector:@selector(statementsForAccounts:) onThread:[WorkerThread thread ] withObject:resultList waitUntilDone:NO ];
//	[bridge statementsForAccounts:resultList ];
}

-(void)getStandingOrders:(NSArray*)resultList
{
	[controller getStandingOrders:resultList ];
}

-(PecuniaError*)sendStandingOrders:(NSArray*)orders
{
	return [controller sendStandingOrders:orders ];
}


-(BOOL)sendTransfers:(NSArray*)transfers
{
	return [controller sendTransfers:transfers ];
}

-(BOOL)checkAccount: (NSString*)accountNumber forBank: (NSString*)bankCode inCountry: (NSString*)country
{
	return [controller checkAccount:accountNumber forBank:bankCode inCountry:country ];
}

-(BOOL)checkIBAN: (NSString*)iban
{
	return [controller checkIBAN:iban ];
}

-(PecuniaError*)changePinTanMethodForUser:(User*)user
{
	return [controller changePinTanMethodForUser:user ];
}

-(NSArray*)users
{
	return [controller users ];
}

-(PecuniaError*)addBankUser:(User*)user
{
	return [controller addBankUser: user ];
}

-(BOOL)deleteBankUser:(User*)user
{
	return [controller deleteBankUser: user ];
}

-(PecuniaError*)updateBankDataForUser:(User*)user
{
	return [controller updateBankDataForUser:user ];
}

-(PecuniaError*)setLogLevel:(LogLevel)level
{
	return [controller setLogLevel:level ];
}

-(NSArray*)getAccountsForUser:(User*)user
{
	return [controller getAccountsForUser: user ];
}

-(PecuniaError*)sendCustomerMessage:(CustomerMessage*)msg
{
    return [controller sendCustomerMessage:msg ];
}

- (NSArray*)getSupportedBusinessTransactions: (BankAccount*)account
{
    return [controller getSupportedBusinessTransactions: account];
}

-(BOOL)checkDTAUS:(NSString*)s
{
    NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜabcdefghijklmnopqrstuvwxyzäöüß 0123456789.,&-/+*$%" ];
    
    if (s == nil || [s length ] == 0) return YES;
    
    for (NSUInteger i = 0; i < [s length]; i++) {
        if ([cs characterIsMember:[s characterAtIndex:i ] ] == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP170", @""), 
                            NSLocalizedString(@"AP171", @""), 
                            NSLocalizedString(@"ok", @"Ok"), 
                            nil,
                            nil,
                            [s characterAtIndex:i ]);
            return NO;
        }
    }
    return YES;    
}


@end
