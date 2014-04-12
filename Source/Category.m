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

#import "NSColor+PecuniaAdditions.h"

static Category *catRootSingleton = nil;
static Category *bankRootSingleton = nil;
static Category *notAssignedRootSingleton = nil;

static ShortDate *startReportDate = nil;
static ShortDate *endReportDate = nil;

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

/** If the balance of a category (sum of assignment values between start and end report date) is not valid
 *  (isBalanceValid) it is recalculated here.
 */
- (void)recomputeInvalidBalances
{
    // Only for categories.
    if (self.isBankAccount) {
        return;
    }

    for (Category *category in self.children) {
        [category recomputeInvalidBalances];
    }

    if (!self.isBalanceValid.boolValue) {
        if (self.reportedAssignments == nil) {
            // The assignment cache was reset, hence it must be filled first.
            // This will also compute the balance.
            [self updateAssignmentsForReportRange];
        } else {
            // The cache is valid, so don't re-create it but just query the assignments needed to
            // compute the current balance.
            NSDecimalNumber *balance = [NSDecimalNumber zero];

            // Fetch all relevant statements.
            NSManagedObjectContext *context = MOAssistant.assistant.context;

            NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName: @"StatCatAssignment" inManagedObjectContext: context];

            [fetchRequest setEntity: entity];
            NSDate *from = startReportDate.lowDate;
            NSDate *to = endReportDate.highDate;

            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category = %@ and statement.date >= %@ and statement.date <= %@", self, from, to];
            [fetchRequest setPredicate: predicate];

            NSError *error = nil;
            NSArray *fetchedObjects = [context executeFetchRequest: fetchRequest error: &error];
            if (fetchedObjects != nil) {
                for (StatCatAssignment *assignment in fetchedObjects) {
                    if (assignment.value != nil) {
                        balance = [balance decimalNumberByAdding: assignment.value];
                    }
                }

                if (fetchedObjects.count > 0) {
                    StatCatAssignment *assignment = fetchedObjects[0];
                    NSString *currency = assignment.statement.currency;
                    if (currency.length > 0) {
                        self.currency = currency;
                    }
                }
            }
            
            self.balance = balance;
            self.isBalanceValid = @YES;
        }
    }
}

/**
 * Recompute all category sums out of their balances and the category sums of their children.
 * Since we are checking for hidden children here we can as well update the hidden children count
 * which helps us to avoid unnecessary filtering (and hence copy operations) for children.
 */
- (void)updateCategorySums
{
    NSDecimalNumber *res = self.balance;
    if (res == nil) {
        res = [NSDecimalNumber zero];
    }
    
    hiddenChildren = 0;
    NSSet *children = [self primitiveValueForKey: @"children"];
    for (Category *category in children) {
        [category updateCategorySums];
        if (!category.noCatRep.boolValue && !category.isHidden.boolValue) {
            res = [res decimalNumberByAdding: category.catSum];
        }
        if (category.isHidden.boolValue) {
            hiddenChildren++;
        }
    }
    self.catSum = res;

    if ([self.children count] > 0) {
        // For now we assume all children have the same currency. We pick one child
        // to update this category's currency.
        NSString *currency = [[children anyObject] currency];
        if (currency.length > 0) {
            self.currency = currency;
        }
    }
}

- (void)invalidateBalance
{
    self.isBalanceValid = @NO;
}

- (void)invalidateCacheIncludeParents: (BOOL)flag recursive: (BOOL)recursive
{
    reportedAssignments = nil;

    if (flag && self.parent != Category.catRoot) {
        [self.parent invalidateCacheIncludeParents: YES recursive: NO];
    }

    if (recursive) {
        for (Category *child in self.children) {
            [child invalidateCacheIncludeParents: NO recursive: YES];
        }
    }
}

