/**
 * Copyright (c) 2007, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "BankAccount.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "BankQueryResult.h"
#import "ShortDate.h"
#import "StandingOrder.h"
#import "PurposeSplitRule.h"
#import "PurposeSplitController.h"

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

@synthesize dbStatements;
@synthesize purposeSplitRule;
@synthesize unread;

-(id)copyWithZone: (NSZone *)zone
{
	return [self retain ];
}

-(NSInteger)calcUnread
{
	NSError *error = nil;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (isNew = 1)", self ];
	[request setPredicate:predicate];
	NSArray *statements = [context executeFetchRequest:request error:&error];
	return unread = [statements count ];
}

-(NSDictionary*)statementsByDay:(NSArray*)stats
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:10 ];
	
	for(BankStatement *stat in stats) {
		ShortDate *date = [ShortDate dateWithDate:stat.date ];
		NSMutableArray *dayStats = [result objectForKey:date ];
		if (dayStats == nil) {
			dayStats = [NSMutableArray arrayWithCapacity:10 ];
			[result setObject:dayStats forKey:date ];
		}
		[dayStats addObject:stat ];
	}
	return result;
}

-(void)evaluateQueryResult: (BankQueryResult*)res
{
	NSError *error = nil;
	BankStatement *stat;
//	ShortDate *lastTransferDate;
	
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	
	// check if purpose split rule exists
	if (self.splitRule && self.purposeSplitRule == nil ) {
        self.purposeSplitRule = [[[PurposeSplitRule alloc] initWithString: self.splitRule] autorelease];
    }

	// get old statements
	if ([res.statements count] == 0) return;
	stat = [res.statements objectAtIndex:0]; // oldest statement
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@)", self, [[ShortDate dateWithDate:stat.date ] lowDate]];
	[request setPredicate:predicate];
	self.dbStatements = [context executeFetchRequest:request error:&error];

	// rearrange statements by day
	NSDictionary *oldDayStats = [self statementsByDay:self.dbStatements ];
	NSDictionary *newDayStats = [self statementsByDay:res.statements ];
	
	// compare by day
	NSArray *dates = [newDayStats allKeys ];
	for(ShortDate *date in dates) {
		NSMutableArray *oldStats = [oldDayStats objectForKey:date ];
		NSMutableArray *newStats = [newDayStats objectForKey:date ];
		
		//repair mode...
//		if ([oldStats count ] == [newStats count ]) continue;
		for(stat in newStats) {
			// Apply purpose split rule, if exists
			if (self.purposeSplitRule) [self.purposeSplitRule applyToStatement:stat ];
			if (oldStats == nil) {
				stat.isNew = [NSNumber numberWithBool:YES ];
				continue;
			} else {
				// find statement in old statements
				BOOL isMatched = NO;
				for (NSUInteger idx = 0; idx < [oldStats count ]; idx++) {
					BankStatement *oldStat = [oldStats objectAtIndex:idx ];
					if([stat matchesAndRepair: oldStat ]) {
						isMatched = YES;
						[oldStats removeObjectAtIndex:idx ];
						break;
					}				
				}
				if(isMatched == NO) stat.isNew = [NSNumber numberWithBool:YES ]; else stat.isNew = [NSNumber numberWithBool:NO ];
			}
		}
	}
	
	
/*	
	
	// look for new statements and mark them
	// in Import case evaluate all statements
	if (self.latestTransferDate && res.isImport == NO) {
		lastTransferDate = [ShortDate dateWithDate:self.latestTransferDate ];
	} else {
		lastTransferDate = [ShortDate dateWithDate: [NSDate distantPast ] ];	
	}
	
	// check if purpose split rule exists
	if (self.splitRule && self.purposeSplitRule == nil ) self.purposeSplitRule = [[PurposeSplitRule alloc ] initWithString:self.splitRule ];
 
	ShortDate *currentDate = nil;
	for (stat in res.statements) {
		NSArray *oldStatements;

		//first, check if date < lDate
		if([[stat date ] compare: [lastTransferDate lowDate ] ] == NSOrderedAscending) continue;

		// Apply purpose split rule, if exists
		if (self.purposeSplitRule) [self.purposeSplitRule applyToStatement:stat ];
		
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
		if(isMatched == NO) stat.isNew = [NSNumber numberWithBool:YES ]; else stat.isNew = [NSNumber numberWithBool:NO ];
	}
 
*/ 
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
        
        if (order.lastExecDate == nil) {
            order.lastExecDate = [[ShortDate dateWithYear:2999 month:12 day:31 ] lowDate ];
        }
	}
	
}

