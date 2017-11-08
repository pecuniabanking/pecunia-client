//
//  BudgetWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 14.06.17.
//  Copyright © 2017 Frank Emminghaus. All rights reserved.
//

#import "BudgetWindowController.h"
#import "BankingCategory.h"
#import "CategoryBudget.h"
#import "MOAssistant.h"
#import "ShortDate.h"
#import "BankStatement.h"
#import "StatCatAssignment.h"
#import "PreferenceController.h"
#import "LocalSettingsController.h"
#import "NSOutlineView+PecuniaAdditions.h"

@interface BudgetWindowController ()

@end

@implementation BudgetWindowController

-(void)awakeFromNib {
    /*
    // create Dictionary out of Category hierarchy
    BankingCategory *catRoot = [BankingCategory catRoot];
    if (catRoot == nil) {
        return;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    [self addCategory:catRoot toDict:dict];
    self.budgetData = dict[@"children"];
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
    [self.budgetContainer setSortDescriptors: @[sd]];

    // get year from current date
    NSDate *date = [NSDate date];
    year = [date year];
    [self updateYear];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidEndEditing:) name:NSControlTextDidEndEditingNotification object:nil];
     */
}

- (void)loadWindow {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    LocalSettingsController *lsc = LocalSettingsController.sharedSettings;

    [super loadWindow];

    self.tolerance = [lsc objectForKeyedSubscript:@"BudgetTolerance"];
    
    // create Dictionary out of Category hierarchy
    BankingCategory *catRoot = [BankingCategory catRoot];
    if (catRoot == nil) {
        return;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    // get year from current date
    NSDate *date = [NSDate date];
    year = [date year];
    self.period = [NSNumber numberWithInteger:year * 100 + 1];

    [self addCategory:catRoot toDict:dict];
    
    if ([defaults boolForKey:@"hideBudgetless"] == YES) {
        NSMutableArray *newData = [[NSMutableArray alloc] init];
        for (NSDictionary *cdict in dict[@"children"]) {
            if ([self hasBudget:cdict[@"cat"]]) {
                [newData addObject:cdict];
            }
        }
        self.budgetData = newData;
    } else {
        self.budgetData = dict[@"children"];
    }

    [self addRowSum];
    
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"id" ascending: YES];
    [self.budgetContainer setSortDescriptors: @[sd]];
    
    // get year from current date
    [self updateYear];
    
    self.lightRed = [NSColor colorWithCalibratedRed:1.0 green:0.6 blue:0.6 alpha:1.0];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidEndEditing:) name:NSControlTextDidEndEditingNotification object:nil];
    [self addObserver:self forKeyPath:@"tolerance" options:0 context:nil];
    
    NSArray *columns = [self.budgetView tableColumns];
    for (NSTableColumn *tc in columns) {
        NSTextFieldCell *cell = [tc dataCell];
        [cell setFont: [PreferenceController mainFontOfSize:13 bold:NO]];
    }
    
    [self.budgetView restoreState];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"tolerance"]) {
        //[self.budgetView reloadData];
        [self.budgetView setNeedsDisplay:YES];
    }
}

- (IBAction)hideBudgetless:(id)sender {
    BankingCategory *catRoot = [BankingCategory catRoot];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self saveBudget];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [self addCategory:catRoot toDict:dict];
    
    if ([defaults boolForKey:@"hideBudgetless"] == YES) {
        NSMutableArray *newData = [[NSMutableArray alloc] init];
        for (NSDictionary *cdict in dict[@"children"]) {
            if ([self hasBudget:cdict[@"cat"]]) {
                [newData addObject:cdict];
            }
        }
        self.budgetData = newData;
    } else {
        self.budgetData = dict[@"children"];
    }
    
    [self addRowSum];
    [self updateYear];
}


- (void)addRowSum {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"name"] = @"Summe";
    dict[@"id"] = @"zzSumme";
    [self.budgetContainer addObject:dict];
}

- (NSDecimalNumber *)effectiveBudgetForCat:(BankingCategory *)cat {
    // if category has budget on its own, return this instead sum of children's
    NSDecimalNumber *budget = [cat budgetForPeriod:self.period];
    
    if (budget != nil) {
        return budget;
    }
    
    // no own budget - return sum of children's effective budget
    NSSet *children = [cat mutableSetValueForKey:@"children"];
    if (children != nil && children.count > 0) {
        for (BankingCategory *child in children) {
            NSDecimalNumber *childBudget = [self effectiveBudgetForCat:child];
            if (childBudget != nil) {
                if (budget == nil) {
                    budget = childBudget;
                } else {
                    budget = [budget decimalNumberByAdding:childBudget];
                }
            }
        }
    }
    return budget;
}

