//
//  BankAccount.m
//  Pecunia
//
//  Created by Frank Emminghaus on 01.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//
#import "BankAccount.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "BankQueryResult.h"
#import "ShortDate.h"
#import "StandingOrder.h"
#import "PurposeSplitRule.h"

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
@dynamic collTransfer;
@dynamic isManual;
@dynamic splitRule;
@dynamic isStandingOrderSupported;
@dynamic accountSuffix;

-(id)copyWithZone: (NSZone *)zone
{
	return [self retain ];
}

-(void)evaluateQueryResult: (BankQueryResult*)res
{
	NSError *error = nil;
	BankStatement *stat;
	ShortDate *lastTransferDate;
	
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];

	// unmark old items
	NSArray *statements = [[self mutableSetValueForKey: @"statements"] allObjects ];
	for(stat in statements) if(stat.isNew == YES) stat.isNew = NO;
	
	// look for new statements and mark them
	// in Import case evaluate all statements
	if (self.latestTransferDate && res.isImport == NO) {
		lastTransferDate = [ShortDate dateWithDate:self.latestTransferDate ];
	} else {
		lastTransferDate = [ShortDate dateWithDate: [NSDate distantPast ] ];	
	}
	
	// check if purpose split rule exists
	if (self.splitRule && purposeSplitRule == nil ) purposeSplitRule = [[PurposeSplitRule alloc ] initWithString:self.splitRule ];
 
	ShortDate *currentDate = nil;
	for (stat in res.statements) {
		NSArray *oldStatements;

		//first, check if date < lDate
		if([[stat date ] compare: [lastTransferDate lowDate ] ] == NSOrderedAscending) continue;

		// Apply purpose split rule, if exists
		if (purposeSplitRule) [purposeSplitRule applyToStatement:stat ];
		
		ShortDate *statDate = [ShortDate dateWithDate: [stat date] ];

		// Get the list of old statements for the date of the new stat.
		if (currentDate == nil || [statDate compare: currentDate] != NSOrderedSame ) {
			currentDate = statDate;
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@) AND (date <= %@)", self, [currentDate lowDate], [currentDate highDate ]];
			[request setPredicate:predicate];
			oldStatements = [context executeFetchRequest:request error:&error];
		}
		
		
		// check if stat matches existing statement		
		BankStatement *oldStat;
		BOOL isMatched = NO;
		for (oldStat in oldStatements) {
			if([stat matches: oldStat ]) {
				isMatched = YES;
				// update (reordered) statements at latestTransferDate
//				oldStat.date = stat.date;
//				oldStat.saldo = stat.saldo;
				break;
			}
		}
		if(isMatched == NO) stat.isNew = YES; else stat.isNew = NO;
	}
}

-(void)updateStandingOrders:(NSArray*)orders
{
	NSError *error = nil;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	StandingOrder *stord;
	StandingOrder *order;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"StandingOrder" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	
	
	for(stord in orders) {
		// find existing order
		NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (orderKey = %@)", self, stord.orderKey ];
		[request setPredicate:predicate];
		NSArray *res = [context executeFetchRequest:request error:&error];
		if (res && [res count ] > 0) {
			order = [res objectAtIndex:0 ];
		} else {
			// order does not yet exist
			order = [NSEntityDescription insertNewObjectForEntityForName:@"StandingOrder" inManagedObjectContext:context];
		}
		// now copy order to real context
		NSEntityDescription *entity = [stord entity];
		NSArray *attributeKeys = [[entity attributesByName] allKeys];
		NSDictionary *attributeValues = [stord dictionaryWithValuesForKeys:attributeKeys];
		[order setValuesForKeysWithDictionary:attributeValues];
		order.account = self;
	}
	
}

-(int)updateFromQueryResult: (BankQueryResult*)result
{
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	BankStatement	*stat;
	NSDate			*ltd = self.latestTransferDate;
	NSDate			*date = nil;
	NSTimeInterval  ofs = 1;
	NSTimeInterval  ltdOfs = 1;
	int             count = 0, j;
	ShortDate		*lastTransferDate;
	NSMutableArray	*newStatements = [NSMutableArray arrayWithCapacity:50 ];
	
	if (self.latestTransferDate) {
		lastTransferDate = [ShortDate dateWithDate:self.latestTransferDate ];
	} else {
		lastTransferDate = [ShortDate dateWithDate: [NSDate distantPast ] ];	
	}

	if(result.balance) self.balance = result.balance;
	if(result.statements == nil) return 0;
	
	// statements must be properly sorted !!!
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
		
		// adjust date to ensure proper ordering
		if ([lastTransferDate isEqual:[ShortDate dateWithDate:stat.date ] ]) {
			stmt.date = [[NSDate alloc ] initWithTimeInterval: ltdOfs++ sinceDate: self.latestTransferDate ];
		} else {
			if (date == nil) date = stat.date;
			else {
				if ([date isEqualToDate:stat.date ]) {
					stmt.date = [[NSDate alloc ] initWithTimeInterval:ofs++ sinceDate: date ];
				} else {
					date = stat.date;
					ofs=1;
				}
			}
		}
		
		// if no balance was given, addforward it
		if (result.balance == nil) {
			stmt.saldo = [self.balance decimalNumberByAdding:stmt.value ];
			self.balance = stmt.saldo;
		}

		[newStatements addObject: stmt ];
		[stmt addToAccount: self ];	
		count++;
		if(ltd == nil || [ltd compare: stmt.date ] == NSOrderedAscending) ltd = stmt.date;
	}
	
	// if balance was given, subbackward it
	if (result.balance) {
		NSDecimalNumber *bal = self.balance;
		for(j = [newStatements count ]-1; j>=0; j--) {
			stat = [newStatements objectAtIndex:j ];
			stat.saldo = bal;
			bal = [bal decimalNumberBySubtracting:stat.value ];
		}
	}
	
	self.latestTransferDate = ltd;
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
	[purposeSplitRule release ];
	[super dealloc ];
}

@end
