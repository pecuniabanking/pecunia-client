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

#import <Cocoa/Cocoa.h>

NSCalendarDate* normalizeDate(NSDate* date);

typedef enum {
    cat_earnings,
    cat_spendings,
    cat_turnovers,
    cat_all
} CatValueType;

/**
 * Specifies the grouping of values when collecting statistical data, that is, which time frame
 * balance values should be coalesced in.
 */
typedef enum {
    GroupByDays,
    GroupByWeeks,
    GroupByMonths,
    GroupByQuarters,
    GroupByYears
} GroupingInterval;

@class ShortDate;
@class CategoryReportingNode;

@interface Category : NSManagedObject {
    
}

@property (nonatomic, retain) NSString * rule;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isBankAcc;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) Category * parent;
@property (nonatomic, retain) NSString * localName;
@property (nonatomic, retain) NSNumber * isBalanceValid;
@property (nonatomic, retain) NSDecimalNumber * catSum;
@property (nonatomic, retain) NSDecimalNumber * balance;
//@property (nonatomic, retain, readonly) NSString * accountNumber;
@property (nonatomic, retain) NSData * catRepColor;
@property (nonatomic, retain) NSNumber * noCatRep;


//-(NSDecimalNumber*)updateBalance;
-(void)updateInvalidBalances;
-(void)invalidateBalance;
-(NSDecimalNumber*)rollup;
-(void)rebuildValues;

-(NSString*)name;
//-(NSString*)localName;
-(NSString*)accountNumber;
-(BOOL)isRoot;
-(BOOL)isBankAccount;
-(BOOL)isBankingRoot;
-(BOOL)isEditable;
-(BOOL)isRemoveable;
-(BOOL)isInsertable;
-(BOOL)isNotAssignedCategory;
-(BOOL)checkMoveToCategory:(Category*)cat;

-(NSColor*)categoryColor;
-(void)setCategoryColor: (NSColor*)color;

//-(void)setLocalName: (NSString*)name;
-(NSMutableSet*)children;
-(NSSet*)allChildren;
-(NSSet*)siblings;
-(NSUInteger)balanceHistoryToDates: (NSArray**)dates
                          balances: (NSArray**)balances
                     balanceCounts: (NSArray**)counts
                      withGrouping: (GroupingInterval)interval;
-(NSUInteger)categoryHistoryToDates: (NSArray**)dates
                           balances: (NSArray**)balances
                      balanceCounts: (NSArray**)counts
                       withGrouping: (GroupingInterval)interval;
- (void)getDatesMin: (ShortDate**)minDate max: (ShortDate**)maxDate;

-(NSDecimalNumber*)valuesOfType: (CatValueType)type from: (ShortDate*)fromDate to: (ShortDate*)toDate;
-(NSArray*)statementsFrom: (ShortDate*)fromDate to: (ShortDate*)toDate withChildren: (BOOL)c;
-(NSMutableSet*)combinedStatements;

+(Category*)bankRoot;
+(Category*)catRoot;
+(Category*)nassRoot;
+(void)updateCatValues;
+(void)setCatReportFrom: (ShortDate*)fDate to: (ShortDate*)tDate;

@end

// coalesce these into one @interface Category (CoreDataGeneratedAccessors) section
@interface Category (CoreDataGeneratedAccessors)
@end