- (NSDecimalNumber *)effectiveDeltaForNode:(NSDictionary *)dict {
    // if node has delta, return this, otherwise the sum of the children's effective Delta
    NSDecimalNumber *delta = dict[@"delta"];
    if (delta != nil) {
        return delta;
    }
    
    NSArray *children = dict[@"children"];
    if (children != nil && children.count > 0) {
        for (NSDictionary *child in children) {
            NSDecimalNumber *childDelta = [self effectiveDeltaForNode:child];
            if (childDelta != nil) {
                if (delta == nil) {
                    delta = childDelta;
                } else {
                    delta = [delta decimalNumberByAdding:childDelta];
                }
            }
        }
    }
    return delta;
}

// update values in sum row
- (void)updateRowSum {
    NSDecimalNumber *sum = [NSDecimalNumber zero];
    NSMutableDictionary *sumDict = nil;
    for (NSMutableDictionary *dict in self.budgetData) {
        if ([dict[@"id"] isEqualToString: @"zzSumme"]) {
            sumDict = dict;
            continue;
        }
        NSDecimalNumber *value = [self effectiveBudgetForCat: dict[@"cat"]];
        if (value != nil) {
            sum = [value decimalNumberByAdding:sum];
        }
    }
    sumDict[@"value"] = sum;
 
    for (int i=1; i<=12; i++) {
        sum = [NSDecimalNumber zero];
        for (NSMutableDictionary *dict in self.budgetData) {
            if (dict == sumDict) {
                continue;
            }
            NSDecimalNumber *value = dict[[NSString stringWithFormat:@"%d", i ]];
            if (value != nil) {
                sum = [value decimalNumberByAdding:sum];
            }
        }
        sumDict[[NSString stringWithFormat:@"%d", i ]] = sum;
    }

    // sum of sums
    sum = [NSDecimalNumber zero];
    for (NSMutableDictionary *dict in self.budgetData) {
        if (dict == sumDict) {
            continue;
        }
        NSDecimalNumber *value = dict[@"sum"];
        if (value != nil) {
            sum = [value decimalNumberByAdding:sum];
        }
    }
    sumDict[@"sum"] = sum;
    
    // sum of delta
    sum = [NSDecimalNumber zero];
    for (NSMutableDictionary *dict in self.budgetData) {
        if (dict == sumDict) {
            continue;
        }
        NSDecimalNumber *value = [self effectiveDeltaForNode:dict];
        if (value != nil) {
            sum = [value decimalNumberByAdding:sum];
        }
    }
    sumDict[@"delta"] = sum;
    
}

- (void)updateYear {
    [self.yearSelector setLabel:[NSString stringWithFormat:@"%ld", year ] forSegment:1];
    self.period = [NSNumber numberWithInteger:year * 100 + 1];
    [self selectData];
    ShortDate *date = [ShortDate currentDate];
    if (date.year > year) {
        effMonths = 12;
    } else if (date.year == year) {
        effMonths = date.month;
    } else {
        effMonths = 0;
    }
    for (NSMutableDictionary *dict in self.budgetData) {
        [self updateValues:dict];
    }
    [self updateRowSum];
}

- (void)addCategory: (BankingCategory *)cat toDict:(NSMutableDictionary *)dict {
    dict[@"name"] = cat.localName;
    dict[@"id"] = cat.localName;
    dict[@"cat"] = cat;
    NSSet *children = [cat mutableSetValueForKey:@"children"];
    if (children != nil && children.count > 0) {
        NSMutableArray *childArr = [[NSMutableArray alloc] init];
        for (BankingCategory *child in children) {
            if (child.isHidden.boolValue == NO) {
                NSMutableDictionary *dictc = [[NSMutableDictionary alloc] init];
                [self addCategory:child toDict:dictc];
                [childArr addObject:dictc];
            }
        }
        dict[@"children"] = childArr;
    }
}

- (BOOL)hasBudget:(BankingCategory *)cat {
    NSSet *children = [cat mutableSetValueForKey:@"children"];
    for (BankingCategory *child in children) {
        if ([self hasBudget:child]) {
            return YES;
        }
    }
    NSSet *budgets = [cat mutableSetValueForKey:@"budget"];
    
    for (CategoryBudget *budget in budgets) {
        if ([budget.period isEqual:self.period] && budget.budget != nil) {
            return YES;
        }
    }
    return NO;
}

