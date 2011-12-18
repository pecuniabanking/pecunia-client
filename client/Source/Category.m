//
//  Category.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "Category.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "ShortDate.h"
#import "BankingController.h"
#import "StatCatAssignment.h"
#import "CategoryReportingNode.h"

#import "GraphicsAdditions.h"

Category *catRoot = nil;
Category *bankRoot = nil;
Category *nassRoot = nil;

ShortDate *catFromDate = nil;
ShortDate *catToDate = nil;
BOOL	updateSent = NO;

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



-(void)updateInvalidBalances
{
    NSArray *stats;
    int     i;
    NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
    if([childs count ] > 0) {
        // first handle children
        NSEnumerator *enumerator = [childs objectEnumerator];
        Category	 *cat;
        
        while ((cat = [enumerator nextObject])) {
            [cat updateInvalidBalances ];
        }
    }
    // now handle self
    if([self.isBalanceValid boolValue ] == NO) {
        NSDecimalNumber	*balance = [NSDecimalNumber zero ];
        
        if([self isBankAccount ]) stats = [[self mutableSetValueForKey: @"assignments" ] allObjects ];
        else stats = [self statementsFrom: catFromDate to: catToDate withChildren: NO ];
        
        StatCatAssignment *stat = nil;
        for(i=0; i<[stats count ]; i++) {
            stat = [stats objectAtIndex:i ];
            balance = [balance decimalNumberByAdding: stat.value ];
        }
        if(stat) {
            NSString *curr = stat.statement.currency;
            if(curr != nil && [curr length ] > 0) self.currency = curr;
        }
        self.balance = balance;
        self.isBalanceValid = [NSNumber numberWithBool: YES ];
    }
}

-(void)rebuildValues
{
    NSArray *stats;
    NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
    if([childs count ] > 0) {
        // first handle children
        NSEnumerator *enumerator = [childs objectEnumerator];
        Category	 *cat;
        
        while ((cat = [enumerator nextObject])) {
            [cat rebuildValues ];
        }
    }
    // now handle self
    NSDecimalNumber	*balance = [NSDecimalNumber zero ];
    
    if([self isBankAccount ]) stats = [[self mutableSetValueForKey: @"assignments" ] allObjects ];
    else stats = [self statementsFrom: catFromDate to: catToDate withChildren: NO ];
    
    for(StatCatAssignment *stat in stats) {
        if(stat.value != nil) balance = [balance decimalNumberByAdding: stat.value]; else stat.value = [NSDecimalNumber zero ];
    }
    self.balance = balance;
}

-(NSMutableSet*)combinedStatements
{
    if(![self isBankAccount ]) return [self mutableSetValueForKey: @"assignments" ];
    if(self.accountNumber) return [self mutableSetValueForKey: @"assignments" ];
    // combine statements
    NSMutableSet *stats = [[[NSMutableSet alloc ] init ] autorelease ];
    NSSet *childs = [self allChildren ];
    NSEnumerator *enumerator = [childs objectEnumerator];
    Category *cat;
    while (cat = [enumerator nextObject]) [stats unionSet: [cat mutableSetValueForKey: @"assignments" ] ];
    return stats;
}

-(NSDecimalNumber*)rollup
{
    NSDecimalNumber *res;
    Category		*cat, *cat_old = nil;
    
    NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
    NSEnumerator *enumerator = [childs objectEnumerator];
    res = self.balance;
    while ((cat = [enumerator nextObject])) { res = [res decimalNumberByAdding: [cat rollup ] ]; cat_old = cat; }
    self.catSum = res;
    if(cat_old) {
        NSString *curr = cat_old.currency;
        if(curr != nil && [curr length ] > 0) self.currency = curr;
    }
    // reset update flag
    updateSent = NO;
    return res;
}

-(void)invalidateBalance
{
    self.isBalanceValid = [NSNumber numberWithBool: NO ];
}


