//
//  StatCatAssignment.m
//  Pecunia
//
//  Created by Frank Emminghaus on 29.12.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "StatCatAssignment.h"
#import "Category.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "BankAccount.h"

@implementation StatCatAssignment

//@dynamic userInfo;
@dynamic value;
//@dynamic category;
@dynamic statement;

-(NSComparisonResult)compareDate: (StatCatAssignment*)stat
{
	return [self.statement.date compare: stat.statement.date ];
}

-(NSString*)stringForFields: (NSArray*)fields usingDateFormatter: (NSDateFormatter*)dateFormatter
{
	NSMutableString	*res = [NSMutableString stringWithCapacity: 300 ];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSString *s;
	NSObject *obj;
	NSString *sep = [defaults objectForKey:@"exportSeparator" ];
	
	if (sep == nil) sep = @"\t";
	
	for(NSString *field in fields) {
		if([field isEqualToString: @"value" ] || [field isEqualToString: @"userInfo" ]) obj = [self valueForKey: field ]; 
        else if([field isEqualToString:@"localName" ]) obj = self.statement.account.localName;
        else if([field isEqualToString:@"localCountry" ]) obj = self.statement.account.country; else obj = [self.statement valueForKey: field ];

		if (obj) {
			if([field isEqualToString: @"valutaDate" ] || [field isEqualToString: @"date" ]) s = [dateFormatter stringFromDate: (NSDate*)obj ];
			else if( [field isEqualToString: @"value" ] )  { 
				s = [(NSDecimalNumber*)obj descriptionWithLocale: [NSLocale currentLocale ]];
			}
			else if([field isEqualToString: @"categories" ]) {
				s = self.statement.categoriesDescription;
			} else s = [obj description ];
			
			if (s) [res appendString: s ];
		}
		[res appendString: sep ];
	}
	[res appendString: @"\n" ];
	return res;
}

-(void)moveToCategory:(Category*)tcat
{
	StatCatAssignment *stat;
	Category *ncat = [Category nassRoot ];
	Category *scat = self.category;
	
	// check if there is already an entry for the statement in tcat
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSMutableSet* stats = [self.statement mutableSetValueForKey: @"assignments" ];
	
	// if assignment already done, add value
	NSEnumerator *iter = [stats objectEnumerator];
	while (stat = [iter nextObject]) {
		if(stat.category == tcat) {
			stat.value = [stat.value decimalNumberByAdding: self.value ];
			// value must never be higher than statement's value
			if([stat.value compare: stat.statement.value ] == NSOrderedDescending) stat.value = stat.statement.value;
			[stat.statement updateAssigned ];
			[scat invalidateBalance ];
			[tcat invalidateBalance ];
			[context deleteObject: self ];
			return;
		}
	}
	
	self.category = tcat;
	if(tcat == ncat || scat == ncat) [self.statement updateAssigned ];
	[scat invalidateBalance ];
	[tcat invalidateBalance ];
}

-(void)remove
{
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	Category *cat = self.category;
	BankStatement *stat = self.statement;
	if (stat.account == nil) {
		[context deleteObject:stat ];
		stat = nil;
	} else [context deleteObject: self ];
	// important: do changes to the graph since updateAssigned counts on an updated graph
	[context processPendingChanges ];
	if (stat) [stat updateAssigned ];
	[cat invalidateBalance ];
}


-(id)valueForUndefinedKey: (NSString*)key
{
	NSLog(@"Undefined key: %@", key);
	return [self.statement valueForKey: key ];
}

- (Category *)category 
{
    id tmpObject;
    
    [self willAccessValueForKey:@"category"];
    tmpObject = [self primitiveCategory];
    [self didAccessValueForKey:@"category"];
    
    return tmpObject;
}

- (void)setCategory:(Category *)value 
{
    [self willChangeValueForKey:@"category"];
	[[self primitiveCategory] invalidateBalance ];
    [self setPrimitiveCategory:value];
    [self didChangeValueForKey:@"category"];
	[value invalidateBalance ];
//	[Category updateCatValues ];
}

-(NSString*)userInfo
{
    id tmpObject;
    
    [self willAccessValueForKey:@"userInfo"];
    tmpObject = [self primitiveValueForKey:@"userInfo"];
    [self didAccessValueForKey:@"userInfo"];
    
    return tmpObject;
}

-(void)setUserInfo:(NSString *)info
{
	NSString *oldInfo = self.userInfo;
	if (![oldInfo isEqualToString:info ]) {
		[self willChangeValueForKey:@"userInfo" ];
		[self setPrimitiveValue:info forKey:@"userInfo" ];
		[self didChangeValueForKey:@"userInfo"];
		if ([self.category isBankAccount ]) {
			BankStatement *statement = self.statement;
			// also set in all categories
			NSSet *stats = [statement mutableSetValueForKey:@"assignments" ];
			for (StatCatAssignment *stat in stats) {
				if (stat != self && (stat.userInfo == nil || [stat.userInfo isEqualToString: @"" ] || [stat.userInfo isEqualToString:oldInfo ])) {
					stat.userInfo = info;
				}
			}
		}
	}
}


- (BOOL)validateCategory:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

-(NSObject*)classify
{
	if(self.category == nil) return nil;
	if(self.category != [Category nassRoot ]) return [NSImage imageNamed: @"yes2.ico" ]; else return nil;
}



@end
