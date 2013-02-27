/**
 * Copyright (c) 2007, 2013, Pecunia Project. All rights reserved.
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

#import "Category.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "ShortDate.h"
#import "BankingController.h"
#import "StatCatAssignment.h"
#import "CategoryReportingNode.h"
#import "PreferenceController.h"

#import "GraphicsAdditions.h"

static Category *catRootSingleton = nil;
static Category *bankRootSingleton = nil;
static Category *notAssignedRootSingleton = nil;

ShortDate *startReportDate = nil;
ShortDate *endReportDate = nil;

BOOL updateSent = NO;

// balance: sum of own statements
// catSum: sum of balance and child's catSums


@implementation Category

@dynamic rule;
@dynamic name;
@dynamic isBankAcc;
@dynamic currency;
@dynamic parent;
@dynamic isBalanceValid;
@dynamic catSum;
@dynamic balance;
@dynamic noCatRep;
@dynamic catRepColor;
@dynamic iconName;
@dynamic isHidden;

@synthesize categoryColor;
@synthesize reportedAssignments;  // assignments that are between start and end report date

// if the value of a category (sum of assignments between start and end report date) is not valid (isBalanceValid) it is recalculated
// the value of a category is stored in the balance field
- (void)updateInvalidCategoryValues
{
    // only for categories
    if (self.isBankAccount) {
        return;
    }
    
    for (Category *category in self.children) {
        [category updateInvalidCategoryValues];
    }

    if (!self.isBalanceValid.boolValue) {
        NSArray *stats = nil;
        NSDecimalNumber	*balance = [NSDecimalNumber zero ];
        
        assert(startReportDate != nil);
        assert(endReportDate != nil);
        stats = [self assignmentsFrom: startReportDate
                                   to: endReportDate
                         withChildren: NO];
        
        StatCatAssignment *stat = nil;
        for (stat in stats) {
            balance = [balance decimalNumberByAdding: stat.value];
        }
        if (stat) {
            NSString *curr = stat.statement.currency;
            if (curr != nil && curr.length > 0) {
                self.currency = curr;
            }
        }
        self.balance = balance;
        self.isBalanceValid = @YES;
    }
}

// rebuild all category values due to a change in the reporting period
// also updates assignments cache
- (void)rebuildValues
{
    if ([self isBankAccount]) {
        return;
    }
    
    for (Category *cat in self.children) {
        [cat rebuildValues];
    }

    // now handle self
    NSDecimalNumber	*balance = NSDecimalNumber.zero;
    
    assert(startReportDate != nil);
    assert(endReportDate != nil);
    self.reportedAssignments = nil;  // clear cache
    NSArray *assignments = [self assignmentsFrom: startReportDate
                                              to: endReportDate
                                    withChildren: NO];
    
    for (StatCatAssignment *assignment in assignments) {
        if (assignment.value != nil) {
            balance = [balance decimalNumberByAdding: assignment.value];
        } else {
            assignment.value = NSDecimalNumber.zero;
        }
    }
    self.balance = balance;
}

/**
 * Collect hierarchical values like overall balance, hidden children etc.
 */
- (NSDecimalNumber*)rollup
{
    NSDecimalNumber *res = self.balance;
    hiddenChildren = 0;
    for (Category *category in self.children) {
        NSDecimalNumber *childResult = [category rollup];
        if (!category.noCatRep.boolValue) {
            res = [res decimalNumberByAdding: childResult];
        }
        if (category.isHidden) {
            hiddenChildren++;
        }
    }
    self.catSum = res;
    if ([self.children count] > 0) {
        // For now we assume all children have the same currency. We pick one child
        // to update this category's currency.
        NSString *currency = [[self.children anyObject] currency];
        if (currency.length > 0) {
            self.currency = currency;
        }
    }
    // reset update flag
    updateSent = NO;
    return res;
}

