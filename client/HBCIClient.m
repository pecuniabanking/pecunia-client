//
//  HBCIClient.m
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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

static HBCIClient *client = nil;

@implementation HBCIClient

-(id)init
{
	self = [super init ];
	if(self == nil) return nil;
	
	bridge = [[HBCIBridge alloc ] initWithClient: self ];
	[bridge startup ];
	passports = [[NSMutableArray alloc ] initWithCapacity: 10 ];
	accounts = [[NSMutableArray alloc ] initWithCapacity: 10 ];
	bankInfo = [[NSMutableDictionary alloc ] initWithCapacity: 10];
	countryInfos = [[NSMutableDictionary alloc ] initWithCapacity: 50];
	[self readCountryInfos ];
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

-(Passport*)passportForBankCode:(NSString*)bankCode
{
	Passport *result;
	for(result in passports) if([bankCode isEqualToString: result.bankCode ]) return result;
	return nil;	
}

-(void)appendTag:(NSString*)tag withValue:(NSString*)val to:(NSMutableString*)cmd
{
	if(val) [cmd appendFormat:@"<%@>%@</%@>", tag, val, tag ];
}

-(NSArray*)initHBCI
{
	PecuniaError *error=nil;
	NSString *ppDir = [[MOAssistant assistant] passportDirectory ];
	NSString *cmd = [NSString stringWithFormat: @"<command name=\"init\"><path>%@</path></command>", ppDir ];
	NSArray *pps = [bridge syncCommand: cmd error: &error ];
	if(pps == nil) {
		//  check for error (wrong password)
		if(error) {
			[error alertPanel ];
			[NSApp terminate:self ];
		}
	} else [passports addObjectsFromArray: pps ];
	
	// load all availabe accounts
	for(Passport *pp in passports) {
		NSArray *accs = [self getAccountsForPassport: pp error:&error ];
		if(error) {
			[error alertPanel ];
			[NSApp terminate:self ];
		} else {
			[accounts addObjectsFromArray: accs ];
		}
	}
	return passports;
}

-(BankInfo*)infoForBankCode: (NSString*)bankCode error:(PecuniaError**)error
{
	BankInfo *info = [bankInfo objectForKey: bankCode ];
	if(info == nil) {
		NSString *cmd = [NSString stringWithFormat: @"<command name=\"getBankInfo\"><bankCode>%@</bankCode></command>", bankCode ];
		info = [bridge syncCommand: cmd error: error ];
		if(*error == nil) [bankInfo setObject: info forKey: bankCode ]; else return nil;
	}
	return info;
}

-(NSString*)bankNameForCode:(NSString*)bankCode
{
	PecuniaError *error=nil;
	BankInfo *info = [self infoForBankCode: bankCode error:&error ];
	if(error || info==nil || info.name == nil) return NSLocalizedString(@"unknown",@"- unknown -");
	return info.name;
}

-(NSDictionary*)getRestrictionsForJob:(NSString*)jobname account:(BankAccount*)account
{
	NSDictionary *result;
	PecuniaError *error=nil;
	if(account == nil) return nil;
	NSMutableString *cmd = [[NSMutableString alloc ] initWithString: @"<command name=\"getJobRestrictions\">" ];
	[self appendTag: @"bankCode" withValue: account.bankCode to: cmd ];
	[self appendTag: @"userId" withValue: account.userId to: cmd ];
	[self appendTag: @"jobName" withValue: jobname to: cmd ];
	[cmd appendString: @"</command>" ];
	result = [bridge syncCommand: cmd error: &error ];
	return result;
}

-(BOOL)isJobSupported:(NSString*)jobName forAccount:(BankAccount*)account
{
	PecuniaError *error=nil;
	if(account == nil) return NO;
	NSMutableString *cmd = [[NSMutableString alloc ] initWithString: @"<command name=\"isJobSupported\">" ];
	[self appendTag: @"bankCode" withValue: account.bankCode to: cmd ];
	[self appendTag: @"userId" withValue: account.userId to: cmd ];
	[self appendTag: @"jobName" withValue: jobName to: cmd ];
	[self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd ];
	[cmd appendString: @"</command>" ];
	NSNumber *result = [bridge syncCommand: cmd error: &error ];
	if(result) return [result boolValue ]; else return NO;
}



+(HBCIClient*)hbciClient
{
	if(client == nil) client = [[HBCIClient alloc ] init ];
	return client;
}

-(NSArray*)passports
{
	return passports;
}

-(NSArray*)accounts
{
	return accounts;
}



-(NSArray*)getAccountsForPassport:(Passport*)pp error:(PecuniaError**)error
{
	NSString *cmd = [NSString stringWithFormat: @"<command name=\"getAccounts\"><bankCode>%@</bankCode><userId>%@</userId></command>", pp.bankCode, pp.userId ];
	NSArray *accs = [bridge syncCommand: cmd error:error ];
	return accs;
}

-(void)setAccounts:(NSArray*)bankAccounts
{
	PecuniaError	*error = nil;
	
	BankAccount	*acc;
	for(acc in bankAccounts) {
		NSMutableString	*cmd = [[NSMutableString alloc ] initWithString: @"<command name=\"setAccount\">" ];
		[self appendTag: @"bankCode" withValue: acc.bankCode to: cmd ];
		[self appendTag: @"accountNumber" withValue: acc.accountNumber to: cmd ];
		[self appendTag: @"country" withValue: [acc.country uppercaseString] to: cmd ];
		[self appendTag: @"iban" withValue: acc.iban to: cmd ];
		[self appendTag: @"bic" withValue: acc.bic to: cmd ];
		[self appendTag: @"ownerName" withValue: acc.owner to: cmd ];
		[self appendTag: @"name" withValue: acc.owner to: cmd ];
		[self appendTag: @"customerId" withValue: acc.customerId to: cmd ];
		[self appendTag: @"userId" withValue: acc.userId to: cmd ];
		[self appendTag: @"customerId" withValue: acc.customerId to: cmd ];
		[self appendTag: @"currency" withValue: acc.currency to: cmd ];
		[cmd appendString: @"</command>" ];
		[bridge syncCommand: cmd error: &error ];
		[cmd release ];
		if(error != nil) return;
	}
}

-(BOOL)addPassport:(Passport*)passport error:(PecuniaError**)error
{
	NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"addPassport\">" ];
	[self appendTag: @"bankCode" withValue: passport.bankCode to: cmd ];
	[self appendTag: @"customerId" withValue: passport.customerId to: cmd ];
	[self appendTag: @"userId" withValue: passport.userId to: cmd ];
	[self appendTag: @"host" withValue: [passport.host stringByReplacingOccurrencesOfString: @"https://" withString:@"" ] to: cmd ];
	[self appendTag: @"version" withValue: passport.version to: cmd ];
	[self appendTag: @"port" withValue: @"443" to: cmd ];
	if(passport.base64) [self appendTag: @"filter" withValue: @"Base64" to: cmd ];
	[self appendTag: @"bankCode" withValue: passport.bankCode to: cmd ];
	[cmd appendString: @"</command>" ];

	Passport* pp = [bridge syncCommand: cmd error: error ];
	if(pp == nil || *error) return NO;
	[passports addObject: pp ];
	
	NSArray* accs = [self getAccountsForPassport: passport error:error ];
	if(*error) return NO;
	
	// delete any previously existing passport first
	[passports removeObject: pp ];
	[passports addObject: pp ];
	// delete any previously existing account first
	[accounts removeObjectsInArray: accs ];
	[accounts addObjectsFromArray: accs ];
	
	return YES;
}