-(NSDecimalNumber*)valuesOfType: (CatValueType)type from: (ShortDate*)fromDate to: (ShortDate*)toDate
{
    NSDecimalNumber* result = [NSDecimalNumber zero];
    NSMutableSet* stats = [self mutableSetValueForKey: @"assignments"];
    NSMutableSet* childs = [self mutableSetValueForKey: @"children"];
    
    if ([childs count] > 0)
    {
        // first handle children
        NSEnumerator *enumerator = [childs objectEnumerator];
        Category	 *cat;
        
        while ((cat = [enumerator nextObject])) {
            result = [result decimalNumberByAdding: [cat valuesOfType: type from: fromDate to: toDate]];
        }
    }
    
    if ([stats count] > 0)
    {
        NSDecimalNumber* zero = [NSDecimalNumber zero];
        NSEnumerator* enumerator = [stats objectEnumerator];
        StatCatAssignment* stat;
        
        switch (type)
        {
            case cat_all:
                while ((stat = [enumerator nextObject]))
                {
                    ShortDate* date = [ShortDate dateWithDate: stat.statement.date];
                    if ([date isBetween: fromDate and: toDate])
                        result = [result decimalNumberByAdding: stat.value];
                }
                break;
            case cat_earnings:
                while ((stat = [enumerator nextObject]))
                {
                    ShortDate* date = [ShortDate dateWithDate: stat.statement.date];
                    if ([date isBetween: fromDate and: toDate] && ([stat.value compare: zero] == NSOrderedDescending))
                        result = [result decimalNumberByAdding: stat.value];
                }
                break;
            case cat_spendings:
                while ((stat = [enumerator nextObject]))
                {
                    ShortDate* date = [ShortDate dateWithDate: stat.statement.date];
                    if ([date isBetween: fromDate and: toDate] && ([stat.value compare: zero] == NSOrderedAscending))
                        result = [result decimalNumberByAdding: stat.value];
                }
                break;
            case cat_turnovers:
            {
                int turnovers = 0;
                while ((stat = [enumerator nextObject]))
                {
                    ShortDate* date = [ShortDate dateWithDate: stat.statement.date];
                    if ([date isBetween: fromDate and: toDate])
                        turnovers++;
                }
                result = [result decimalNumberByAdding: [NSDecimalNumber decimalNumberWithMantissa: turnovers
                                                                                          exponent: 0
                                                                                        isNegative: NO]];
                break;
            }
        }
    }
    return result;
}

-(NSArray*)statementsFrom: (ShortDate*)fromDate to: (ShortDate*)toDate withChildren: (BOOL)c
{
    NSMutableArray	*result = [NSMutableArray arrayWithCapacity: 100 ];
    
    NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
    NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
    
    if(c == YES && [childs count ] > 0) {
        // first handle children
        NSEnumerator *enumerator = [childs objectEnumerator];
        Category	 *cat;
        
        while ((cat = [enumerator nextObject])) {
            [result addObjectsFromArray: [cat statementsFrom: fromDate to: toDate withChildren: YES ] ];
        }
    }
    
    if([stats count ] > 0) {
        NSEnumerator *enumerator = [stats objectEnumerator ];
        StatCatAssignment *stat;
        while ((stat = [enumerator nextObject])) {
            ShortDate *date = [ShortDate dateWithDate: stat.statement.date ];
            if(![date isBetween: fromDate and: toDate ]) continue;
            [result addObject: stat ];
        }
    }
    return result;	
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
    NSSet* myChildren = [self mutableSetValueForKey: @"children" ];
    if([myChildren count ] > 0) return NO;
    return [self isMemberOfClass: [Category class ] ];
}

-(BOOL)isInsertable
{
    if( [self.isBankAcc boolValue ] == YES) return NO;
    //	if( [self valueForKey: @"parent" ] == nil ) return NO;
    NSString *n = [self primitiveValueForKey:@"name"];
    if([n isEqual: @"++nassroot" ]) return NO;
    return TRUE;
}

-(BOOL)isRequestable
{
    if(![self isBankAccount ]) return NO;
    if([[BankingController controller ] requestRunning ]) return NO; else return YES;
}

-(BOOL)isNotAssignedCategory
{
    return self == [Category nassRoot ];
}

-(NSMutableSet*)children
{
    return [self mutableSetValueForKey: @"children" ];
}


-(NSSet*)allChildren
{
    NSMutableSet* childs = [[[NSMutableSet alloc ] init ] autorelease ];
    
    NSSet* myChildren = [self children ];
    NSEnumerator *enumerator = [myChildren objectEnumerator];
    Category	 *cx;
    
    while ((cx = [enumerator nextObject])) {
        NSSet* sub = [cx allChildren ];
        [childs unionSet: sub ];
    }
    [childs addObject: self ];
    return childs;
}

-(NSSet*)siblings
{
    Category* parent = self.parent;
    if(parent == nil) return nil;
    NSMutableSet* set = [NSMutableSet setWithSet: [parent mutableSetValueForKey: @"children" ] ];
    [set removeObject: self ];
    return set;
}

/**
 * Collects a history of the saldo movement for this category over time.
 * This is usually only meaningful for bank accounts.
 * The resulting arrays are sorted by ascending date.
 */