-(void)invalidateBalance
{
    self.isBalanceValid = @NO;
    self.reportedAssignments = nil; // also remove cache
}

// value of expenses, earnings or turnovers for a specified period
-(NSDecimalNumber*)valuesOfType: (CatValueType)type from: (ShortDate*)fromDate to: (ShortDate*)toDate
{
    NSDecimalNumber* result = [NSDecimalNumber zero];

    for (Category *category in self.children) {
        result = [result decimalNumberByAdding: [category valuesOfType: type from: fromDate to: toDate]];
    }

    NSArray *assignments = [self assignmentsFrom: fromDate to: toDate withChildren: NO];
    if ([assignments count] > 0)
    {
        switch (type)
        {
            case cat_all:
                for (StatCatAssignment *assignment in assignments) {
                    result = [result decimalNumberByAdding: assignment.value];
                }
                break;
            case cat_earnings:
                for (StatCatAssignment *assignment in assignments) {
                    if ([assignment.value compare: NSDecimalNumber.zero] == NSOrderedDescending)
                        result = [result decimalNumberByAdding: assignment.value];
                }
                break;
            case cat_spendings:
                for (StatCatAssignment *assignment in assignments) {
                    if ([assignment.value compare: NSDecimalNumber.zero] == NSOrderedAscending)
                        result = [result decimalNumberByAdding: assignment.value];
                }
                break;
            case cat_turnovers:
            {
                result = [result decimalNumberByAdding: [NSDecimalNumber decimalNumberWithMantissa: assignments.count
                                                                                          exponent: 0
                                                                                        isNegative: NO]];
                break;
            }
        }
    }
    return result;
}

// returns all assignments for the specified period
// if the period equals the reporting period, the assignments are cached / retrieved from cache
// the cache always only contains assignments directly belonging to the current category, not those from child categories!
-(NSArray*)assignmentsFrom: (ShortDate*)fromDate to: (ShortDate*)toDate withChildren: (BOOL)includeChildren
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity: 100];
    
    if (includeChildren) {
        for (Category *category in self.children) {
            [result addObjectsFromArray: [category assignmentsFrom: fromDate to: toDate withChildren: YES]];
        }
    }

    // check if we can take the assignments from cache
    if ([fromDate isEqual: startReportDate] && [toDate isEqual: endReportDate] && self.reportedAssignments != nil) {
        [result addObjectsFromArray: self.reportedAssignments];
        return result;
    }
    
    // fetch all relevant statements
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StatCatAssignment" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSDate *from = [fromDate lowDate];
    NSDate *to = [toDate highDate];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@ and statement.date >= %@ and statement.date <= %@", self, from, to];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects != nil) {
        [result addObjectsFromArray:fetchedObjects];
    }
    // cache assignments
    if ([fromDate isEqual: startReportDate] && [toDate isEqual: endReportDate]) {
        self.reportedAssignments = [fetchedObjects copy];
    }
    return result;	
}

// update reported assignment caches due to a change of the reporting period
- (void)updateReportedAssignments
{
    for (Category *category in self.children) {
        [category updateReportedAssignments];
    }

    // now handle self
    self.reportedAssignments = nil;
    [self assignmentsFrom: startReportDate to: endReportDate withChildren: NO];
}


-(NSString*)accountNumber { return nil; }

-(NSString*)localName
{
    [self willAccessValueForKey:@"name"];
    NSString *n = [self primitiveValueForKey:@"name"];
    [self didAccessValueForKey:@"name"];
    if(self.parent == nil) {
        if([n isEqualToString: @"++bankroot" ]) return NSLocalizedString(@"banking_root", @"");
        if([n isEqualToString: @"++catroot" ]) return NSLocalizedString(@"category_root", @"");
    }
    if([n isEqualToString: @"++nassroot" ]) return NSLocalizedString(@"nass_root", @"");
    return n;
}

/**
 * Sets the name of this category to the given value. Checks are done to ensure that the overall
 * structure will not be broken.
 */
