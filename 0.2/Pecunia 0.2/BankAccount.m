//
//  BankAccount.m
//  MacBanking
//
//  Created by Frank Emminghaus on 01.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//
#import "BankAccount.h"
#import "BankStatement.h"
#import "ABAccount.h"
#import "ABController.h"
#import "MOAssistant.h"
#import "BankQueryResult.h"
#include <aqhbci/account.h>


@implementation BankAccount

@dynamic latestTransferDate;
@dynamic country;
@dynamic bankName;
@dynamic bankCode;
//@dynamic accountNumber;
@dynamic owner;
@dynamic uid;
@dynamic type;
@dynamic balance;

-(id)copyWithZone: (NSZone *)zone
{
	return [self retain ];
}

-(BOOL)collTransfer
{
	ABAccount* abAccount = [[ABController abController ] accountByNumber: [self accountNumber ] 
																bankCode: [self bankCode ] ];
	if(abAccount == nil) return TRUE;
	uint32_t flags = [abAccount flags ];
	return (flags ^ AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER);
}

-(void)setCollTransfer: (BOOL)coll
{
	ABAccount* abAccount = [[ABController abController ] accountByNumber: self.accountNumber 
																bankCode: self.bankCode ];
	uint32_t flags;
	if(coll) flags = 0; else flags = AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER;
	[abAccount setFlags: flags ];
}

-(void)evaluateStatements: (NSArray*)stats onlyLatest:(BOOL)onlyLatest
{
	NSError *error = nil;
	NSDate *lDate = nil;
	BankStatement *stat;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];

	// unmark old items
	NSArray *statements = [[self mutableSetValueForKey: @"statements"] allObjects ];
	for(stat in statements) if(stat.isNew == YES) stat.isNew = NO;
	
	// look for new statements and mark them
	if (onlyLatest == YES) {
		lDate = self.latestTransferDate;
	}
	if(lDate == nil) {
		lDate = [NSDate distantPast ];
	} else {
		// go back one week
		lDate = [[NSDate alloc ] initWithTimeInterval: -604800 sinceDate: lDate ];
	}
	
	// Find duplicates for new items.
	NSDate* currentDate = [NSDate distantPast];
	for (stat in stats) {
		NSArray *oldStatements;
		
		//first, check if valutaDate < lDate
		if([[stat valutaDate ] compare: lDate ] != NSOrderedDescending) continue;

		// Get the list of old statements for the date of the new stat.
		if ( ! [[stat valutaDate] isEqualToDate: currentDate] ) {
			currentDate = [stat valutaDate];
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(%@ IN categories) AND (valutaDate == %@)", self, currentDate];
			[request setPredicate:predicate];
			oldStatements = [context executeFetchRequest:request error:&error];
		}
		
		BankStatement *oldStat;
		BOOL isMatched = NO;
		for (oldStat in oldStatements) {
			if([stat matches: oldStat]) {
				isMatched = YES;
				break;
			}
		}
		
		if(isMatched == NO) stat.isNew = YES; else stat.isNew = NO;
	}
}

-(int)updateFromQueryResult: (BankQueryResult*)result
{
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	BankStatement	*stat;
	NSDate			*ltd = self.latestTransferDate;
	int             count = 0;
	BOOL			calcBalance = NO;

	if(result.balance) self.balance = result.balance;
	else calcBalance = YES;
	if(result.statements == nil) return 0;
	for (stat in result.statements) {
		if(stat.isNew == NO) continue;

		// now copy statement
		NSEntityDescription *entity = [stat entity];
		NSArray *attributeKeys = [[entity attributesByName] allKeys];
		NSDictionary *attributeValues = [stat dictionaryWithValuesForKeys:attributeKeys];
		
		BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement"
															inManagedObjectContext:context];

		[stmt setValuesForKeysWithDictionary:attributeValues];
		stmt.isNew = YES;
		[stmt addToAccount: self ];
		
		// calculate new balance if none is given
		if (calcBalance) {
			self.balance = [self.balance decimalNumberByAdding:stmt.value ];
		}
		
		count++;
		if(ltd == nil || [ltd compare: stmt.valutaDate ] == NSOrderedAscending) ltd = stmt.valutaDate;
	}
	self.latestTransferDate = ltd;
	return count;
}


-(ABAccount*)abAccount
{
	return [[ABController abController ] accountByNumber: self.accountNumber bankCode: self.bankCode ];
}

-(void)updateChanges
{
	ABAccount *abAcc = [self abAccount ];
	
	self.name = [abAcc  name ];
	self.owner = [abAcc  ownerName ];
/*	
	[self willAccessValueForKey:@"name"];
    [self setPrimitiveValue: [abAcc  name ] forKey: @"name"];
    [self didAccessValueForKey:@"name"];
	
	[self willAccessValueForKey:@"owner"];
    [self setPrimitiveValue: [abAcc  ownerName ] forKey: @"owner"];
    [self didAccessValueForKey:@"owner"];
*/ 
}

-(NSString*)accountNumber
{
	[self willAccessValueForKey:@"accountNumber"];
    NSString *n = [self primitiveValueForKey: @"accountNumber"];
    [self didAccessValueForKey:@"accountNumber"];
	return n;
}

-(void)setAccountNumber:(NSString*)n
{
	[self willAccessValueForKey:@"accountNumber"];
    [self setPrimitiveValue: n forKey: @"accountNumber"];
    [self didAccessValueForKey:@"accountNumber"];
}

+(BankAccount*)accountWithNumber:(NSString*)number bankCode:(NSString*)code
{
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel *model = [[MOAssistant assistant ] model ];
	
	NSError *error = nil;
	NSDictionary *subst = [NSDictionary dictionaryWithObjectsAndKeys: number, @"ACCNT", code, @"BCODE", nil];
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"bankAccountByID" substitutionVariables:subst];
	NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
	if( error != nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	if(results == nil || [results count ] != 1) return nil;
	return [results objectAtIndex: 0 ];
}



-(void)dealloc
{
	[super dealloc ];
}

@end
