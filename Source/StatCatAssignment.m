/**
 * Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
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

#import "MessageLog.h"

#import "StatCatAssignment.h"
#import "BankingCategory.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "BankAccount.h"

#import "ShortDate.h"

@interface StatCatAssignment ()
{
    ShortDate *executionDate;
}

@end

@implementation StatCatAssignment

@dynamic value;
@dynamic statement;

- (ShortDate *)dayOfExecution {
    if (executionDate == nil) {
        executionDate = [ShortDate dateWithDate: self.statement.date];
    }
    return executionDate;
}

- (NSComparisonResult)compareDate: (StatCatAssignment *)stat {
    return [self.statement.date compare: stat.statement.date];
}

- (NSComparisonResult)compareDateReverse: (StatCatAssignment *)stat {
    return [stat.statement.date compare: self.statement.date];
}

- (NSString *)stringForFields: (NSArray *)fields usingDateFormatter: (NSDateFormatter *)dateFormatter numberFormatter: (NSNumberFormatter *)numberFormatter {
    NSMutableString *res = [NSMutableString stringWithCapacity: 300];
    NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
    NSString        *s;
    NSObject        *obj;
    NSString        *sep = [defaults objectForKey: @"exportSeparator"];

    if (sep == nil) {
        sep = @"\t";
    }

    for (NSString *field in fields) {
        if ([field isEqualToString: @"value"]) {
            obj = self.value;
        } else if ([field isEqualToString: @"note"]) {
            obj = self.userInfo == nil?nil:[NSString stringWithFormat: @"\"%@\"", self.userInfo];
        } else if ([field isEqualToString: @"localName"]) {
            obj = self.statement.account.localName;
        } else if ([field isEqualToString: @"localCountry"]) {
            obj = self.statement.account.country;
        } else {
            obj = [self.statement valueForKey: field];
        }

        if (obj) {
            if ([field isEqualToString: @"valutaDate"] || [field isEqualToString: @"date"]) {
                s = [dateFormatter stringFromDate: (NSDate *)obj];
            } else if ([field isEqualToString: @"value"]) {
                s = [numberFormatter stringFromNumber: (NSNumber *)obj];
            } else if ([field isEqualToString: @"categories"]) {
                s = self.statement.categoriesDescription;
            } else {
                s = [obj description];
            }

            if (s) {
                [res appendString: s];
            }
        }
        [res appendString: sep];
    }
    [res appendString: @"\n"];
    return res;
}

- (void)moveAmount: (NSDecimalNumber *)amount toCategory: (BankingCategory *)tcat withInfo: (NSString *)info {
    StatCatAssignment *stat;
    BankingCategory          *scat = self.category;

    if (amount == nil) {
        return;
    }

    if ([amount compare: [NSDecimalNumber zero]] == NSOrderedSame) {
        return;
    }

    if ([[amount abs] compare: [self.value abs]] != NSOrderedAscending) {
        amount = self.value;
    }
    if (tcat == scat) {
        return;
    }

    // check if there is already an entry for the statement in tcat
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSMutableSet           *stats = [self.statement mutableSetValueForKey: @"assignments"];

    // if assignment already done, add value
    BOOL assignmentDone = NO;
    for (stat in stats) {
        if (stat.category == tcat) {
            stat.value = [stat.value decimalNumberByAdding: amount];
            // value must never be higher than statement's value
            if ([[stat.value abs] compare: [stat.statement.value abs]] == NSOrderedDescending) {
                stat.value = stat.statement.value;
                if (info && info.length > 0) {
                    if (stat.userInfo && stat.userInfo.length > 0) {
                        stat.userInfo = [NSString stringWithFormat: @"%@\n%@", stat.userInfo, info];
                    } else {
                        stat.userInfo = info;
                    }
                }
            }
            [stat.statement updateAssigned];
            [scat invalidateBalance];
            [tcat invalidateBalance];

            return;
        }
    }
    // if assignment is not done yet, create it
    if (assignmentDone == NO) {
        stat = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment" inManagedObjectContext: context];
        if (info) {
            stat.userInfo = info;
        } else {
            stat.userInfo = self.userInfo;
        }
        stat.category = tcat;
        stat.statement = self.statement;
        stat.value = amount;
    }

    // adjust self
    self.value = [self.value decimalNumberBySubtracting: amount];
    if ([self.value compare: [NSDecimalNumber zero]] == NSOrderedSame) {
        [context deleteObject: self];
    }

    [context processPendingChanges];

    [scat invalidateBalance];
    [tcat invalidateBalance];
}

- (void)moveToCategory: (BankingCategory *)targetCategory {
    BankingCategory *nassRoot = BankingCategory.nassRoot;
    BankingCategory *sourceCategory = self.category;

    if (targetCategory == sourceCategory) {
        return;
    }

    // Check if there is already an entry for the statement in the target category.
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    NSSet *assignments = [self.statement valueForKey: @"assignments"];

    // If assignment already done, add value.
    for (StatCatAssignment *stat in assignments) {
        if (stat.category == targetCategory) {
            stat.value = [stat.value decimalNumberByAdding: self.value];

            // Value must never be higher than the statement's value.
            if ([[stat.value abs] compare: [stat.statement.value abs]] == NSOrderedDescending) {
                stat.value = stat.statement.value;
            }
            [stat.statement updateAssigned];
            if (self != stat) {
                [context deleteObject: self];
            }
            [sourceCategory invalidateBalance];
            [targetCategory invalidateBalance];
            return;
        }
    }
    self.category = targetCategory;

    [sourceCategory invalidateBalance];
    [targetCategory invalidateBalance];

    if (targetCategory == nassRoot || sourceCategory == nassRoot) {
        [self.statement updateAssigned];
    }
}

/**
 * Removes a single assignment (the receiver) and updates its previously associated bank statement.
 */