// value of expenses, earnings or turnovers for a specified period
- (NSDecimalNumber *)valuesOfType: (CatValueType)type from: (ShortDate *)fromDate to: (ShortDate *)toDate
{
    NSDecimalNumber *result = [NSDecimalNumber zero];

    NSArray *assignments = [self assignmentsFrom: fromDate to: toDate withChildren: YES];
    if ([assignments count] > 0) {
        switch (type) {
            case cat_all:
                for (StatCatAssignment *assignment in assignments) {
                    result = [result decimalNumberByAdding: assignment.value];
                }
                break;

            case cat_earnings:
                for (StatCatAssignment *assignment in assignments) {
                    if ([assignment.value compare: NSDecimalNumber.zero] == NSOrderedDescending) {
                        result = [result decimalNumberByAdding: assignment.value];
                    }
                }
                break;

            case cat_spendings:
                for (StatCatAssignment *assignment in assignments) {
                    if ([assignment.value compare: NSDecimalNumber.zero] == NSOrderedAscending) {
                        result = [result decimalNumberByAdding: assignment.value];
                    }
                }
                break;

            case cat_turnovers: {
                result = [result decimalNumberByAdding: [NSDecimalNumber decimalNumberWithMantissa: assignments.count
                                                                                          exponent: 0
                                                                                        isNegative: NO]];
                break;
            }
        }
    }
    return result;
}

/**
 * Fills date and turnover arrays with turnover counts of the given year (grouped by day) and returns the
 * maximum turnover value found.
 * Note: turnover counts are of type double.
 */
- (NSUInteger)turnoversForYear: (unsigned)year toDates: (NSArray **)dates turnovers: (NSArray **)turnovers recursive: (BOOL)recursive
{
    ShortDate *startDate = [ShortDate dateWithYear: year month: 1 day: 1];
    ShortDate *endDate = [ShortDate dateWithYear: year month: 12 day: 31];

    NSUInteger maxTurnover = 0;

    NSArray *assignments = [self assignmentsFrom: startDate to: endDate withChildren: recursive];
    NSArray *sortedAssignments = [assignments sortedArrayUsingSelector: @selector(compareDate:)];

    NSUInteger     count = assignments.count;
    NSMutableArray *dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray *countArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0) {
        ShortDate *lastDate = nil;
        double    balanceCount = 0;
        for (StatCatAssignment *assignment in sortedAssignments) {
            // Ignore categories that are hidden, except if this is the parent category.
            if (assignment.category != self) {
                if ([assignment.category.isHidden boolValue] || [assignment.category.noCatRep boolValue]) {
                    continue;
                }
            }
            ShortDate *date = [ShortDate dateWithDate: assignment.statement.date];
            if ((lastDate != nil) && [lastDate compare: date] != NSOrderedSame) {
                [dateArray addObject: lastDate];
                [countArray addObject: @(balanceCount)];
                if (balanceCount > maxTurnover) {
                    maxTurnover = balanceCount;
                }
                balanceCount = 1;
                lastDate = date;
            } else {
                if (lastDate == nil) {
                    lastDate = date;
                }
                balanceCount++;
            }
        }
        [dateArray addObject: lastDate];
        [countArray addObject: @(balanceCount)];
        if (balanceCount > maxTurnover) {
            maxTurnover = balanceCount;
        }
        *dates = dateArray;
        *turnovers = countArray;
    }
    return maxTurnover;
}

/**
 * Fills date and values arrays with absolute turnover values of the given year (grouped by day) and returns the
 * maximum absolute value found.
 * Note: turnover values are of type double.
 */
- (double)absoluteValuesForYear: (unsigned)year
                        toDates: (NSArray **)dates
                         values: (NSArray **)values
                      recursive: (BOOL)recursive
{
    ShortDate *startDate = [ShortDate dateWithYear: year month: 1 day: 1];
    ShortDate *endDate = [ShortDate dateWithYear: year month: 12 day: 31];

    double maxSum = 0;

    NSArray *assignments = [self assignmentsFrom: startDate to: endDate withChildren: recursive];
    NSArray *sortedAssignments = [assignments sortedArrayUsingSelector: @selector(compareDate:)];

    NSUInteger     count = assignments.count;
    NSMutableArray *dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0) {
        ShortDate *lastDate = nil;
        double    sum = 0;
        for (StatCatAssignment *assignment in sortedAssignments) {
            // Ignore categories that are hidden, except if this is the parent category.
            if (assignment.category != self) {
                if ([assignment.category.isHidden boolValue] || [assignment.category.noCatRep boolValue]) {
                    continue;
                }
            }
            ShortDate *date = [ShortDate dateWithDate: assignment.statement.date];
            if ((lastDate != nil) && [lastDate compare: date] != NSOrderedSame) {
                [dateArray addObject: lastDate];
                [valuesArray addObject: @(sum)];
                if (sum > maxSum) {
                    maxSum = sum;
                }
                sum = fabs([assignment.value doubleValue]);
                lastDate = date;
            } else {
                if (lastDate == nil) {
                    lastDate = date;
                }
                sum += fabs([assignment.value doubleValue]);
            }
        }
        [dateArray addObject: lastDate];
        [valuesArray addObject: @(sum)];
        if (sum > maxSum) {
            maxSum = sum;
        }
        *dates = dateArray;
        *values = valuesArray;
    }
    return maxSum;
}