-(void)setLocalName: (NSString*)name
{
    if (name == nil)
        return;
    
    [self willAccessValueForKey: @"name"];
    NSString *n = [self primitiveValueForKey: @"name"];
    [self didAccessValueForKey: @"name"];
    
    // Check for special node names denoting certain built-in elements and refuse to rename them.
    if (n != nil)
    {
        // The existing name must have a value for this check to work properly.
        NSRange r = [n rangeOfString: @"++"];
        if (r.location == 0)
            return;
    }
    
    // Check also the new name so it doesn't use our special syntax to denote such elements.
    NSRange r = [name rangeOfString: @"++"];
    if (r.location == 0)
        return;
    
    [self setValue: name forKey: @"name"];
}

-(BOOL)isRoot
{
    return self.parent == nil;
}

-(BOOL)isBankAccount
{
    return [self.isBankAcc boolValue ];
}

-(BOOL)isBankingRoot
{
    if( self.parent == nil ) return [self.isBankAcc boolValue ];
    return NO;
}

-(BOOL)isEditable
{
    if(self.parent == nil) return NO;
    NSString *n = [self primitiveValueForKey:@"name"];
    if(n != nil) {
        NSRange r = [n rangeOfString: @"++" ];
        if(r.location == 0) return NO;
    }
    return YES;
    //	return [self isMemberOfClass: [Category class ] ];
}

-(BOOL)isRemoveable
{
    if(self.parent == nil) return NO;
    NSString *n = [self primitiveValueForKey:@"name"];
    if(n != nil) {
        NSRange r = [n rangeOfString: @"++" ];
        if(r.location == 0) return NO;
    }
    if ([self.children count] > 0) {
        return NO;
    }
    return [self isMemberOfClass: [Category class]];
}

-(BOOL)isInsertable
{
    if (self.isBankAcc.boolValue) {
        return NO;
    }
    NSString *n = [self primitiveValueForKey: @"name"];
    if ([n isEqual: @"++nassroot"]) {
        return NO;
    }
    return TRUE;
}

-(BOOL)isRequestable
{
    if (![self isBankAccount]) {
        return NO;
    }
    return ![BankingController.controller requestRunning];
}

-(BOOL)isNotAssignedCategory
{
    return self == [Category nassRoot ];
}

-(id)children
{
    if (hiddenChildren > 0 && !PreferenceController.showHiddenCategories) {
        NSMutableSet *children = [[self mutableSetValueForKey: @"children"] mutableCopy];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isHidden = NO"];
        [children filterUsingPredicate: predicate];
        return children;
    }
    return [self primitiveValueForKey: @"children"];
}

/**
 * Returns a set consisting of this category plus all its children, grand children etc.
 */
-(NSSet*)allCategories
{
    if (self.isHidden && !PreferenceController.showHiddenCategories) {
        return [NSSet set];
    }
    NSMutableSet* result = [[NSMutableSet alloc] init];
    
    for (Category *child in self.children) {
        [result unionSet: [child allCategories]];
    }
    [result addObject: self];
    return result;
}

/**
 * Returns a set consisting of all sibling categories of this one.
 */
- (NSSet*)siblings
{
    Category* parent = self.parent;
    if (parent == nil) {
        return nil;
    }
    NSMutableSet* set = [[parent mutableSetValueForKey: @"children"] mutableCopy];
    [set removeObject: self];
    if (!PreferenceController.showHiddenCategories) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isHidden = NO"];
        [set filterUsingPredicate: predicate];
    }
    return set;
}

/**
 * Returns a set of all assignments displayed in the transaction list for this category.
 * Takes setting "recursiveTransactions" into account, i.e. whether also assignments of sub categories should be displayed.
 */
- (NSMutableSet*)boundAssignments
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *assignments = [self assignmentsFrom: startReportDate to: endReportDate withChildren: [defaults boolForKey: @"recursiveTransactions"]];
    return [NSMutableSet setWithArray: assignments];
}

