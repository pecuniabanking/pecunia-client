//
//  BankStatement.m
//  Pecunia
//
//  Created by Frank Emminghaus on 30.06.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "BankStatement.h"
#import "ClassificationContext.h"
#import "Category.h"
#import "MOAssistant.h"
#import "StatCatAssignment.h"
#import "ShortDate.h"
#import "MCEMDecimalNumberAdditions.h"

static ClassificationContext* classContext = nil;
static NSArray*	catCache = nil;

@implementation BankStatement

@dynamic valutaDate;
@dynamic date;

@dynamic value, nassValue, charge, saldo;
@dynamic localBankCode, localAccount;
@dynamic remoteName, remoteIBAN, remoteBIC, remoteBankCode, remoteAccount, remoteCountry, remoteBankName, remoteBankLocation;
@dynamic purpose, localSuffix, remoteSuffix;

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
@dynamic isNew;
@dynamic ref1, ref2, ref3, ref4;


BOOL stringEqualIgnoreWhitespace(NSString *a, NSString *b)
{
	int i=0, j=0;
	int l1, l2;
	BOOL done = NO;
	NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet ];
	
	if (a == nil && b == nil) return YES;
	if (a == nil && b != nil && [b length ] == 0) return YES;
	if (a != nil && b == nil && [a length ] == 0) return YES;
	if (a == nil && b != nil) return NO;
	if (a != nil && b == nil) return NO;
	l1 = [a length ];
	l2 = [b length ];
	while (done == NO) {
		//find first of a and b
		while (i<l1 && [cs characterIsMember: [a characterAtIndex:i ] ]) i++;		
		while (j<l2 && [cs characterIsMember: [b characterAtIndex:j ] ]) j++;
		if (i==l1 && j==l2) return YES;
		if (i<l1 && j<l2) {
			if ([a characterAtIndex:i ] != [b characterAtIndex:j ]) return NO;
			else {
				i++;
				j++;
			}
		} else return NO;	
	}
	return YES;
}

BOOL stringEqualIgnoringMissing(NSString *a, NSString *b)
{
	if (a == nil || b == nil) return YES;
	if ([a length ] == 0 || [b length ] == 0) return YES;
	return [a isEqualToString:b ];	
}

BOOL stringEqual(NSString *a, NSString *b)
{
	if (a == nil && b == nil) return YES;
	if (a == nil && b != nil && [b length ] == 0) return YES;
	if (a != nil && b == nil && [a length ] == 0) return YES;
	if (a == nil && b != nil) return NO;
	if (a != nil && b == nil) return NO;
	return [a isEqualToString:b ];
}


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
	for (Category* cat in catCache) {
		NSPredicate* pred = [NSPredicate predicateWithFormat: cat.rule ];
		if([pred evaluateWithObject: stat ]) {
			[self assignToCategory: cat ];
		}
	}
	[self updateAssigned ];
}

-(BOOL)matches: (BankStatement*)stat
{
/*	
	if([self.hashNumber isEqual: stat.hashNumber ]) return YES;
	return NO;
*/ 
	ShortDate *d1 = [ShortDate dateWithDate:self.date ];
	ShortDate *d2 = [ShortDate dateWithDate:stat.date ];
	
	if ([d1 isEqual: d2 ] == NO) return NO;
	if(abs([self.value doubleValue ] - [stat.value doubleValue ]) > 0.001) return NO;
	
	if (stringEqualIgnoreWhitespace(self.purpose, stat.purpose) == NO) return NO;
	if (stringEqualIgnoreWhitespace(self.remoteName, stat.remoteName) == NO) return NO;

	if (stringEqualIgnoringMissing(self.remoteAccount, stat.remoteAccount) == NO) return NO;
	if (stringEqualIgnoringMissing(self.remoteBankCode, stat.remoteBankCode) == NO) return NO;
	if (stringEqualIgnoringMissing(self.remoteBIC, stat.remoteBIC) == NO) return NO;
	if (stringEqualIgnoringMissing(self.remoteIBAN, stat.remoteIBAN) == NO) return NO;
	return YES; 
}