/**
 * Fills date and values arrays with turnover amounts of the given year (grouped by day) and returns the
 * maximum turnover value found.
 * Note: turnover values are of type double.
 */
- (HighLowValues)valuesForYear: (unsigned)year
                       toDates: (NSArray **)dates
                        values: (NSArray **)values
                     recursive: (BOOL)recursive
{
    ShortDate *startDate = [ShortDate dateWithYear: year month: 1 day: 1];
    ShortDate *endDate = [ShortDate dateWithYear: year month: 12 day: 31];

    HighLowValues limits = {
        1e100, -1e100
    };                                        // Should this not be enough one day we want a 1% share
                                              // from the user's managed money in Pecunia ;-)

    NSArray *assignments = [self assignmentsFrom: startDate to: endDate withChildren: recursive];
    NSArray *sortedAssignments = [assignments sortedArrayUsingSelector: @selector(compareDate:)];

    NSUInteger     count = assignments.count;
    NSMutableArray *dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0) {
        ShortDate *lastDate = nil;
        double    sum = 0;
        for (StatCatAssignment *assignment in sortedAssignments) {
            // Ignore categories that are hidden, except if this is the parent category.
            if (assignment.category != self) {
                if ([assignment.category.isHidden boolValue] || [assignment.category.noCatRep boolValue]) {
                    continue;
                }
            }
            ShortDate *date = [ShortDate dateWithDate: assignment.statement.date];
            if ((lastDate != nil) && [lastDate compare: date] != NSOrderedSame) {
                [dateArray addObject: lastDate];
                [valuesArray addObject: @(sum)];
                if (sum > limits.high) {
                    limits.high = sum;
                }
                if (sum < limits.low) {
                    limits.low = sum;
                }
                sum = [assignment.value doubleValue];
                lastDate = date;
            } else {
                if (lastDate == nil) {
                    lastDate = date;
                }
                sum += [assignment.value doubleValue];
            }
        }
        [dateArray addObject: lastDate];
        [valuesArray addObject: @(sum)];
        if (sum > limits.high) {
            limits.high = sum;
        }
        if (sum < limits.low) {
            limits.low = sum;
        }
        *dates = dateArray;
        *values = valuesArray;
    }
    return limits;
}

/**
 * Returns all assignments for the specified period.
 * The assignments are cached / retrieved from cache for quicker response if the given range corresponds to the
 * current report range.
 */
- (NSArray *)assignmentsFrom: (ShortDate *)fromDate to: (ShortDate *)toDate withChildren: (BOOL)includeChildren
{
    // Check if we can take the assignments from cache.
    if ([fromDate isEqual: startReportDate] && [toDate isEqual: endReportDate] && self.reportedAssignments != nil) {
        return self.reportedAssignments;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity: 100];

    if (includeChildren) {
        for (Category *category in self.children) {
            [result addObjectsFromArray: [category assignmentsFrom: fromDate to: toDate withChildren: YES]];
        }
    }

    // Fetch all relevant statements.
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"StatCatAssignment" inManagedObjectContext: context];
    
    [fetchRequest setEntity: entity];
    NSDate *from = fromDate.lowDate;
    NSDate *to = toDate.highDate;

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category = %@ and statement.date >= %@ and statement.date <= %@", self, from, to];
    [fetchRequest setPredicate: predicate];

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest: fetchRequest error: &error];
    if (fetchedObjects != nil) {
        [result addObjectsFromArray: fetchedObjects];

        // Update the balance value for this category while we have the filtered assignments at hand and this
        // is not a bank account.
        if (!self.isBankAccount) {
            NSDecimalNumber *balance = NSDecimalNumber.zero;

            for (StatCatAssignment *assignment in fetchedObjects) {
                if (assignment.value != nil) {
                    balance = [balance decimalNumberByAdding: assignment.value];
                } else {
                    assignment.value = NSDecimalNumber.zero;
                }
            }
            self.balance = balance;
        }
    }

    // Cache the assignments if the requested date range is the same as the current report range.
    if ([fromDate isEqual: startReportDate] && [toDate isEqual: endReportDate]) {
        self.reportedAssignments = result;
    }
    return result;
}