/**
 * Returns all assignments from this category plus all of those from the children and grand children etc. categories.
 */
- (NSMutableSet*)allAssignments
{
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSSet *allCats = [self allCategories];
    NSMutableSet *result = [[NSMutableSet alloc] init];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"StatCatAssignment" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category in %@", allCats];
    [fetchRequest setPredicate: predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects != nil) {
        [result addObjectsFromArray:fetchedObjects];
    }
    return result;
}

/**
 * Used to get the KVO chain into moving when an assignment in this category changed.
 */
- (void)updateBoundAssignments
{
    [self willChangeValueForKey: @"boundAssignments"];
    [self didChangeValueForKey: @"boundAssignments"];
}

/**
 * Returns the dates of the oldest and newest entry for this category and all its children.
 */
- (void)getDatesMin: (ShortDate **)minDate max: (ShortDate **)maxDate
{
    ShortDate* currentMinDate = [ShortDate currentDate];
    ShortDate* currentMaxDate = [ShortDate currentDate];
    
    // First get the dates from all child categories and then compare them to dates of this one.
    for (Category* category in self.children) {
        ShortDate *localMin, *localMax;
        [category getDatesMin: &localMin max: &localMax];
        if ([localMin compare: currentMinDate] == NSOrderedAscending) {
            currentMinDate = localMin;
        }
        if ([localMax compare: currentMaxDate] == NSOrderedDescending) {
            currentMaxDate = localMax;
        }
    }
    
    NSArray* stats = [[self mutableSetValueForKey: @"assignments"] allObjects];
    NSArray* sortedStats = [stats sortedArrayUsingSelector: @selector(compareDate:)];
    
    if ([sortedStats count] > 0) {
        StatCatAssignment* assignment = sortedStats[0];
        ShortDate* date = [ShortDate dateWithDate: assignment.statement.date];
        if ([date compare: currentMinDate] == NSOrderedAscending) {
            currentMinDate = date;
        }
        assignment = [sortedStats lastObject];
        date = [ShortDate dateWithDate: assignment.statement.date];
        if ([date compare: currentMaxDate] == NSOrderedDescending) {
            currentMaxDate = date;
        }
    }
    *minDate = currentMinDate;
    *maxDate = currentMaxDate;
}

/**
 * Collects a full history of turnover values over time, including all sub categories.
 */
-(NSUInteger)categoryHistoryToDates: (NSArray**)dates
                           balances: (NSArray**)balances
                      balanceCounts: (NSArray**)counts
                       withGrouping: (GroupingInterval)interval
{
    NSArray* statements = [[self allAssignments] allObjects];
    NSArray* sortedAssignments = [statements sortedArrayUsingSelector: @selector(compareDate:)];
    
    NSUInteger count = [statements count];
    NSMutableArray* dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray* balanceArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray* countArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0)
    {
        ShortDate* lastDate = nil;
        int balanceCount = 0;
        NSDecimalNumber* currentValue = [NSDecimalNumber zero];
        for (StatCatAssignment* assignment in sortedAssignments) {
            ShortDate* date = [ShortDate dateWithDate: assignment.statement.date];
            
            switch (interval) {
                case GroupByWeeks:
                    date = [date firstDayInWeek];
                    break;
                case GroupByMonths:
                    date = [date firstDayInMonth];
                    break;
                case GroupByQuarters:
                    date = [date firstDayInQuarter];
                    break;
                case GroupByYears:
                    date = [date firstDayInYear];
                    break;
                default:
                    break;
            }            

            if ((lastDate != nil) && [lastDate compare: date] != NSOrderedSame)
            {
                [dateArray addObject: lastDate];
                [balanceArray addObject: currentValue];
                [countArray addObject: @(balanceCount)];
                balanceCount = 1;
                lastDate = date;
                currentValue = assignment.statement.value;
            }
            else
            {
                if (lastDate == nil) {
                    lastDate = date;
                }
                balanceCount++;
                currentValue = [currentValue decimalNumberByAdding: assignment.statement.value];
            }
        }
        [dateArray addObject: lastDate];
        [balanceArray addObject: currentValue];
        [countArray addObject: @(balanceCount)];
        
        *dates = dateArray;
        *balances = balanceArray;
        *counts = countArray;
    }
    return count;
}

