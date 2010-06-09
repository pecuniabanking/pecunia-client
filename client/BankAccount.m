//
//  BankAccount.m
//  MacBanking
//
//  Created by Frank Emminghaus on 01.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//
#import "BankAccount.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "BankQueryResult.h"
#import "ShortDate.h"


@implementation BankAccount

@dynamic latestTransferDate;
@dynamic country;
@dynamic bankName;
@dynamic bankCode;
@dynamic bic;
@dynamic iban;
@dynamic userId;
@dynamic customerId;
//@dynamic accountNumber;
@dynamic owner;
@dynamic uid;
@dynamic type;
@dynamic balance;
@dynamic noAutomaticQuery;

-(id)copyWithZone: (NSZone *)zone
{
	return [self retain ];
}

-(void)evaluateStatements: (NSArray*)stats
{
	NSError *error = nil;
	BankStatement *stat;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];

	// unmark old items
	NSArray *statements = [[self mutableSetValueForKey: @"statements"] allObjects ];
	for(stat in statements) if(stat.isNew == YES) stat.isNew = NO;
	
	// look for new statements and mark them
	NSDate *lDate = self.latestTransferDate;
	if(lDate == nil) {
		lDate = [NSDate distantPast ];
	} 
 
	// get (old) reference statements
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@)", self, lDate ];
	[request setPredicate:predicate];
	statements = [context executeFetchRequest:request error:&error];
	for (stat in stats) {
		// check if stat matches existing statements
		//first, check if date < lDate
		if([[stat date ] compare: lDate ] == NSOrderedAscending) continue;
		BankStatement *oldStat;
		BOOL isMatched = NO;
		for (oldStat in statements) {
			if([stat matches: oldStat ]) {
				isMatched = YES;
				// update (reordered) statements at latestTransferDate
				oldStat.date = stat.date;
				oldStat.saldo = stat.saldo;
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

	if(result.balance) self.balance = result.balance;
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
		count++;
		if(ltd == nil || [ltd compare: stmt.date ] == NSOrderedAscending) ltd = stmt.date;
	}
	self.latestTransferDate = [[ShortDate dateWithDate: ltd ] lowDate ];
	return count;
}


+(BankAccount*)bankRootForCode:(NSString*)bankCode
{
	BOOL	found = NO;
	NSError *error = nil;
	
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
	
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"bankNodes"];
	NSArray *nodes = [context executeFetchRequest:request error:&error];
	if( error != nil || nodes == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	
	BankAccount *bankNode;
	for(bankNode in nodes) {
		if( [[bankNode valueForKey: @"bankCode" ] isEqual: bankCode ]) {
			found = YES;
			break;
		}
	}
	if(found) return bankNode; else return nil;
}

-(void)setAccountNumber:(NSString*)n
{
	[self willAccessValueForKey:@"accountNumber"];
    [self setPrimitiveValue: n forKey: @"accountNumber"];
    [self didAccessValueForKey:@"accountNumber"];
}

-(NSString*)accountNumber
{
	[self willAccessValueForKey:@"accountNumber"];
    NSString *n = [self primitiveValueForKey: @"accountNumber"];
    [self didAccessValueForKey:@"accountNumber"];
	return n;
}

-(NSDate*)nextDateForDate:(NSDate*)date
{
	NSError *error = nil;
	NSDate *startDate = [[ShortDate dateWithDate:date ] lowDate ];
	NSDate *endDate = [[ShortDate dateWithDate:date ] highDate ];
	NSDate *currentDate;
	
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@) AND (date < %@)", self, startDate, endDate ];
	[request setPredicate:predicate];
	
	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[request setSortDescriptors:sds ];

	NSArray *statements = [context executeFetchRequest:request error:&error];
	if (statements == nil || [statements count ] == 0) return startDate;
	
	currentDate = [[statements objectAtIndex:0 ] date ];
	return [[NSDate alloc ] initWithTimeInterval:100 sinceDate:currentDate ];
}


-(void)dealloc
{
	[super dealloc ];
}

@end
