//
//  HBCIClient.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HBCIBridge;
@class BankInfo;
@class Passport;
@class PecuniaError;
@class BankAccount;
@class Account;

@interface HBCIClient : NSObject {
	HBCIBridge		*bridge;
	
	NSMutableArray		*passports;
	NSMutableArray		*accounts;
	NSMutableDictionary	*bankInfo;
	NSMutableDictionary *countryInfos;
	NSArray				*bankQueryResults;
	int					currentQuery;
	id					asyncCommandSender;
}

-(Passport*)passportForBankCode:(NSString*)bankCode;
-(void)readCountryInfos;
-(NSDictionary*)countryInfos;


-(NSArray*)initHBCI;
-(NSArray*)passports;
-(NSArray*)accounts;

-(Account*)accountWithNumber:(NSString*)number bankCode:(NSString*)code;

// HBCI Methods
-(BankInfo*)infoForBankCode: (NSString*)bankCode error:(PecuniaError**)error;
-(BOOL)addPassport:(Passport*)passport error:(PecuniaError**)error;
-(NSArray*)getAccountsForPassport:(Passport*)pp error:(PecuniaError**)error;
-(void)setAccounts:(NSArray*)bankAccounts;
-(NSString*)bankNameForCode:(NSString*)bankCode;
-(void)deletePassport:(Passport*)pp error:(PecuniaError**)error;
-(void)getStatements:(NSArray*)resultList sender:(id)sender;
-(NSDictionary*)getRestrictionsForJob:(NSString*)jobname account:(BankAccount*)account;
-(BOOL)checkAccount:(NSString*)accountNumber bankCode:(NSString*)bankCode error:(PecuniaError**)error;
-(BOOL)checkIBAN:(NSString*)iban error:(PecuniaError**)error;
-(void)asyncCommandCompletedWithResult:(id)result error:(PecuniaError*)err;
-(BOOL)isJobSupported:(NSString*)jobName forAccount:(BankAccount*)account;
-(BOOL)sendTransfers:(NSArray*)transfers error:(PecuniaError**)err;


+(HBCIClient*)hbciClient;

@end