/**
 * Recreate the assignments cache for the current reporting period in this category and those of its children.
 */
- (void)updateAssignmentsForReportRange
{
    for (Category *category in self.children) {
        [category updateAssignmentsForReportRange];
    }

    if (reportedAssignments != nil) { // Check this to avoid unnecessary KVO calls.
        self.reportedAssignments = nil;
    }
    [self assignmentsFrom: startReportDate to: endReportDate withChildren: YES];
}

- (NSString *)accountNumber
{
    return nil;
}

- (NSString *)localName
{
    [self willAccessValueForKey: @"name"];
    NSString *n = [self primitiveValueForKey: @"name"];
    [self didAccessValueForKey: @"name"];
    if (self.parent == nil) {
        if ([n isEqualToString: @"++bankroot"]) {
            return NSLocalizedString(@"AP8", nil);
        }
        if ([n isEqualToString: @"++catroot"]) {
            return NSLocalizedString(@"AP9", nil);
        }
    }
    if ([n isEqualToString: @"++nassroot"]) {
        return NSLocalizedString(@"AP12", nil);
    }
    return n;
}

/**
 * Sets the name of this category to the given value. Checks are done to ensure that the overall
 * structure will not be broken.
 */
- (void)setLocalName: (NSString *)name
{
    if (name == nil) {
        return;
    }
    [self willAccessValueForKey: @"name"];
    NSString *n = [self primitiveValueForKey: @"name"];
    [self didAccessValueForKey: @"name"];

    // Check for special node names denoting certain built-in elements and refuse to rename them.
    if (n != nil) {
        // The existing name must have a value for this check to work properly.
        NSRange r = [n rangeOfString: @"++"];
        if (r.location == 0) {
            return;
        }
    }
    // Check also the new name so it doesn't use our special syntax to denote such elements.
    NSRange r = [name rangeOfString: @"++"];
    if (r.location == 0) {
        return;
    }
    [self setValue: name forKey: @"name"];
}

- (BOOL)isRoot
{
    return self.parent == nil;
}

- (BOOL)isBankAccount
{
    return [self.isBankAcc boolValue];
}

- (BOOL)isBankingRoot
{
    if (self.parent == nil) {
        return [self.isBankAcc boolValue];
    }
    return NO;
}

- (BOOL)isEditable
{
    if (self.parent == nil) {
        return NO;
    }
    NSString *n = [self primitiveValueForKey: @"name"];
    if (n != nil) {
        NSRange r = [n rangeOfString: @"++"];
        if (r.location == 0) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isRemoveable
{
    if (self.parent == nil) {
        return NO;
    }
    NSString *n = [self primitiveValueForKey: @"name"];
    if (n != nil) {
        NSRange r = [n rangeOfString: @"++"];
        if (r.location == 0) {
            return NO;
        }
    }
    if ([self.children count] > 0) {
        return NO;
    }
    return [self isMemberOfClass: [Category class]];
}

- (BOOL)isInsertable
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

- (BOOL)isRequestable
{
    if (![self isBankAccount]) {
        return NO;
    }
    return ![BankingController.controller requestRunning];
}

- (BOOL)isNotAssignedCategory
{
    return self == Category.nassRoot;
}

- (id)children
{
    if (hiddenChildren > 0 && !PreferenceController.showHiddenCategories) {
        NSMutableSet *children = [[self mutableSetValueForKey: @"children"] mutableCopy];
        NSPredicate  *predicate = [NSPredicate predicateWithFormat: @"isHidden = NO"];
        [children filterUsingPredicate: predicate];
        return children;
    }
    return [self primitiveValueForKey: @"children"];
}

/**
 * Returns a set consisting of this category plus all its children, grand children etc.
 */
- (NSSet *)allCategories
{
    if (self.isHidden.boolValue && !PreferenceController.showHiddenCategories) {
        return [NSSet set];
    }
    NSMutableSet *result = [[NSMutableSet alloc] init];

    [result addObject: self];
    for (Category *child in self.children) {
        [result unionSet: [child allCategories]];
    }
    return result;
}

/**
 * Returns a set consisting of all sibling categories of this one.
 */
- (NSSet *)siblings
{
    Category *parent = self.parent;
    if (parent == nil) {
        return nil;
    }
    NSMutableSet *set = [[parent mutableSetValueForKey: @"children"] mutableCopy];
    [set removeObject: self];
    if (!PreferenceController.showHiddenCategories) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isHidden = NO"];
        [set filterUsingPredicate: predicate];
    }
    return set;
}

/**
 * Returns all assignments from this category (and subcategories if recursive is YES).
 * The resulting assignments are ordered by the date specified in @order and can be limited to
 * a certain number if @limit is not NSNotFound.
 */
- (NSArray *)allAssignmentsOrderedBy: (CategoryDateOrder)order
                               limit: (NSUInteger)limit
                           recursive: (BOOL)recursive
                           ascending: (BOOL)ascending
{
    NSSet *categories;
    if (recursive) {
        categories = [self allCategories];
    } else {
        categories = [NSSet setWithObject: self];
    }

    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"StatCatAssignment"
                                              inManagedObjectContext: MOAssistant.assistant.context];
    [fetchRequest setEntity: entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category in %@", categories];
    [fetchRequest setPredicate: predicate];

    NSString *key;
    switch (order) {
        case DateOrderValutaDate:
            key = @"statement.valutaDate";
            break;

        case DateOrderDocDate:
            key = @"statement.docDate";
            break;

        default:
            key = @"statement.date";
    }
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key ascending: ascending];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors: sortDescriptors];

    if (limit != NSNotFound) {
        [fetchRequest setFetchLimit: limit];
    }
    
    NSError *error = nil;
    NSArray *fetchedObjects = [MOAssistant.assistant.context executeFetchRequest: fetchRequest
                                                                           error: &error];
    return fetchedObjects;
}