- (void)remove {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    BankStatement *stat = self.statement;
    if (stat.account == nil) {
        [context deleteObject: stat];
        stat = nil;
    } else {
        [context deleteObject: self];
    }

    // Important: do changes to the graph since updateAssigned counts on an updated graph.
    [context processPendingChanges];
    if (stat) {
        [stat updateAssigned];
    }
}

/**
 * Efficiently removes a list of assignments and updates their bank statements.
 */
+ (void)removeAssignments: (NSArray *)assignments {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    NSMutableSet *statements = [NSMutableSet set]; // Automatically removes duplicates.

    for (StatCatAssignment *assignment in assignments) {
        if (assignment.statement.account == nil) {
            [context deleteObject: assignment.statement];
        } else {
            [statements addObject: assignment.statement];
            [context deleteObject: assignment];
        }
    }
    // Important: do changes to the graph since updateAssigned counts on an updated graph.
    [context processPendingChanges];
    for (BankStatement *statement in statements) {
        [statement updateAssigned];
    }
}

- (id)valueForUndefinedKey: (NSString *)key {
    LogError(@"StatCatAssignment, ungültiger Schlüssel: %@", key);
    return [self.statement valueForKey: key];
}

- (BankingCategory *)category {
    [self willAccessValueForKey: @"category"];
    BankingCategory *result = [self primitiveCategory];
    [self didAccessValueForKey: @"category"];
    return result;
}

- (void)setCategory: (BankingCategory *)value {
    if ([self primitiveCategory] != value) {
        [[self primitiveCategory] invalidateBalance];
        [[self primitiveCategory] invalidateCacheIncludeParents: YES recursive: NO];
        [self willChangeValueForKey: @"category"];
        [self setPrimitiveCategory: value];
        [self didChangeValueForKey: @"category"];
        [value invalidateBalance];
        [value invalidateCacheIncludeParents: YES recursive: NO];
    }
}

- (NSString *)userInfo {
    id tmpObject;

    [self willAccessValueForKey: @"userInfo"];
    tmpObject = [self primitiveValueForKey: @"userInfo"];
    [self didAccessValueForKey: @"userInfo"];

    return tmpObject;
}

- (void)setUserInfo: (NSString *)info {
    NSString *oldInfo = self.userInfo;
    if (![oldInfo isEqualToString: info]) {
        [self willChangeValueForKey: @"userInfo"];
        [self setPrimitiveValue: info forKey: @"userInfo"];
        [self didChangeValueForKey: @"userInfo"];
        if ([self.category isBankAccount]) {
            BankStatement *statement = self.statement;
            // also set in all categories
            NSSet *stats = [statement mutableSetValueForKey: @"assignments"];
            for (StatCatAssignment *stat in stats) {
                if (stat != self && (stat.userInfo == nil || [stat.userInfo isEqualToString: @""] || [stat.userInfo isEqualToString: oldInfo])) {
                    stat.userInfo = info;
                }
            }
        }
    }
}

- (BOOL)validateCategory: (id *)valueRef error: (NSError **)outError {
    // Insert custom validation logic here.
    return YES;
}

@end