-(int)updateFromQueryResult: (BankQueryResult*)result
{
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	BankStatement	*stat;
	NSDate			*ltd = self.latestTransferDate;
	NSDate			*date = nil;
	ShortDate		*currentDate = nil;
	NSMutableArray	*newStatements = [NSMutableArray arrayWithCapacity:50 ];
	NSMutableArray	*resultingStatements = [NSMutableArray arrayWithCapacity:50 ];
	

	result.oldBalance = self.balance;
	if(result.balance) self.balance = result.balance;
	if(result.statements == nil) return 0;
	
	// rearrange statements by day
	NSDictionary *oldDayStats = [self statementsByDay:self.dbStatements ];

	// statements must be properly sorted !!! (regarding HBCI)
	for (stat in result.statements) {
		if([stat.isNew boolValue] == NO) continue;
		
		// now copy statement
		NSEntityDescription *entity = [stat entity];
		NSArray *attributeKeys = [[entity attributesByName] allKeys];
		NSDictionary *attributeValues = [stat dictionaryWithValuesForKeys:attributeKeys];
		
		BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement"
															inManagedObjectContext:context];
		
		[stmt setValuesForKeysWithDictionary:attributeValues];
		stmt.isNew = [NSNumber numberWithBool:YES ];
		
		// check for old statements
		ShortDate *stmtDate = [ShortDate dateWithDate:stmt.date ];
		
		if (currentDate == nil || [stmtDate isEqual:currentDate ] == NO) {
			// get start date
			NSArray *oldStats = [oldDayStats objectForKey:stmtDate ];
			if (oldStats == nil) {
				date = stmt.date;
			} else {
				date = nil;
				for(BankStatement *oldStat in oldStats) {
					[resultingStatements addObject:oldStat ];
					if (date == nil || [date compare:oldStat.date ] == NSOrderedAscending) {
						date = oldStat.date;
					}
				}
				date = [[[NSDate alloc ] initWithTimeInterval:10 sinceDate: date ] autorelease ];
			}
			currentDate = stmtDate;
		}
		
		stmt.date = date;
		date = [[[NSDate alloc ] initWithTimeInterval:10 sinceDate: date ] autorelease ];
		
		[newStatements addObject: stmt ];
		[resultingStatements addObject:stmt ];
		[stmt addToAccount: self ];
		if(ltd == nil || [ltd compare: stmt.date ] == NSOrderedAscending) ltd = stmt.date;
	}		
	
	if ([newStatements count ] > 0) {
		if (result.balance == nil) {
			// no balance given - calculate new balance
			NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
			NSArray				*sds = [NSArray arrayWithObject:sd];
			[newStatements sortUsingDescriptors:sds ];
			NSMutableArray *oldStatements = [[self.dbStatements mutableCopy] autorelease];
			[oldStatements sortUsingDescriptors:sds ];
			
			// find earliest old that is later than first new
			BankStatement *firstNewStat = [newStatements objectAtIndex:0 ];

			BOOL found = NO;
			NSMutableArray *mergedStatements = [NSMutableArray arrayWithCapacity:100 ];
			NSDecimalNumber *newSaldo;
			for(stat in oldStatements) {
				if ([stat.date compare:firstNewStat.date ] == NSOrderedDescending) {
					found = YES;
					newSaldo = [stat.saldo decimalNumberBySubtracting:stat.value ];
				}
				if (found) {
					[mergedStatements addObject:stat ];
				}
			}

			if(found == NO) {
				newSaldo = self.balance;
			}

			[mergedStatements addObjectsFromArray:newStatements ];
			[mergedStatements sortUsingDescriptors:sds ];
			// sum up saldo
			for(stat in mergedStatements) {
				newSaldo = [newSaldo decimalNumberByAdding: stat.value ];
				stat.saldo = newSaldo;
			}
			self.balance = newSaldo;
		} else {
			// balance was given - calculate back
			NSMutableArray *mergedStatements = [NSMutableArray arrayWithCapacity:100 ];
			[mergedStatements addObjectsFromArray:newStatements ];
			[mergedStatements addObjectsFromArray:self.dbStatements ];
			NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
			NSArray				*sds = [NSArray arrayWithObject:sd];
			[mergedStatements sortUsingDescriptors:sds ];
			NSDecimalNumber *newSaldo = self.balance;
			for(stat in mergedStatements) {
				stat.saldo = newSaldo;
				newSaldo = [newSaldo decimalNumberBySubtracting:stat.value ];
			}
		}
		[self copyStatementsToManualAccounts:newStatements ];
	}

	