- (void)updateValues: (NSMutableDictionary *)dict {
    BankingCategory *cat = dict[@"cat"];
    NSSet *budgets = [cat mutableSetValueForKey:@"budget"];
    NSDecimalNumber *sum = [NSDecimalNumber zero];
    NSDecimalNumber *budgetValue = nil;

    BOOL found = NO;
    for (CategoryBudget *budget in budgets) {
        if ([budget.period isEqual:self.period]) {
            dict[@"value"] = budgetValue = budget.budget;
            found = YES;
            break;
        }
    }
    
    if (!found) {
        dict[@"value"] = nil;
    }
    
    // update month values
    NSArray *monthValues = self.actuals[cat.objectID];
    if (monthValues != nil) {
        for (int i=0; i<12; i++) {
            dict[[NSString stringWithFormat:@"%d",i+1 ]] = monthValues[i];
            sum = [sum decimalNumberByAdding:monthValues[i]];
        }
    } else {
        for (int i=0; i<12; i++) {
            dict[[NSString stringWithFormat:@"%d",i+1 ]] = [NSDecimalNumber zero];
        }
    }
    
    // update sum value
    NSArray *children = dict[@"children"];
    for (NSMutableDictionary *child in children) {
        [self updateValues: child];
        
        // add child values
        for (int i=0; i<12; i++) {
            NSDecimalNumber *val = dict[[NSString stringWithFormat:@"%d",i+1 ]];
            dict[[NSString stringWithFormat:@"%d",i+1 ]] = [val decimalNumberByAdding:child[[NSString stringWithFormat:@"%d",i+1 ]]];
        }
        sum = [sum decimalNumberByAdding:child[@"sum"]];
    }
    dict[@"sum"] = sum;
    
    // update delta
    [self updateDelta:dict];
}

- (void)updateDelta: (NSMutableDictionary *)dict {
    NSDecimalNumber *budgetValue = dict[@"value"];

    // update delta
    if ([dict[@"id"] isEqualToString:@"zzSumme"]) {
        return;
    }
    
    if (budgetValue != nil) {
        // calculate effective Budget
        NSDecimalNumber *effBudget = [budgetValue decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInteger:effMonths] decimalValue]]];
        dict[@"delta"] = [effBudget decimalNumberByAdding:dict[@"sum"]];
    } else {
        dict[@"delta"] = nil;
    }
    
    NSArray *children = dict[@"children"];
    if (children != nil && children.count > 0) {
        for (NSMutableDictionary *child in children) {
            [self updateDelta:child];
        }
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)changeYear:(id)sender {
    [self saveBudget];
    if ([sender isSelectedForSegment: 0]) {
        // One year back.
        year--;
        [self updateYear];
        
    } else if ([sender isSelectedForSegment:2]) {
        // One year forward.
        year++;
        [self updateYear];
    }
}


- (void)windowWillClose: (NSNotification *)aNotification {
    [NSApp stopModal];
}

- (void)storeValues:(NSDictionary *)dict {
    BankingCategory *cat = dict[@"cat"];
    NSSet *budgets = [cat mutableSetValueForKey:@"budget"];
    BOOL found = NO;
    for (CategoryBudget *budget in budgets) {
        if ([budget.period isEqual:self.period]) {
            budget.budget = dict[@"value"];
            found = YES;
            break;
        }
    }
    
    if (!found && dict[@"value"] != nil) {
        // add budget to category
        NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
        CategoryBudget *budget = [NSEntityDescription insertNewObjectForEntityForName: @"CategoryBudget" inManagedObjectContext: context];
        budget.category = cat;
        budget.budget = dict[@"value"];
        budget.period = self.period;
    }
    NSSet *children = dict[@"children"];
    for (NSMutableDictionary *child in children) {
        [self storeValues: child];
    }
    
}

- (NSDecimalNumber *)totalForDict: (NSDictionary *)dict {
    NSDecimalNumber *value = dict[@"value"];
    if (value == nil) {
        value = [NSDecimalNumber zero];
    }
    NSSet *children = dict[@"children"];
    for (NSMutableDictionary *child in children) {
        value = [value decimalNumberByAdding:[self totalForDict: child]];
    }
    return value;
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    [self updateRowSum];
    for (NSMutableDictionary *dict in self.budgetData) {
        [self updateDelta:dict];
    }
}

