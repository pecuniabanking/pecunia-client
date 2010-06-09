//
//  BankStatement.m
//  MacBanking
//
//  Created by Frank Emminghaus on 30.06.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "BankStatement.h"
#import "ClassificationContext.h"
#import "Category.h"
#import "MOAssistant.h"
#import "StatCatAssignment.h"

static ClassificationContext* classContext = nil;
static NSArray*	catCache = nil;

@implementation BankStatement

@dynamic valutaDate;
@dynamic date;

@dynamic value, charge, saldo;
@dynamic localBankCode, localAccount;
@dynamic remoteName, remoteIBAN, remoteBIC, remoteBankCode, remoteAccount, remoteCountry;
@dynamic purpose;

@dynamic customerReference, bankReference;
@dynamic transactionCode, transactionText;
@dynamic primaNota;
@dynamic currency;
@dynamic additional;
@dynamic isAssigned;	// assigned to >= 100%
@dynamic account;
@dynamic hashNumber;
@dynamic isManual;
@dynamic isStorno;

@synthesize isNew;

-(NSString*)categoriesDescription
{
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	NSMutableSet *cats = [NSMutableSet setWithCapacity:10 ];
	StatCatAssignment *stat;
	NSString *result = nil;
	for(stat in stats) {
		Category *cat = stat.category;
		if (cat == nil) {
			continue;
		}
		// avoid same category several times
		if ([cats containsObject:cat ]) {
			continue;
		} else {
			[cats addObject:cat ];
		}

		if([cat isBankAccount ]) continue;
		if([cat isNotAssignedCategory ]) continue;
		if(result) result = [NSString stringWithFormat: @"%@, %@", result, [cat localName ] ];
		else result = [cat localName ];
	}
	if(result) return result; else return @"";
}

-(void)addToAccount: (BankAccount*)account
{
	int i;
	if(account == nil) return;
	
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	
	// create StatCatAssignment
	StatCatAssignment *stat = [NSEntityDescription insertNewObjectForEntityForName:@"StatCatAssignment" inManagedObjectContext:context ];
	stat.value = self.value;
	stat.category = (Category*)account;
	stat.statement = self;
	
	self.account = account;
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	[stats addObject: stat ];
	
	// adjust posting date for manual postings
/*
	if ([self.isManual boolValue ] == YES) {
		self.date = [account nextDateForDate:self.date ];
	}	
*/	
	//assign categories
	for(i = 0; i < [catCache count ]; i++) {
		Category* cat = [catCache objectAtIndex: i ];
		NSPredicate* pred = [NSPredicate predicateWithFormat: [cat valueForKey: @"rule" ] ];
		if([pred evaluateWithObject: stat ]) {
			[self assignToCategory: cat ];
		}
	}
	[self updateAssigned ];
}

-(BOOL)matches: (BankStatement*)stat
{
	if([self.hashNumber isEqual: stat.hashNumber ]) return YES;
	return NO;
/*	
	NSTimeInterval ti = [[self valutaDate ] timeIntervalSinceDate: [stat valutaDate ] ];
	if(ti > 10) return NO;
	if(abs([self.value doubleValue ] - [stat.value doubleValue ]) > 0.001) return NO;
	if(	[self.remoteAccount isEqualToString: stat.remoteAccount ] &&
		[self.remoteBankCode isEqualToString: stat.remoteBankCode ] &&
		[self.remoteBIC isEqualToString: stat.remoteBIC ] &&
		[self.remoteIBAN isEqualToString: stat.remoteIBAN ] &&
		[self.purpose isEqualToString: stat.purpose ]) return YES;
	return NO;
*/ 
}

-(BOOL)hasAssignment
{
	StatCatAssignment *stat;
	Category *ncat = [Category nassRoot ];
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	NSEnumerator *iter = [stats objectEnumerator];
	while (stat = [iter nextObject]) {
		if([stat.category isBankAccount] == NO && stat.category != ncat) return YES;
	}
	return NO;
}
 
-(void)updateAssigned
{
	NSDecimalNumber *value = self.value;
	BOOL positive = [value compare: [NSDecimalNumber zero ]] != NSOrderedAscending;
	BOOL assigned = NO;
	StatCatAssignment *stat;
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	Category *ncat = [Category nassRoot ];
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	NSEnumerator *iter = [stats objectEnumerator];
	while (stat = [iter nextObject]) {
		if([stat.category isBankAccount ] == NO && stat.category != ncat) {
			value = [value decimalNumberBySubtracting: stat.value ];
		}
	}
	if(positive) {
		 if([value compare: [NSDecimalNumber zero ]] != NSOrderedDescending) assigned = YES; // fully assigned
	} else {
		 if([value compare: [NSDecimalNumber zero ]] != NSOrderedAscending) assigned = YES; // fully assigned
	}
	self.isAssigned = [NSNumber numberWithBool:assigned ];
	
	// update not assigned part
	BOOL found = NO;
	iter = [stats objectEnumerator];
	while (stat = [iter nextObject]) {
		if(stat.category == ncat) {
			if(assigned || [stat.value compare: value ] != NSOrderedSame) [ncat invalidateBalance ];
			if(assigned) [context deleteObject: stat ]; else stat.value = value;
			found = YES;
			break;
		}
	}
	
	if(found == NO && assigned == NO) {
		// create a new assignment to ncat
		StatCatAssignment *stat = [NSEntityDescription insertNewObjectForEntityForName:@"StatCatAssignment" inManagedObjectContext:context ];
		stat.value = value;
		stat.category = ncat;
		stat.statement = self;
		[ncat invalidateBalance ];
	}
}