-(BOOL)checkMoveToCategory:(Category*)cat
{
    Category *parent;
    if ([cat isBankAccount]) return NO;
    if (cat == notAssignedRootSingleton) return NO;
    
    // check for cycles
    parent = cat.parent;
    while (parent != nil) {
        if (parent == self) return NO;
        parent = parent.parent;
    }
    return YES;
}

-(NSColor*)categoryColor
{
    // Assign a default color if none has been set so far.
    // Root categories get different dark gray default colors. Others either get one of the predefined
    // colors or a random one if no color is left from the set of predefined colors.
    [self willAccessValueForKey: @"categoryColor"];
    if (self.catRepColor == nil) {
        if (self == [Category bankRoot]) {
            catColor = [NSColor colorWithDeviceWhite: 0.12 alpha: 1];
        } else {
            if (self == [Category catRoot]) {
                catColor = [NSColor colorWithDeviceWhite: 0.24 alpha: 1];
            } else {
                if (self == [Category nassRoot]) {
                    catColor = [NSColor colorWithDeviceWhite: 0.36 alpha: 1];
                } else {
                    if ([self isBankAccount]) {
                        catColor = [NSColor nextDefaultAccountColor];
                    } else {
                        catColor = [NSColor nextDefaultCategoryColor];
                    }
                }
            }
        }
        
        // Archive the just determined color.
        NSMutableData* data = [NSMutableData data];

        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: catColor forKey: @"color"];
        [archiver finishEncoding];
        
        self.catRepColor = data;
    } else {
        if (catColor == nil) {
            NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: self.catRepColor];
            catColor = [unarchiver decodeObjectForKey: @"color"];
            [unarchiver finishDecoding];
        }
    }

    [self didAccessValueForKey: @"categoryColor"];

    return catColor;
}

-(void)setCategoryColor: (NSColor*)color
{
    if (catColor != color) {
        [self willChangeValueForKey: @"categoryColor"];
        catColor = color;
        
        NSMutableData* data = [NSMutableData data];
        
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: catColor forKey: @"color"];
        [archiver finishEncoding];
        
        self.catRepColor = data;
        [self didChangeValueForKey: @"categoryColor"];
    }
}

+(Category*)bankRoot
{
    NSError *error = nil;
    if(bankRootSingleton) return bankRootSingleton;
    
    NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
    NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getBankingRoot"];
    NSArray *cats = [context executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return nil;
    }
    if([cats count ] > 0) return cats[0];
    
    // create Root object
    bankRootSingleton = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
    [bankRootSingleton setValue: @"++bankroot" forKey: @"name" ];
    [bankRootSingleton setValue: @YES forKey: @"isBankAcc" ];
    return bankRootSingleton;
}


+(Category*)catRoot
{
    NSError *error = nil;
    if (catRootSingleton) {
        return catRootSingleton;
    }
    
    NSManagedObjectContext	*context = MOAssistant.assistant.context;
    NSManagedObjectModel	*model   = MOAssistant.assistant.model;
    
    if (context == nil) return nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getCategoryRoot"];
    NSArray *cats = [context executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return nil;
    }
    if ([cats count ] > 0) {
        catRootSingleton = cats[0];
        return cats[0];
    }
    
    // create Category Root object
    catRootSingleton = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
    [catRootSingleton setValue: @"++catroot" forKey: @"name" ];
    [catRootSingleton setValue: @NO forKey: @"isBankAcc" ];
    return catRootSingleton;
}