-(NSUInteger)balanceHistoryToDates: (NSArray**)dates
                          balances: (NSArray**)balances
                     balanceCounts: (NSArray**)counts
                      withGrouping: (GroupingInterval)interval
{
    int i;
    NSArray* stats = [[self mutableSetValueForKey: @"assignments"] allObjects];
    NSArray* sortedStats = [stats sortedArrayUsingSelector: @selector(compareDate:)];
    
    NSUInteger count = [stats count];
    NSMutableArray* dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray* balanceArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray* countArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0)
    {
        ShortDate* lastDate = nil;
        int balanceCount = 1;
        NSDecimalNumber* lastSaldo;
        for (i = 0; i < [stats count]; i++)
        {
            StatCatAssignment* assignment = [sortedStats objectAtIndex: i];
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

            if (lastDate == nil) {
                lastDate = date;
            } else {
                if ([lastDate compare: date] != NSOrderedSame)
                {
                    [dateArray addObject: lastDate];
                    [balanceArray addObject: lastSaldo];
                    [countArray addObject: [NSNumber numberWithInt: balanceCount]];
                    balanceCount = 1;
                    lastDate = date;
                }
                else
                {
                    balanceCount++;
                }
            }                
            lastSaldo = assignment.statement.saldo;
        }
        [dateArray addObject: lastDate];
        [balanceArray addObject: lastSaldo];
        [countArray addObject: [NSNumber numberWithInt: balanceCount]];
        
        *dates = dateArray;
        *balances = balanceArray;
        *counts = countArray;
    }
    
    return count;
}

/**
 * Collects a coalesced history of turnover values over time, including all sub categories.
 */
-(CategoryReportingNode*)categoryHistoryWithType:(CatHistoryType)histType
{
    CategoryReportingNode *node = [[CategoryReportingNode alloc ] init ];
    node.name = self.localName;
    node.category = self;
    
    NSMutableSet* stats = [self mutableSetValueForKey: @"assignments" ];
    NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
    
    for(Category *cat in childs) {
        CategoryReportingNode *childNode = [cat categoryHistoryWithType:histType ];
        for(ShortDate *key in [childNode.values allKeys ]) {
            NSDecimalNumber *value = [node.values objectForKey:key ];
            if (value != nil) {
                value = [value decimalNumberByAdding:[childNode.values objectForKey:key ] ];
            } else value = [childNode.values objectForKey:key ];
            [node.values setObject:value forKey:key ];
            [node.children addObject:childNode ];
        }
    }
    
    for(StatCatAssignment *stat in stats) {
        ShortDate *date = [ShortDate dateWithDate: stat.statement.date ];
        ShortDate *newDate;
        switch (histType) {
            case cat_histtype_year: newDate = [date firstDayInYear ]; break;
            case cat_histtype_quarter: newDate = [date firstDayInQuarter ]; break;
            case cat_histtype_month: newDate = [date firstDayInMonth ]; break;
            default: newDate = [date firstDayInMonth ]; break;
        }
        NSDecimalNumber *value = [node.values objectForKey:newDate ];
        if (value != nil) {
            value = [value decimalNumberByAdding: stat.value ];
        } else value = stat.value;
        [node.values setObject:value forKey:newDate ];
    }
    
    return [node autorelease ];	
}

/**
 * Returns a list of all statements for this category, including sub categories.
 */
-(NSSet*)allStatements
{
    NSMutableSet* result = [NSMutableSet setWithSet: [self mutableSetValueForKey: @"assignments" ]];
    NSMutableSet* childs = [self mutableSetValueForKey: @"children" ];
    
    if ([childs count] > 0)
    {
        NSEnumerator* enumerator = [childs objectEnumerator];
        Category* child;
        
        while ((child = [enumerator nextObject]))
        {
            [result unionSet: [child allStatements]];
        }
    }
    
    return result;	
}


/**
 * Collects a full history of turnover values over time, including all sub categories.
 */