-(NSDecimalNumber*)residualAmount
{
	Category *ncat = [Category nassRoot ];
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	NSEnumerator *iter = [stats objectEnumerator];
	StatCatAssignment *stat;
	while (stat = [iter nextObject]) {
		if(stat.category == ncat) return stat.value;
	}
	return [NSDecimalNumber zero ];
}


-(void)assignToCategory:(Category*)cat
{
	[self assignAmount: self.value toCategory: cat ];
}

-(void)assignAmount: (NSDecimalNumber*)value toCategory:(Category*)cat
{
	StatCatAssignment *stat;
	Category *ncat = [Category nassRoot ];
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	
	// if assignment already done, add value
	NSEnumerator *iter = [stats objectEnumerator];
	BOOL changed = NO;
	while (stat = [iter nextObject]) {
		if(stat.category == cat) {
			if(value == nil || [value isEqual: [NSDecimalNumber zero ] ]) [context deleteObject: stat ]; else stat.value = [stat.value decimalNumberByAdding: value ];
			changed = YES;
			break;
		}
	}
	// value must never be higher than statement's value
	if([stat.value compare: stat.statement.value ] == NSOrderedAscending) stat.value = stat.statement.value;
	
	if(changed == NO) {
		// create StatCatAssignment
		stat = [NSEntityDescription insertNewObjectForEntityForName:@"StatCatAssignment" inManagedObjectContext:context ];
		stat.value = value;
		if(cat) stat.category = cat;
		stat.statement = self;
		[stats addObject: stat ];
	}
	
	[self updateAssigned ];
	
	[cat invalidateBalance ];
	[ncat invalidateBalance ];
}


-(void)moveFromCategory:(Category*)scat toCategory:(Category*)tcat
{
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	[cats removeObject: scat ];
	[cats addObject: tcat ];
	[scat invalidateBalance ];
	[tcat invalidateBalance ];
}

-(void)removeFromCategory:(Category*)cat
{
	Category *ncat = [Category nassRoot ];
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	[cats removeObject: cat ];
	[cat invalidateBalance ];
	if([self.isAssigned boolValue ] == NO) {
		[cats addObject: ncat ];
		[ncat invalidateBalance ];
	}
}

+(void)setClassificationContext: (ClassificationContext*)cc
{
	if(classContext) [classContext release ];
	classContext = [cc retain];
}

+(ClassificationContext*)classificationContext
{
	return classContext;
}


-(NSObject*)classify
{
	return [classContext classify: self ];
}

-(NSComparisonResult)compareValuta: (BankStatement*)stat
{
	return [self.valutaDate compare: stat.valutaDate ];
}


-(NSString*)stringForFields: (NSArray*)fields usingDateFormatter: (NSDateFormatter*)dateFormatter
{
	NSMutableString	*res = [NSMutableString stringWithCapacity: 300 ];
	NSString *s;
	int i;
	NSObject *obj;
	
	for(i = 0; i < [fields count ]; i++) {
		NSString* field = [fields objectAtIndex: i ];
		obj = [self valueForKey: field ];
		if([field isEqualToString: @"valutaDate" ] || [field isEqualToString: @"date" ]) s = [dateFormatter stringFromDate: (NSDate*)obj ];
		else if( [field isEqualToString: @"value" ] )  { 
			s = [(NSDecimalNumber*)obj descriptionWithLocale: [NSLocale currentLocale ]];
		}
		else if([field isEqualToString: @"categories" ]) {
			s = [self categoriesDescription ];
		} else s = [obj description ];
			
		[res appendString: s ];	[res appendString: @"\t" ];
	}
	[res appendString: @"\n" ];
	return res;
}

+(void)initCategoriesCache
{
	NSError* error = nil;
	NSManagedObjectContext* context = [[MOAssistant assistant ] context ];
	NSManagedObjectModel*	model   = [[MOAssistant assistant ] model ];

	
	if(catCache) [catCache release ];
	catCache = nil;
	NSFetchRequest *request = [model fetchRequestTemplateForName:@"categories"];
	catCache = [context executeFetchRequest:request error:&error];
	if( error != nil || catCache == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	[catCache retain ];
}

-(NSString*)floatingPurpose
{
	// replace newline with space
	NSString *s = [self purpose ];
	return [s stringByReplacingOccurrencesOfString:@"\n" withString:@"" ];
}


@end
