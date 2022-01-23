/**
 * Copyright (c) 2007, 2015, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, CatValueType) {
    cat_earnings,
    cat_spendings,
    cat_turnovers,
    cat_all
};

/**
 * Specifies the grouping of values when collecting statistical data, that is, which time frame
 * balance values should be coalesced in.
 */
typedef NS_ENUM(NSUInteger, GroupingInterval) {
    GroupByDays,
    GroupByWeeks,
    GroupByMonths,
    GroupByQuarters,
    GroupByYears
};

/**
 * Specifies the date to use for ordering statements in a category.
 */
typedef NS_ENUM(NSUInteger, CategoryDateOrder) {
    DateOrderDate,
    DateOrderValutaDate,
    DateOrderDocDate
};

typedef struct {
    double low;
    double high;
} HighLowValues;

@class ShortDate;
@class CategoryReportingNode;
@class StatCatAssignment;

@interface BankingCategory : NSManagedObject {
@private
    NSColor    *catColor;
    NSUInteger hiddenChildren; // Keep track of hidden child count to optimize handling.
}

@property (nonatomic, strong) NSString        *rule;
@property (nonatomic, strong) NSString        *name;
@property (nonatomic, strong) NSNumber        *isBankAcc;
@property (nonatomic, strong) NSString        *currency;
@property (nonatomic, strong) BankingCategory *parent;
@property (nonatomic, strong) NSString        *localName;
@property (nonatomic, strong) NSNumber        *isBalanceValid;
@property (nonatomic, strong) NSDecimalNumber *catSum;
@property (nonatomic, strong) NSDecimalNumber *balance;
@property (nonatomic, strong) NSData          *catRepColor;
@property (nonatomic, strong) NSNumber        *noCatRep;
@property (nonatomic) NSString                *iconName;
@property (nonatomic, strong) NSNumber        *isHidden;

@property (nonatomic, strong) NSColor *categoryColor; // Unarchived catRepColor.
@property (nonatomic, strong) NSArray *reportedAssignments; // assignments between start and end report date

- (void)recomputeInvalidBalances;
- (void)invalidateBalance;
- (void)updateCategorySums;

// Cache handling.
- (void)invalidateCacheIncludeParents: (BOOL)flag recursive: (BOOL)recursive;
- (void)updateAssignmentsForReportRange;

- (NSString *)accountNumber;
- (BOOL)isRoot;
- (BOOL)isBankAccount;
- (BOOL)isBankingRoot;
- (BOOL)isEditable;
- (BOOL)isRemoveable;
- (BOOL)isInsertable;
- (BOOL)isNotAssignedCategory;
- (BOOL)isCategoryRoot;
- (BOOL)checkMoveToCategory: (BankingCategory *)cat;
- (BOOL)canSynchronize;
- (BOOL)isDepotAccount;

- (NSDecimalNumber *)budgetForPeriod:(NSNumber *)period;

- (id)children;
- (NSSet *)allCategories;
- (NSSet *)siblings;
- (NSUInteger)historyToDates: (NSArray **)dates
                    balances: (NSArray **)balances
               balanceCounts: (NSArray **)counts
                withGrouping: (GroupingInterval)interval
                       sumUp: (BOOL)sumUp
                   recursive: (BOOL)recursive;
- (void)getDatesMin: (ShortDate **)minDate max: (ShortDate **)maxDate;

- (NSDecimalNumber *)valuesOfType: (CatValueType)type from: (ShortDate *)fromDate to: (ShortDate *)toDate;
- (NSUInteger)turnoversForYear: (unsigned)year
                       toDates: (NSArray **)dates
                     turnovers: (NSArray **)turnovers
                     recursive: (BOOL)recursive;
- (double)absoluteValuesForYear: (unsigned)year
                        toDates: (NSArray **)dates
                         values: (NSArray **)values
                      recursive: (BOOL)recursive;
- (HighLowValues)valuesForYear: (unsigned)year
                       toDates: (NSArray **)dates
                        values: (NSArray **)values
                     recursive: (BOOL)recursive;

- (NSArray *)assignmentsFrom: (ShortDate *)fromDate to: (ShortDate *)toDate withChildren: (BOOL)c;
- (NSArray *)allAssignmentsOrderedBy: (CategoryDateOrder)order
                               limit: (NSUInteger)limit
                           recursive: (BOOL)recursive
                           ascending: (BOOL)ascending;
- (NSUInteger)assignmentCountRecursive: (BOOL)recursive;

+ (BankingCategory *)bankRoot;
+ (BankingCategory *)catRoot;
+ (BankingCategory *)nassRoot;
+ (BankingCategory *)categoryForName: (NSString *)name;
+ (void)updateBalancesAndSums;
+ (void)setCatReportFrom: (ShortDate *)fDate to: (ShortDate *)tDate;
+ (void)recreateRoots;
+ (void)createDefaultCategories;
+ (void)createCategoryWithName: (NSString *)name;

@end