/**
 * Determines the number of assignments for this category effienctly (i.e. without loading any object).
 */
- (NSUInteger)assignmentCountRecursive: (BOOL)recursive
{
    NSSet *categories;
    if (recursive) {
        categories = [self allCategories];
    } else {
        categories = [NSSet setWithObject: self];
    }

    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"StatCatAssignment"
                                              inManagedObjectContext: MOAssistant.assistant.context];
    [request setEntity: entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category in %@", categories];
    [request setPredicate: predicate];

    NSError *error = nil;
    NSUInteger count = [MOAssistant.assistant.context countForFetchRequest: request error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return 0;
    }
    return count;

}

/**
 * Returns the dates of the oldest and newest entry for this category and all its children.
 */
- (void)getDatesMin: (ShortDate **)minDate max: (ShortDate **)maxDate
{
    ShortDate *currentMinDate = [ShortDate currentDate];
    ShortDate *currentMaxDate = [ShortDate currentDate];

    // First get the dates from all child categories and then compare them to dates of this one.
    for (Category *category in self.children) {
        ShortDate *localMin, *localMax;
        [category getDatesMin: &localMin max: &localMax];
        if ([localMin compare: currentMinDate] == NSOrderedAscending) {
            currentMinDate = localMin;
        }
        if ([localMax compare: currentMaxDate] == NSOrderedDescending) {
            currentMaxDate = localMax;
        }
    }
    NSArray *stats = [[self mutableSetValueForKey: @"assignments"] allObjects];
    NSArray *sortedStats = [stats sortedArrayUsingSelector: @selector(compareDate:)];

    if ([sortedStats count] > 0) {
        StatCatAssignment *assignment = sortedStats[0];
        ShortDate         *date = [ShortDate dateWithDate: assignment.statement.date];
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
 * @param sumUp Determines if balances are summed up over the grouping period or if the last value
 *              in that period is returned in the balances array.
 */
- (NSUInteger)historyToDates: (NSArray **)dates
                    balances: (NSArray **)balances
               balanceCounts: (NSArray **)counts
                withGrouping: (GroupingInterval)interval
                       sumUp: (BOOL)sumUp
              recursive: (BOOL)recursive
{
    NSArray *assignments = [self allAssignmentsOrderedBy: DateOrderDate
                                                   limit: NSNotFound
                                               recursive: recursive
                                               ascending: YES];

    NSUInteger     count = assignments.count;
    NSMutableArray *dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray *balanceArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray *countArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0) {
        ShortDate *lastDate = nil;

        if (sumUp) {
            int balanceCount = 1;

            // We have to keep the current balance for each participating account as we have to sum
            // them up on each time point to get the total balance.
            NSMutableDictionary *currentBalances = [NSMutableDictionary dictionaryWithCapacity: 5];
            for (StatCatAssignment *assignment in assignments) {
                // Ignore categories that are hidden, except if this is the parent category.
                if (assignment.category != self) {
                    if ([assignment.category.isHidden boolValue] || [assignment.category.noCatRep boolValue]) {
                        continue;
                    }
                }
                ShortDate *date = [ShortDate dateWithDate: assignment.statement.date];

                switch (interval) {
                    case GroupByWeeks:
                        date = [date lastDayInWeek];
                        break;

                    case GroupByMonths:
                        date = [date lastDayInMonth];
                        break;

                    case GroupByQuarters:
                        date = [date lastDayInQuarter];
                        break;

                    case GroupByYears:
                        date = [date lastDayInYear];
                        break;

                    default:
                        break;
                }

                if (lastDate == nil) {
                    lastDate = date;
                } else {
                    if ([lastDate compare: date] != NSOrderedSame) {
                        [dateArray addObject: lastDate];

                        NSDecimalNumber *totalBalance = [NSDecimalNumber zero];
                        for (NSDecimalNumber *balance in currentBalances.allValues) {
                            totalBalance = [totalBalance decimalNumberByAdding: balance];
                        }
                        [balanceArray addObject: totalBalance];
                        [countArray addObject: @(balanceCount)];
                        balanceCount = 1;
                        lastDate = date;
                    } else {
                        balanceCount++;
                    }
                }
                // Use the category's object id as unique key as Category itself is not suitable.
                currentBalances[assignment.category.objectID] = assignment.statement.saldo;
            }
            if (lastDate != nil) {
                [dateArray addObject: lastDate];

                NSDecimalNumber *totalBalance = [NSDecimalNumber zero];
                for (NSDecimalNumber *balance in currentBalances.allValues) {
                    totalBalance = [totalBalance decimalNumberByAdding: balance];
                }
                [balanceArray addObject: totalBalance];
                [countArray addObject: @(balanceCount)];
            }
        } else {
            int             balanceCount = 0;
            NSDecimalNumber *currentValue = [NSDecimalNumber zero];
            for (StatCatAssignment *assignment in assignments) {
                // Ignore categories that are hidden, except if this is the parent category.
                if (assignment.category != self) {
                    if ([assignment.category.isHidden boolValue] || [assignment.category.noCatRep boolValue]) {
                        continue;
                    }
                }
                ShortDate *date = [ShortDate dateWithDate: assignment.statement.date];

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

                if ((lastDate != nil) && [lastDate compare: date] != NSOrderedSame) {
                    [dateArray addObject: lastDate];
                    [balanceArray addObject: currentValue];
                    [countArray addObject: @(balanceCount)];
                    balanceCount = 1;
                    lastDate = date;
                    currentValue = assignment.value;
                } else {
                    if (lastDate == nil) {
                        lastDate = date;
                    }
                    balanceCount++;
                    currentValue = [currentValue decimalNumberByAdding: assignment.value];
                }
            }
            [dateArray addObject: lastDate];
            [balanceArray addObject: currentValue];
            [countArray addObject: @(balanceCount)];
        }
        *dates = dateArray;
        *balances = balanceArray;
        *counts = countArray;
    }
    return count;
}

- (BOOL)checkMoveToCategory: (Category *)cat
{
    Category *parent;
    if ([cat isBankAccount]) {
        return NO;
    }
    if (cat == notAssignedRootSingleton) {
        return NO;
    }
    // check for cycles
    parent = cat.parent;
    while (parent != nil) {
        if (parent == self) {
            return NO;
        }
        parent = parent.parent;
    }
    return YES;
}

- (NSColor *)categoryColor
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
        NSMutableData *data = [NSMutableData data];

        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: catColor forKey: @"color"];
        [archiver finishEncoding];

        self.catRepColor = data;
    } else {
        if (catColor == nil) {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: self.catRepColor];
            catColor = [unarchiver decodeObjectForKey: @"color"];
            [unarchiver finishDecoding];
        }
    }
    [self didAccessValueForKey: @"categoryColor"];

    return catColor;
}