-(void)deletePassport:(Passport*)pp error:(PecuniaError**)error
{
	NSString *cmd = [NSString stringWithFormat: @"<command name=\"deletePassport\"><bankCode>%@</bankCode><userId>%@</userId></command>", pp.bankCode, pp.userId ];
	[bridge syncCommand: cmd error:error ];
	if(*error == nil) {
		NSMutableArray *newAccounts = [NSMutableArray arrayWithCapacity: [accounts count ] ];
		// remove accounts first
		for(Account *acc in accounts) {
			if(![acc.bankCode isEqualToString: pp.bankCode ] || ![acc.customerId isEqualToString: pp.customerId ]) [newAccounts addObject: acc ];
		}
		[accounts setArray: newAccounts ];
		[passports removeObject: pp ];
	}
}

-(void)getStatements:(NSArray*)resultList sender:(id)sender
{
	bankQueryResults = [resultList retain ];
	NSMutableString	*cmd = [[NSMutableString alloc ] init ];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO] autorelease];
	NSString		*fromString;
	
	BankQueryResult *result;
	[cmd setString: @"<command name=\"getAllStatements\"><accinfolist type=\"list\">" ];
	for(result in resultList) {
		if (result.account.latestTransferDate == nil) fromString=@"2000-01-01";
		else fromString = [dateFormatter stringFromDate:result.account.latestTransferDate];
		[cmd appendFormat:@"<accinfo><bankCode>%@</bankCode><accountNumber>%@</accountNumber>", result.bankCode, result.accountNumber ];
		[cmd appendFormat:@"<userId>%@</userId><fromDate>%@</fromDate></accinfo>", result.userId, fromString ];
	}
	[cmd appendString:@"</accinfolist></command>" ];
	asyncCommandSender = sender;
	[bridge asyncCommand: cmd sender: self ];
	[cmd release ];
}