-(NSUInteger)categoryHistoryToDates: (NSArray**)dates
                           balances: (NSArray**)balances
                      balanceCounts: (NSArray**)counts
                       withGrouping: (GroupingInterval)interval
{
    int i;
    NSArray* stats = [[self allStatements] allObjects];
    NSArray* sortedStats = [stats sortedArrayUsingSelector: @selector(compareDate:)];
    
    NSUInteger count = [stats count];
    NSMutableArray* dateArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray* balanceArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableArray* countArray = [NSMutableArray arrayWithCapacity: count];
    if (count > 0)
    {
        ShortDate* lastDate = nil;
        int balanceCount = 0;
        NSDecimalNumber* currentValue = [NSDecimalNumber zero];
        for (i = 0; i < [sortedStats count]; i++)
        {
            StatCatAssignment* assignment = [sortedStats objectAtIndex: i];
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
                [countArray addObject: [NSNumber numberWithInt: balanceCount]];
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
        [countArray addObject: [NSNumber numberWithInt: balanceCount]];
        
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
    if (cat == nassRoot) return NO;
    
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
    if (self.catRepColor == nil) {
        NSColor* color;
        if (self == bankRoot) {
            color = [NSColor colorWithDeviceWhite: 0.12 alpha: 1];
        } else {
            if (self == catRoot) {
                color = [NSColor colorWithDeviceWhite: 0.24 alpha: 1];
            } else {
                if (self == nassRoot) {
                    color = [NSColor colorWithDeviceWhite: 0.36 alpha: 1];
                } else {
                    if ([self isBankAccount]) {
                        color = [NSColor nextDefaultAccountColor];
                    } else {
                        color = [NSColor nextDefaultCategoryColor];
                    }
                }
            }
        }
        self.catRepColor = [NSArchiver archivedDataWithRootObject: color];
    }
    
    return [NSUnarchiver unarchiveObjectWithData: self.catRepColor];
}

-(void)setCategoryColor: (NSColor*)color
{
    self.catRepColor = [NSArchiver archivedDataWithRootObject: color];
}

+(Category*)bankRoot
{
    NSError *error = nil;
    if(bankRoot) return bankRoot;
    
    NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
    NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getBankingRoot"];
    NSArray *cats = [context executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return nil;
    }
    if([cats count ] > 0) return [cats objectAtIndex: 0 ];
    
    // create Root object
    bankRoot = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
    [bankRoot setValue: @"++bankroot" forKey: @"name" ];
    [bankRoot setValue: [NSNumber numberWithBool: YES ] forKey: @"isBankAcc" ];
    return bankRoot;
}


+(Category*)catRoot
{
    NSError *error = nil;
    if(catRoot) return catRoot;
    
    NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
    NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
    
    if (context == nil) return nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getCategoryRoot"];
    NSArray *cats = [context executeFetchRequest:request error:&error];
    if( error != nil || cats == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return nil;
    }
    if([cats count ] > 0) return [cats objectAtIndex: 0 ];
    
    // create Category Root object
    catRoot = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
    [catRoot setValue: @"++catroot" forKey: @"name" ];
    [catRoot setValue: [NSNumber numberWithBool: NO ] forKey: @"isBankAcc" ];
    return catRoot;
}

+(Category*)nassRoot
{
    NSError *error = nil;
    if(nassRoot) return nassRoot;
    
    NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
    NSManagedObjectModel	*model   = [[MOAssistant assistant ] model ];
    
    NSFetchRequest *request = [model fetchRequestTemplateForName:@"getNassRoot"];
    NSArray *cats = [context executeFetchRequest:request error:&error];
    if( error != nil || cats == nil || [cats count ] == 0) return nil;
    nassRoot = [cats objectAtIndex: 0 ];
    return nassRoot;
}

+(void)updateCatValues
{
    if (updateSent) return;
    [[self catRoot ] updateInvalidBalances ]; 
    [[self catRoot ] rollup ]; 
    //	[[self catRoot ] performSelector:@selector(updateInvalidBalances) withObject:nil afterDelay:0 ]; 
    //	[[self catRoot ] performSelector:@selector(rollup) withObject:nil afterDelay:0 ]; 
}

+(void)setCatReportFrom: (ShortDate*)fDate to: (ShortDate*)tDate
{
    [catFromDate release ];
    [catToDate release ];
    catFromDate = [fDate retain ];
    catToDate = [tDate retain ];
}

+(void)setMonthFromDate: (ShortDate*)date
{
    [catFromDate release ];
    catFromDate = [ShortDate dateWithYear: [date year ] month: [date month ] day: 1 ];
    [catFromDate retain ];
}

+(void)setYearFromDate: (ShortDate*)date
{
    [catFromDate release ];
    catFromDate = [ShortDate dateWithYear: [date year ] month: 1 day: 1 ];
    [catFromDate retain ];
}

+(void)setQuarterFromDate: (ShortDate*)date
{
    int month;
    [catFromDate release ];
    switch([date month ]) {
        case 1:
        case 2:
        case 3: month = 1; break;
        case 4:
        case 5:
        case 6: month = 4; break;
        case 7:
        case 8:
        case 9: month = 7; break;
        case 10:
        case 11:
        case 12: month = 10; break;
    }
    catFromDate = [ShortDate dateWithYear: [date year ] month: month day: 1 ];
    [catFromDate retain ];
}

@end
