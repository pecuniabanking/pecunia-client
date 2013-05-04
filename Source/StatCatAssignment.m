/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

#import "StatCatAssignment.h"
#import "Category.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "MCEMDecimalNumberAdditions.h"

@implementation StatCatAssignment

@dynamic value;
@dynamic statement;

-(NSComparisonResult)compareDate: (StatCatAssignment*)stat
{
	return [self.statement.date compare: stat.statement.date];
}

-(NSString*)stringForFields: (NSArray*)fields usingDateFormatter:(NSDateFormatter*)dateFormatter numberFormatter:(NSNumberFormatter*)numberFormatter
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
                s = [numberFormatter stringFromNumber:(NSNumber*)obj];
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

-(void)moveAmount:(NSDecimalNumber*)amount toCategory:(Category*)tcat
{
	StatCatAssignment *stat;
	Category *scat = self.category;
    
    if ([amount abs] > [self.value abs]) {
        amount = self.value;
    }
    if (tcat == scat) {
        return;
    }
    
	// check if there is already an entry for the statement in tcat
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSMutableSet* stats = [self.statement mutableSetValueForKey: @"assignments" ];
	
	// if assignment already done, add value
    BOOL assignmentDone = NO;
	for (stat in stats) {
		if(stat.category == tcat) {
			stat.value = [stat.value decimalNumberByAdding: amount ];
			// value must never be higher than statement's value
			if([[stat.value abs] compare: [stat.statement.value abs] ] == NSOrderedDescending) stat.value = stat.statement.value;
			[stat.statement updateAssigned ];
			[scat invalidateBalance ];
			[tcat invalidateBalance ];
            assignmentDone = YES;
            /*
			if (self != stat) {
                [context deleteObject: self ];
            }
            */ 
			return;
		}
	}

    // if assignment is not done yet, create it
    if (assignmentDone == NO) {
        stat = [NSEntityDescription insertNewObjectForEntityForName:@"StatCatAssignment" inManagedObjectContext:context ];
        stat.userInfo = self.userInfo;
        stat.category = tcat;
        stat.statement = self.statement;
        stat.value = amount;
    }

    // adjust self
    self.value = [self.value decimalNumberBySubtracting:amount];
    if ([self.value compare:[NSDecimalNumber zero]] == NSOrderedSame) {
        [context deleteObject:self];
    }
    
    [context processPendingChanges];

	[scat invalidateBalance];
	[tcat invalidateBalance];
    
    [tcat updateBoundAssignments];
    [scat updateBoundAssignments];
}

-(void)moveToCategory:(Category*)tcat
{
	StatCatAssignment *stat;
	Category *ncat = [Category nassRoot ];
	Category *scat = self.category;
    
    if (tcat == scat) {
        return;
    }
	
	// check if there is already an entry for the statement in tcat
	NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
	NSMutableSet* stats = [self.statement mutableSetValueForKey: @"assignments" ];
	
	// if assignment already done, add value
	NSEnumerator *iter = [stats objectEnumerator];
	while ((stat = [iter nextObject]) != nil) {
		if(stat.category == tcat) {
			stat.value = [stat.value decimalNumberByAdding: self.value ];
			// value must never be higher than statement's value
			if([[stat.value abs] compare: [stat.statement.value abs] ] == NSOrderedDescending) stat.value = stat.statement.value;
			[stat.statement updateAssigned ];
			if (self != stat) {
                [context deleteObject: self ];
                [context processPendingChanges];
            }
			[scat invalidateBalance ];
			[tcat invalidateBalance ];
            [tcat updateBoundAssignments];
            [scat updateBoundAssignments];
			return;
		}
	}

    [context processPendingChanges];

	self.category = tcat;

	[scat invalidateBalance];
	[tcat invalidateBalance];

    // This call doesn't actually update anything but triggers a KVO notification about this assignment change.
    // TODO: do we need a similar call for the old category?
    [tcat updateBoundAssignments];
    [scat updateBoundAssignments];

	if (tcat == ncat || scat == ncat) {
        [self.statement updateAssigned];
    }
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
	[context processPendingChanges];
	if (stat) [stat updateAssigned];
	[cat invalidateBalance ];
    [cat updateBoundAssignments];
}


-(id)valueForUndefinedKey: (NSString*)key
{
	NSLog(@"Undefined key: %@", key);
	return [self.statement valueForKey: key ];
}

- (Category *)category 
{
    [self willAccessValueForKey: @"category"];
    Category *result = [self primitiveCategory];
    [self didAccessValueForKey: @"category"];
    return result;
}

- (void)setCategory:(Category *)value 
{
	[[self primitiveCategory] invalidateBalance];
    [self willChangeValueForKey: @"category"];
    [self setPrimitiveCategory: value];
    [self didChangeValueForKey: @"category"];
	[value invalidateBalance];
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

@end