- (void)setCategoryColor: (NSColor *)color
{
    if (![catColor isEqualTo: color]) {
        [self willChangeValueForKey: @"categoryColor"];
        catColor = color;

        NSMutableData *data = [NSMutableData data];

        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: catColor forKey: @"color"];
        [archiver finishEncoding];

        self.catRepColor = data;
        [self didChangeValueForKey: @"categoryColor"];
    }
}

+ (Category *)bankRoot
{
    NSError *error = nil;
    if (bankRootSingleton) {
        return bankRootSingleton;
    }
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSManagedObjectModel   *model   = [[MOAssistant assistant] model];

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getBankingRoot"];
    NSArray        *cats = [context executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if ([cats count] > 0) {
        bankRootSingleton = cats[0];
    }

    // Create root object if none exists.
    if (bankRootSingleton == nil) {
        bankRootSingleton = [NSEntityDescription insertNewObjectForEntityForName: @"Category" inManagedObjectContext: context];
        [bankRootSingleton setValue: @"++bankroot" forKey: @"name"];
        [bankRootSingleton setValue: @YES forKey: @"isBankAcc"];
    }
    return bankRootSingleton;
}

+ (Category *)catRoot
{
    NSError *error = nil;
    if (catRootSingleton) {
        return catRootSingleton;
    }
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSManagedObjectModel   *model   = MOAssistant.assistant.model;

    if (context == nil) {
        return nil;
    }
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getCategoryRoot"];
    NSArray        *cats = [context executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if ([cats count] > 0) {
        catRootSingleton = cats[0];
        return cats[0];
    }
    // create Category Root object
    catRootSingleton = [NSEntityDescription insertNewObjectForEntityForName: @"Category" inManagedObjectContext: context];
    [catRootSingleton setValue: @"++catroot" forKey: @"name"];
    [catRootSingleton setValue: @NO forKey: @"isBankAcc"];
    return catRootSingleton;
}

+ (Category *)nassRoot
{
    NSError *error = nil;
    if (notAssignedRootSingleton) {
        return notAssignedRootSingleton;
    }
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSManagedObjectModel   *model   = [[MOAssistant assistant] model];

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"getNassRoot"];
    NSArray        *cats = [context executeFetchRequest: request error: &error];
    if (error != nil || cats == nil) {
        return nil;
    }
    if ([cats count] > 0) {
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

+ (Category *)categoryForName: (NSString *)name
{
    if (name.length > 0) {
        NSManagedObjectContext *context = [[MOAssistant assistant] context];
        NSFetchRequest         *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription    *entity = [NSEntityDescription entityForName: @"Category" inManagedObjectContext: context];
        [fetchRequest setEntity: entity];

        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"name = %@", name];
        [fetchRequest setPredicate: predicate];

        NSError *error;
        NSArray *fetchedObjects = [context executeFetchRequest: fetchRequest error: &error];
        if (error == nil && fetchedObjects.count > 0) {
            return fetchedObjects[0];
        }
    }
    return nil;
}

+ (void)updateBalancesAndSums
{
    [[self catRoot] recomputeInvalidBalances];
    [[self catRoot] updateCategorySums];
}

+ (void)setCatReportFrom: (ShortDate *)fDate to: (ShortDate *)tDate
{
    if (fDate == nil) {
        fDate = [ShortDate distantPast];
    }
    if (tDate == nil) {
        tDate = [ShortDate distantFuture];
    }
    if ([startReportDate isEqual: fDate] && [endReportDate isEqual: tDate]) {
        return;
    }

    startReportDate = fDate;
    endReportDate = tDate;

    // Update assignments cache for the new reporting date and recompute all balances/category sums.
    [[self bankRoot] updateAssignmentsForReportRange];
    [[self catRoot] updateAssignmentsForReportRange];
    [[self catRoot] updateCategorySums];
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

+ (void)createCategoryWithName: (NSString *)name
{
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    Category *root = [Category catRoot];
 
    Category *cat = [NSEntityDescription insertNewObjectForEntityForName: @"Category" inManagedObjectContext: context];
    cat.name = name;
    cat.parent = root;
    
    NSError *error;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}


/**
 * Creates a set of default categories, which are quite common. These categories are defined in Localizable.strings.
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
    NSUInteger             lastLevel = 0;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    Category               *current = [Category nassRoot];

    for (NSUInteger i = lower; i <= upper; i++) {
        NSString *key = [NSString stringWithFormat: @"AP%lu", i];
        NSString *entry = NSLocalizedString(key, nil);
        NSArray  *values = [entry componentsSeparatedByString: @"|"];
        if (values.count < 1) {
            continue;
        }
        // Count leading plus chars (they determine the nesting level) and remove them.
        NSString   *name = values[0];
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