-(BOOL)matchesAndRepair: (BankStatement*)stat
{
	NSDecimalNumber *e = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-2 isNegative:NO ];
	ShortDate *d1 = [ShortDate dateWithDate:self.date ];
	ShortDate *d2 = [ShortDate dateWithDate:stat.date ];
	
	if ([d1 isEqual: d2 ] == NO) return NO;
	
	if (stringEqualIgnoreWhitespace(self.purpose, stat.purpose) == NO) return NO;
	if (stringEqualIgnoreWhitespace(self.remoteName, stat.remoteName) == NO) return NO;
	
	if (stringEqualIgnoringMissing(self.remoteAccount, stat.remoteAccount) == NO) return NO;
	if (stringEqualIgnoringMissing(self.remoteBankCode, stat.remoteBankCode) == NO) return NO;
	if (stringEqualIgnoringMissing(self.remoteBIC, stat.remoteBIC) == NO) return NO;
	if (stringEqualIgnoringMissing(self.remoteIBAN, stat.remoteIBAN) == NO) return NO;
	
	NSDecimalNumber *d = [[self.value decimalNumberBySubtracting: stat.value ] abs ];
	if ([d compare:e ] == NSOrderedDescending) return NO;	
	if ([d compare:e ] == NSOrderedSame) {
		// repair
		[stat changeValueTo:self.value ];
	}
	return YES; 
}

-(void)changeValueTo:(NSDecimalNumber*)val
{
	Category *ncat = [Category nassRoot ];

	self.value = val;
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	for(StatCatAssignment *stat in stats) {
		if([stat.category isBankAccount]) stat.value = val;
		// if there is only one category assignment, change that as well
		if(stat.category != ncat && [stats count ] == 2) stat.value = val;
	}
	[self updateAssigned ];
}


-(BOOL)hasAssignment
{
	StatCatAssignment *stat;
	Category *ncat = [Category nassRoot ];
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	NSEnumerator *iter = [stats objectEnumerator];
	while ((stat = [iter nextObject]) != nil) {
		if([stat.category isBankAccount] == NO && stat.category != ncat) return YES;
	}
	return NO;
}

-(StatCatAssignment*)bankAssignment
{
	NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
	StatCatAssignment *stat;
	for (stat in stats) {
		if([stat.category isBankAccount] == YES) return stat;
	}
	return nil;
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
	while ((stat = [iter nextObject]) != nil) {
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
	if(assigned == NO) self.nassValue = value; else self.nassValue = [NSDecimalNumber zero ];
	BOOL found = NO;
	iter = [stats objectEnumerator];
	while ((stat = [iter nextObject]) != nil) {
		if(stat.category == ncat) {
			if(assigned || [stat.value compare: value ] != NSOrderedSame) [ncat invalidateBalance ];
			if(assigned) [context deleteObject: stat ]; else stat.value = value;
			found = YES;
			break;
		}
	}
	
	if(found == NO && assigned == NO) {
		// create a new assignment to ncat
		stat = [NSEntityDescription insertNewObjectForEntityForName:@"StatCatAssignment" inManagedObjectContext:context ];
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
	while ((stat = [iter nextObject]) != nil) {
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
	while ((stat = [iter nextObject]) != nil) {
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
		StatCatAssignment *bStat = [self bankAssignment ];
		stat.value = value;
		if(cat) stat.category = cat;
		stat.statement = self;
		// get User Info from Bank Assignment
		if (bStat.userInfo) {
			stat.userInfo = bStat.userInfo;
		} else stat.userInfo = @"";
		[stats addObject: stat ];
	}
	
	[self updateAssigned];
    
	[cat invalidateBalance];
	[ncat invalidateBalance];
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
	NSObject *obj;
	
	for (NSString* field in fields) {
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
	s = [s stringByReplacingOccurrencesOfString:@"\n " withString:@" " ];
	s = [s stringByReplacingOccurrencesOfString:@" \n" withString:@" " ];
	return [s stringByReplacingOccurrencesOfString:@"\n" withString:@" " ];
}

-(NSString*)note
{
	StatCatAssignment *stat = [self bankAssignment ];
	return stat.userInfo;
}


@end