/*	
	// statements must be properly sorted !!! (regarding HBCI)
	for (stat in result.statements) {
		if([stat.isNew boolValue] == NO) continue;

		// now copy statement
		NSEntityDescription *entity = [stat entity];
		NSArray *attributeKeys = [[entity attributesByName] allKeys];
		NSDictionary *attributeValues = [stat dictionaryWithValuesForKeys:attributeKeys];
		
		BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement"
															inManagedObjectContext:context];

		[stmt setValuesForKeysWithDictionary:attributeValues];
		stmt.isNew = [NSNumber numberWithBool:YES ];
		
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
*/	
	self.latestTransferDate = ltd;
	[self  calcUnread ];
	return [newStatements count ];
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
	return [[[NSDate alloc] initWithTimeInterval: 100 sinceDate:currentDate] autorelease];
}

-(void)copyStatement:(BankStatement*)stat
{
	NSDate *startDate = [[ShortDate dateWithDate:stat.date ] lowDate ];
	NSDate *endDate = [[ShortDate dateWithDate:stat.date ] highDate ];
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSError *error = nil;
	
	// first copy statement
	NSEntityDescription *entity = [stat entity];
	NSArray *attributeKeys = [[entity attributesByName] allKeys];
	NSDictionary *attributeValues = [stat dictionaryWithValuesForKeys:attributeKeys];
	
	BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement"
														inManagedObjectContext:context];
	
	[stmt setValuesForKeysWithDictionary:attributeValues];
	
	// negate value
	stmt.value = [[NSDecimalNumber zero ] decimalNumberBySubtracting:stmt.value ];
		
	// next check if duplicate
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankStatement" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@) AND (date < %@)", self, startDate, endDate ];
	[request setPredicate:predicate];
	NSArray *statements = [context executeFetchRequest:request error:&error];
	for(BankStatement *statement in statements) {
		if ([statement matches:stmt ]) {
			[context deleteObject:stmt ];
			return;
		}
	}
	
	// saldo
	stmt.date = [self nextDateForDate:stmt.date ];
	
	// adjust all statements after the current
	predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", self, stmt.date ];
	[request setPredicate:predicate];

	NSSortDescriptor	*sd = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	NSArray				*sds = [NSArray arrayWithObject:sd];
	[request setSortDescriptors:sds ];
	
	statements = [context executeFetchRequest:request error:&error];
	if (statements == nil || [statements count ] == 0) {
		self.balance = [self.balance decimalNumberByAdding:stmt.value ];
		stmt.saldo = self.balance;
	} else {
		BankStatement *statement = [statements objectAtIndex:0 ];
		NSDecimalNumber *base = [statement.saldo decimalNumberBySubtracting:statement.value ];
		stmt.saldo = [base decimalNumberByAdding:stmt.value ];
		
		for(statement in statements) {
			statement.saldo = [statement.saldo decimalNumberByAdding:stmt.value ];
			self.balance = statement.saldo;
		}
	}
	
	// add to account
	[stmt addToAccount:self ];	
}

-(void)copyStatementsToManualAccounts:(NSArray*)statements
{
	NSError *error = nil;
	
	// find all manual accounts that have rules
	if ([self.isManual boolValue ] == YES) return;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isManual = 1) AND (rule != nil)" ];
	[request setPredicate:predicate];
	NSArray *accounts = [context executeFetchRequest:request error:&error];
	if (accounts == nil || error || [accounts count ] == 0) return;
		
	for(BankAccount *account in accounts) {
		NSPredicate* pred = [NSPredicate predicateWithFormat: account.rule ];
		for(BankStatement *stat in statements) {
			if([pred evaluateWithObject: stat ]) {
				[account copyStatement:stat ];
			}
		}
	}	
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

+(NSInteger)maxUnread
{
	NSError *error = nil;
	NSInteger unread = 0;
	
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	if (context == nil) return 0;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BankAccount" inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isManual = 0) AND (accountNumber != nil)" ];
	[request setPredicate:predicate];
	NSArray *accounts = [context executeFetchRequest:request error:&error];
	if (accounts == nil || error || [accounts count ] == 0) return 0;
	
	for(BankAccount *account in accounts) {
		NSInteger n = [account calcUnread ];
		if (n > unread) unread = n;
	}	
	return unread;
}

-(void)dealloc
{
	[purposeSplitRule release ];
	[dbStatements release ];
	[super dealloc ];
}

@end
