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

static ClassificationContext* classContext = nil;
static NSArray*	catCache = nil;

@implementation BankStatement

@dynamic valutaDate;
@dynamic value;
@dynamic remoteName;
@dynamic remoteIBAN;
@dynamic remoteBIC;
@dynamic remoteBankCode;
@dynamic remoteAccount;
@dynamic purpose;

@dynamic localCountry, localBankCode, localBranch, localAccount, localSuffix, localName, localIBAN, localBIC;
@dynamic remoteCountry, remoteBankName, remoteBankLocation, remoteBranch, remoteSuffix;
@dynamic transactionKey;
@dynamic customerReference;
@dynamic bankReference;
@dynamic transactionText;
@dynamic primaNota;
@dynamic textKey;
@dynamic transactionCode;
@dynamic currency;
@dynamic date;

@synthesize isNew;

-(void)updateWithAB: (const AB_TRANSACTION*)t
{
	const char*			c;
	const AB_VALUE*		val;
	const GWEN_TIME*	d;
	
	AB_TRANSACTION_TYPE		type;
	AB_TRANSACTION_SUBTYPE	stype;
	
	type = AB_Transaction_GetType(t);
	stype = AB_Transaction_GetSubType(t);
	
	self.localCountry = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalCountry(t)) ? c: ""];
	self.localBankCode = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBankCode(t)) ? c: ""];
	self.localBranch = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBranchId(t)) ? c: ""];
	self.localAccount = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalAccountNumber(t)) ? c: ""];
	self.localSuffix = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalSuffix(t)) ? c: ""];
	self.localName = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalName(t)) ? c: ""];
	self.localIBAN = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalIban(t)) ? c: ""];
	self.localBIC = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBic(t)) ? c: ""];
	self.remoteCountry = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteCountry(t)) ? c: ""];
	self.remoteBankName = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankName(t)) ? c: ""];
	self.remoteBankLocation = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankLocation(t)) ? c: ""];
	if(type != AB_Transaction_TypeEuTransfer) {
		self.remoteBankCode = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankCode(t)) ? c: ""];
	}
	
	self.remoteBranch = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBranchId(t)) ? c: ""];
	if(type != AB_Transaction_TypeEuTransfer) {
		self.remoteAccount = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteAccountNumber(t)) ? c: ""];
	}
	
	self.remoteSuffix = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteSuffix(t)) ? c: ""];
	self.remoteIBAN = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteIban(t)) ? c: ""];
	self.remoteBIC = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBic(t)) ? c: ""];
	self.remoteName = [self stringsFromAB: AB_Transaction_GetRemoteName(t)];
	self.transactionKey = [NSString stringWithUTF8String: (c = AB_Transaction_GetTransactionKey(t)) ? c: ""];
	self.customerReference = [NSString stringWithUTF8String: (c = AB_Transaction_GetCustomerReference(t)) ? c: ""];
	self.bankReference = [NSString stringWithUTF8String: (c = AB_Transaction_GetBankReference(t)) ? c: ""];
	self.transactionText = [NSString stringWithUTF8String: (c = AB_Transaction_GetTransactionText(t)) ? c: ""];
	self.primaNota = [NSString stringWithUTF8String: (c = AB_Transaction_GetPrimanota(t)) ? c: ""];
	self.purpose = [self stringsFromAB: AB_Transaction_GetPurpose(t)];

	self.textKey = [NSNumber numberWithInt: AB_Transaction_GetTextKey(t) ];
	self.transactionCode = [NSNumber numberWithInt: AB_Transaction_GetTransactionCode(t) ];

	val = AB_Transaction_GetValue(t);
	self.value = (NSDecimalNumber*)[NSDecimalNumber numberWithDouble: AB_Value_GetValueAsDouble(val) ];
	
	self.currency = [NSString stringWithUTF8String: (c = AB_Value_GetCurrency(val)) ? c: ""];
	
	d = AB_Transaction_GetDate(t);
	if(d) {
		self.date = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	}
	
	d = AB_Transaction_GetValutaDate(t);
	if(d) { 
		self.valutaDate = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	}
}

-(NSString*)categoriesDescription
{
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	Category *cat;
	NSString *result = nil;
	for(cat in cats) {
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
	
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	[cats addObject: account ];
	
	//assign categories
	BOOL assigned = NO;
	for(i = 0; i < [catCache count ]; i++) {
		Category* cat = [catCache objectAtIndex: i ];
		NSPredicate* pred = [NSPredicate predicateWithFormat: [cat valueForKey: @"rule" ] ];
		if([pred evaluateWithObject: self ]) {
			[self assignToCategory: cat ];
			assigned = YES;
		}
	}
	if(assigned == NO) {
		Category *nassRoot = [Category nassRoot ];
		[cats addObject: nassRoot ];
		[nassRoot invalidateBalance ];
	}
}

-(NSString*)stringsFromAB: (const GWEN_STRINGLIST*)sl
{
	NSMutableString* result = [NSMutableString stringWithCapacity: 100 ];
	const char*	c;
	NSString*	s;
	GWEN_STRINGLISTENTRY* sle; 
	
	if(!sl) return result;
	sle = GWEN_StringList_FirstEntry(sl);
	while(sle) {
		s = [NSString stringWithUTF8String: (c = GWEN_StringListEntry_Data(sle)) ? c: ""];
	    [result appendFormat:  @"%@ ", s ];
		sle = GWEN_StringListEntry_Next(sle);
	}
	return result;
}

-(BOOL)matches: (BankStatement*)stat
{
	NSTimeInterval ti = [[self valutaDate ] timeIntervalSinceDate: [stat valutaDate ] ];
	if(ti > 10) return NO;
	if(abs([self.value doubleValue ] - [stat.value doubleValue ]) > 0.001) return NO;
	NSString *p1 = [self.purpose stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
	NSString *p2 = [stat.purpose stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
	
	if ([p1 isEqualToString:p2 ] == NO) return NO;
	if(	[self.remoteAccount isEqualToString: stat.remoteAccount ] &&
		[self.remoteBankCode isEqualToString: stat.remoteBankCode ] &&
		[self.remoteBIC isEqualToString: stat.remoteBIC ] &&
		[self.remoteIBAN isEqualToString: stat.remoteIBAN ] ) return YES;
	return NO;
}

-(BOOL)isAssigned
{
	Category *cat;
	Category *ncat = [Category nassRoot ];
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	NSEnumerator *iter = [cats objectEnumerator];
	while (cat = [iter nextObject]) {
		if([cat isBankAccount ] == NO && cat != ncat) return YES;
	}
	return NO;
}

-(void)verifyAssignment
{
	Category *cat;
	Category *ncat = [Category nassRoot ];
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	NSEnumerator *iter = [cats objectEnumerator];
	while (cat = [iter nextObject]) {
		if([cat isBankAccount ] == NO) return;
	}
	[cats addObject: ncat ];
	[ncat invalidateBalance ];
}


-(void)assignToCategory:(Category*)cat
{
	Category *ncat = [Category nassRoot ];
	NSMutableSet* cats = [self mutableSetValueForKey: @"categories" ];
	[cats removeObject: ncat ];
	[cats addObject: cat ];
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
	if([self isAssigned ] == NO) {
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
	return [[self valutaDate ] compare: [stat valutaDate ] ];
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


@end