- (void)selectData {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    NSError *error = nil;
    NSUInteger month = 1;
    
    // retrieve all data for selected year
    ShortDate *start = [ShortDate dateWithYear:year month:1 day:1];
    ShortDate *end = [ShortDate dateWithYear:year month:12 day:31];
    NSDate *startDate = [start lowDate];
    NSDate *endDate = [end highDate];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"date > %@ and date < %@", startDate, endDate];
    [request setPredicate: predicate];
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: YES];
    NSArray          *sds = @[sd];
    [request setSortDescriptors:sds];
    NSArray *statements = [context executeFetchRequest: request error: &error];
    
    end = [ShortDate dateWithYear:year month:month+1 day:1];
    endDate = [end lowDate];
    for (BankStatement *statement in statements) {
        // switch to next month
        if ([statement.date compare: endDate] != NSOrderedAscending) {
            month++;
            if (month == 13) {
                end = [ShortDate dateWithYear:year month:12 day:31];
                endDate = [end highDate];
            } else {
                end = [ShortDate dateWithYear:year month:month+1 day:1];
                endDate = [end lowDate];
            }
        }
        // we are still in the month
        NSSet *stats = [statement mutableSetValueForKey:@"assignments"];
        for (StatCatAssignment *stat in stats) {
            BankingCategory *cat = stat.category;
            if (![cat isBankAccount]) {
                // now assign value
                NSMutableArray *monthValues = values[cat.objectID];
                if (monthValues == nil) {
                    monthValues = [[NSMutableArray alloc] init];
                    for (int i=0; i<12; i++) {
                        [monthValues addObject:[NSDecimalNumber zero]];
                    }
                    values[cat.objectID] = monthValues;
                }
                monthValues[month-1] = [monthValues[month-1] decimalNumberByAdding:stat.value];
            }
        }
    }
    self.actuals = values;
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (id)cell forTableColumn: (NSTableColumn *)tableColumn item: (id)item {
    NSDictionary *dict = [item representedObject];
    if (dict != nil) {
        if ([dict[@"id"] isEqualToString:@"zzSumme"]) {
            [cell setDrawsBackground:YES];
            [cell setBackgroundColor:[NSColor yellowColor]];
        } else {
            NSDecimalNumber *budget = dict[@"value"];
            if (budget != nil) {
                if ([tableColumn.identifier isEqualToString:@"sum"]) {
                    // calculate budget for sum column
                    budget = [budget decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInteger:effMonths] decimalValue]]];
                }
                
                NSDecimalNumber *value = dict[tableColumn.identifier];
                if (value != nil) {
                    // delta column handling
                    if ([tableColumn.identifier isEqualToString:@"delta"]) {
                        [cell setDrawsBackground:YES];
                        if ([value compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                            [cell setBackgroundColor: [NSColor redColor]];
                        } else {
                            [cell setBackgroundColor: [NSColor greenColor]];
                        }
                        return;
                    }
                    
                    // other columns
                    if ([[value abs] compare:[budget abs]] == NSOrderedAscending) {
                        [cell setDrawsBackground:YES];
                        [cell setBackgroundColor: [NSColor greenColor]];
                        return;
                    } else if ([[value abs] compare:[budget abs]] == NSOrderedDescending) {
                        [cell setDrawsBackground:YES];
                        NSDecimalNumber *limit = [NSDecimalNumber decimalNumberWithDecimal:[self.tolerance decimalValue]];
                        if (limit == nil) {
                            [cell setBackgroundColor:[NSColor redColor]];
                        } else {
                            limit = [limit decimalNumberByMultiplyingByPowerOf10:-2];
                            limit = [limit decimalNumberByMultiplyingBy:budget];
                            budget = [budget decimalNumberByAdding:limit];
                            if ([[value abs] compare:[budget abs]] == NSOrderedDescending) {
                                [cell setBackgroundColor:[NSColor redColor]];
                            } else {
                                [cell setBackgroundColor:self.lightRed];
                            }
                        }
                        return;
                    }
                }
            }
            [cell setDrawsBackground:NO];
        }
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
}

- (void)saveBudget {
    NSError *error = nil;

    for (NSDictionary *dict in self.budgetData) {
        [self storeValues:dict];
    }
    
    [self.budgetView saveState];
    
    // save updates
    if (![MOAssistant.sharedAssistant.context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }
}

- (void)ok:(id)sender {
    LocalSettingsController *lsc = LocalSettingsController.sharedSettings;
    
    [lsc setObject:self.tolerance forKeyedSubscript:@"BudgetTolerance"];
    
    [self saveBudget];
    [self.window close];
}

- (void)cancel:(id)sender {
    [self.window close];
}


@end