+(Category*)nassRoot
{
    NSError *error = nil;
    if(notAssignedRootSingleton) return notAssignedRootSingleton;
    
    NSManagedObjectContext	*context = [[MOAssistant assistant ] context];
    NSManagedObjectModel	*model   = [[MOAssistant assistant ] model];
    
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getNassRoot"];
    NSArray *cats = [context executeFetchRequest: request error: &error];
    if( error != nil || cats == nil) {
        return nil;
    }

    if ([cats count ] > 0) {
        notAssignedRootSingleton = cats[0];
    } else {
        Category *notAssignedRootSingleton = [NSEntityDescription insertNewObjectForEntityForName: @"Category"
                                                                           inManagedObjectContext: context];
        [notAssignedRootSingleton setPrimitiveValue: @"++nassroot" forKey: @"name"];
        [notAssignedRootSingleton setValue: @NO forKey: @"isBankAcc"];
        [notAssignedRootSingleton setValue: catRootSingleton forKey: @"parent"];
    }

    return notAssignedRootSingleton;
}

+(void)updateCatValues
{
    if (updateSent) return;
    [[self catRoot ] updateInvalidCategoryValues ];
    [[self catRoot ] rollup ]; 
}

+(void)setCatReportFrom: (ShortDate*)fDate to: (ShortDate*)tDate
{
    if (startReportDate != nil && endReportDate != nil) {
        if ([startReportDate isEqual:fDate] && [endReportDate isEqual:tDate]) {
            return;
        }
    }
    
    startReportDate = fDate;
    endReportDate = tDate;
    [[self catRoot] rebuildValues];
    [[self catRoot] rollup];
    [[self bankRoot] updateReportedAssignments];
}

/**
 * Recreate the 3 implicit root categories. Called when the entire managed context was cleared.
 */
+ (void)recreateRoots
{
    catRootSingleton = nil, [self catRoot];
    bankRootSingleton = nil, [self bankRoot];
    notAssignedRootSingleton = nil, [self nassRoot];
}

/**
 * Creates a set of default categories, which are quite common. These categories are defined in localizable.strings.
 */
+ (void)createDefaultCategories
{
    NSString *sentinel = NSLocalizedString(@"AP300", nil); // Upper limit.
    if (sentinel == nil || sentinel.length == 0) {
        return;
    }

    NSUInteger lower = 250;
    NSUInteger upper = [sentinel intValue];
    if (upper <= lower) {
        return;
    }

    NSUInteger lastLevel = 0;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    Category *current = [Category nassRoot];

    for (NSUInteger i = lower; i <= upper; i++) {
        NSString *key = [NSString stringWithFormat: @"AP%lu", i];
        NSString *entry = NSLocalizedString(key, nil);
        NSArray *values = [entry componentsSeparatedByString: @"|"];
        if (values.count < 1) {
            continue;
        }

        // Count leading plus chars (they determine the nesting level) and remove them.
        NSString *name = values[0];
        NSUInteger level = 0;
        while ([name characterAtIndex: level] == '+') {
            level++;
        }
        if (level > 0) {
            name = [name substringFromIndex: level];
        }

        Category *child = [NSEntityDescription insertNewObjectForEntityForName: @"Category" inManagedObjectContext: context];
        child.name = name;
        if (values.count > 1) {
            child.rule = values[1];
        }
        if (level < lastLevel) {
            // Go up the parent chain as many levels as indicated.
            while (lastLevel > level) {
                current = current.parent;
                lastLevel--;
            }
            child.parent = current.parent;
        } else {
            if (level > lastLevel) {
                // Go down one level (there must never be level increases with more than one step).
                child.parent = current;
                lastLevel++;
            } else {
                // Add new sibling to the current node.
                child.parent = current.parent;
            }
        }
        current = child;
    }

    NSError *error;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

@end