-(void)asyncCommandCompletedWithResult:(id)result error:(PecuniaError*)err
{
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
}

-(BOOL)sendTransfers:(NSArray*)transfers error:(PecuniaError**)err
{
	Transfer *transfer;
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO] autorelease];
	NSMutableString *cmd = [[NSMutableString alloc ] initWithString: @"<command name=\"sendTransfers\"><transfers type=\"list\">" ];
	NSString *type;
	for(transfer in transfers) {
		[cmd appendString: @"<transfer>" ];
		[self appendTag: @"bankCode" withValue: transfer.account.bankCode to: cmd ];
		[self appendTag: @"accountNumber" withValue: transfer.account.accountNumber to: cmd ];
		[self appendTag: @"customerId" withValue: transfer.account.customerId to: cmd ];
		[self appendTag: @"userId" withValue: transfer.account.userId to: cmd ];
		[self appendTag: @"remoteAccount" withValue: transfer.remoteAccount to: cmd ];
		[self appendTag: @"remoteBankCode" withValue: transfer.remoteBankCode to: cmd ];
		[self appendTag: @"remoteName" withValue: transfer.remoteName to: cmd ];
		[self appendTag: @"purpose1" withValue: transfer.purpose1 to: cmd ];
		[self appendTag: @"purpose2" withValue: transfer.purpose2 to: cmd ];
		[self appendTag: @"purpose3" withValue: transfer.purpose3 to: cmd ];
		[self appendTag: @"purpose4" withValue: transfer.purpose4 to: cmd ];
		[self appendTag: @"currency" withValue: transfer.currency to: cmd ];
		[self appendTag: @"remoteBIC" withValue: transfer.remoteBIC to: cmd ];
		[self appendTag: @"remoteIBAN" withValue: transfer.remoteIBAN to: cmd ];
		[self appendTag: @"remoteCountry" withValue: transfer.remoteCountry==nil?@"DE":transfer.remoteCountry to: cmd ];
		if([transfer.type intValue] == TransferTypeDated) {
			NSString *fromString = [dateFormatter stringFromDate:transfer.valutaDate ];
			[self appendTag: @"valutaDate" withValue: fromString to: cmd ];
		}
		TransferType tt = [transfer.type intValue];
		switch(tt) {
			case TransferTypeLocal: type = @"standard"; break;
			case TransferTypeDated: type = @"dated"; break;
			case TransferTypeInternal: type = @"internal"; break;
			case TransferTypeEU:	
				type = @"foreign";
				[self appendTag:@"chargeTo" withValue:[transfer.chargedBy description ]  to:cmd ];
				break;
		}
		
		[self appendTag: @"type" withValue: type to: cmd ];
		NSDecimalNumber *val = [transfer.value decimalNumberByMultiplyingByPowerOf10:2 ];
		[self appendTag: @"value" withValue: [val stringValue ] to: cmd ];
		
		NSURL *uri = [[transfer objectID] URIRepresentation];
		[self appendTag: @"transferId" withValue: [uri absoluteString ] to: cmd ];
		[cmd appendString: @"</transfer>" ];
	}
	[cmd appendString: @"</transfers></command>" ];
	
	NSArray *resultList = [bridge syncCommand: cmd error: err ];
	TransferResult	*result;
	BOOL allSent = YES;
	for(result in resultList) {
		NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
		NSURL *uri = [NSURL URLWithString:result.transferId ];
		NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
		Transfer *transfer = (Transfer*)[context objectWithID: moID];
		transfer.isSent = [NSNumber numberWithBool: result.isOk ];
		if(transfer.isSent == NO) allSent = NO;
	}
	return allSent;
}

-(BOOL)checkAccount:(NSString*)accountNumber bankCode:(NSString*)bankCode error:(PecuniaError**)error
{
	if(bankCode == nil || accountNumber == nil) return YES;
	NSString *cmd = [NSString stringWithFormat: @"<command name=\"checkAccount\"><bankCode>%@</bankCode><accountNumber>%@</accountNumber></command>", bankCode, accountNumber ];
	NSNumber *result = [bridge syncCommand: cmd error: error ];
	if(result) return [result boolValue ]; else return NO;
}

-(BOOL)checkIBAN:(NSString*)iban error:(PecuniaError**)error
{
	if(iban == nil) return YES;
	NSString *cmd = [NSString stringWithFormat: @"<command name=\"checkAccount\"><iban>%@</iban></command>", iban ];
	NSNumber *result = [bridge syncCommand: cmd error: error ];
	if(result) return [result boolValue ]; else return NO;
}

@end
