/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

#import "BankStatementController.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "HBCIClient.h"
#import "ShortDate.h"

@implementation BankStatementController

@synthesize accountStatements;

- (id)initWithAccount: (BankAccount *)acc statement: (BankStatement *)stat
{
    self = [super initWithWindowNibName: @"BankStatementController"];
    memContext = [[MOAssistant assistant] memContext];
    context = [[MOAssistant assistant] context];
    account = acc;
    actionResult = 0;

    [self arrangeStatements];

    currentStatement = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement" inManagedObjectContext: memContext];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    negateValue = [defaults boolForKey: @"negateStatementEditValue"];

    if (stat) {
        // now copy statement
        NSEntityDescription *entity = [stat entity];
        NSArray             *attributeKeys = [[entity attributesByName] allKeys];
        NSDictionary        *attributeValues = [stat dictionaryWithValuesForKeys: attributeKeys];
        [currentStatement setValuesForKeysWithDictionary: attributeValues];
        if (negateValue) {
            currentStatement.value = [[NSDecimalNumber zero] decimalNumberBySubtracting: currentStatement.value];
        }
    } else {
        currentStatement.currency = account.currency;
        currentStatement.localAccount = account.accountNumber;
        currentStatement.localBankCode = account.bankCode;
        currentStatement.isManual = @YES;
        if ([accountStatements count] > 0) {
            currentStatement.date = [accountStatements[0] date];
            currentStatement.valutaDate = [accountStatements[0] valutaDate];
        } else {
            currentStatement.date = [NSDate date];
            currentStatement.valutaDate = [NSDate date];
        }
        //provisorisch
        currentStatement.remoteCountry = @"de";
    }
    return self;
}

- (void)arrangeStatements
{
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
    NSArray          *sds = @[sd];

    NSMutableSet *statements = [account mutableSetValueForKey: @"statements"];
    self.accountStatements = [[statements allObjects] sortedArrayUsingDescriptors: sds];

    if ([self.accountStatements count] > 0) {
        lastStatement = (self.accountStatements)[0];
    } else {lastStatement = nil; }

}

- (void)awakeFromNib
{
    [statementController setContent: currentStatement];
    if (negateValue) {
        [valueField setTextColor: [NSColor redColor]];
    }

    [categoriesController setSortDescriptors: @[[[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES]]];
}

- (void)saveStatement
{
    NSEntityDescription *entity = [currentStatement entity];
    NSArray             *attributeKeys = [[entity attributesByName] allKeys];
    NSDictionary        *attributeValues = [currentStatement dictionaryWithValuesForKeys: attributeKeys];
    BankStatement       *stat;
    NSError             *error = nil;

    BankStatement *newStatement = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement" inManagedObjectContext: context];
    [newStatement setValuesForKeysWithDictionary: attributeValues];

    if (negateValue) {
        newStatement.value = [[NSDecimalNumber zero] decimalNumberBySubtracting: currentStatement.value];
    }

    //calculate date
    BOOL found = NO;
    for (stat in accountStatements) {
        // newStatement.date >= stat.date
        if ([[ShortDate dateWithDate: newStatement.date] compare: [ShortDate dateWithDate: stat.date]] != NSOrderedAscending) {
            // newStatement.date == stat.date
            if ([[ShortDate dateWithDate: newStatement.date] compare: [ShortDate dateWithDate: stat.date]] == NSOrderedSame) {
                newStatement.date = [[NSDate alloc] initWithTimeInterval: 100 sinceDate: stat.date];
            } else {
                newStatement.date = [[ShortDate dateWithDate: newStatement.date] lowDate];
            }
            found = YES;
            break;
        }
    }
    // adjust balance of later statements
    for (stat in accountStatements) {
        // stat.date > newStatement.date
        if ([stat.date compare: newStatement.date] == NSOrderedDescending) {
            stat.saldo = [stat.saldo decimalNumberByAdding: newStatement.value];
        } else {break; }
    }
    if (found == NO) {
        newStatement.date = [[ShortDate dateWithDate: newStatement.date] lowDate];
    }

    // add to account
    [newStatement addToAccount: account];

    [self arrangeStatements];

    if (lastStatement) {
        account.balance = lastStatement.saldo;
        [[Category bankRoot] rollupRecursive: YES];
    }

    // Manually assign to a category. Doesn't affect automatic assignments based on rules.
    NSInteger idx = [categoriesController selectionIndex];
    if (idx != NSNotFound) {
        Category *cat = [categoriesController arrangedObjects][idx];
        [newStatement assignToCategory: cat];
        [Category updateCatValues];
    }

    // save updates
    if ([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    [NSApp stopModalWithCode: actionResult];
    [memContext reset];
}

- (IBAction)cancel: (id)sender
{
    actionResult = 0;
    [self close];
}

- (IBAction)next: (id)sender
{
    [statementController commitEditing];
    if (valueChanged) {
        [self updateSaldo];
    }
    if ([self check] == NO) {
        return;
    }
    [self saveStatement];
    currentStatement = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement" inManagedObjectContext: memContext];
    currentStatement.currency = account.currency;
    currentStatement.localAccount = account.accountNumber;
    currentStatement.localBankCode = account.bankCode;
    currentStatement.isManual = @YES;
    currentStatement.date = [dateField dateValue];
    currentStatement.valutaDate = [valutaField dateValue];
    currentStatement.remoteCountry = @"de";
    [statementController setContent: currentStatement];
}

- (IBAction)done: (id)sender
{
    [statementController commitEditing];
    if (valueChanged) {
        [self updateSaldo];
    }
    if ([self check] == NO) {
        return;
    }
    [self saveStatement];
    actionResult = 1;
    [self close];
}

- (void)updateSaldo
{
    NSDecimalNumber *realValue;

    if (currentStatement.value == nil) {
        return;
    }
    if (negateValue == YES) {
        realValue = [[NSDecimalNumber zero] decimalNumberBySubtracting: currentStatement.value];
    } else {realValue = currentStatement.value; }

    // amount field
    if (lastStatement == nil || [[ShortDate dateWithDate: currentStatement.date] compare: [ShortDate dateWithDate: lastStatement.date]] != NSOrderedAscending) {
        if (lastStatement == nil) {
            if (currentStatement.value) {
                currentStatement.saldo = [account.balance decimalNumberByAdding: realValue];
            }
        } else {
            if (currentStatement.value) {
                currentStatement.saldo = [lastStatement.saldo decimalNumberByAdding: realValue];
            }
        }
    } else {
        // find first statement that is later than current one.
        BankStatement *foundStatement = nil;
        for (BankStatement *stat in accountStatements) {
            if ([[ShortDate dateWithDate: currentStatement.date] compare: [ShortDate dateWithDate: stat.date]] == NSOrderedAscending) {
                foundStatement = stat;
            } else {break; }
        }
        if (foundStatement && currentStatement.value != nil) {
            currentStatement.saldo = [[foundStatement.saldo decimalNumberBySubtracting: foundStatement.value] decimalNumberByAdding: realValue];
        }
    }
    valueChanged = NO;
}

- (void)controlTextDidBeginEditing: (NSNotification *)aNotification
{
    NSControl *te = [aNotification object];

    if ([te tag] == 200) {
        valueChanged = YES;
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    NSControl *te = [aNotification object];

    if ([te tag] == 100) {
        NSString *name = [[HBCIClient hbciClient] bankNameForCode: [te stringValue] inCountry: currentStatement.remoteCountry];
        if (name) {
            [self setValue: name forKey: @"bankName"];
        }
    }
    if ([te tag] == 200) {
        [self updateSaldo];
    }
}

- (IBAction)dateChanged: (id)sender
{
    NSDate *date = [(NSDatePicker *)sender dateValue];
    if (sender == dateField) {
        [valutaField setDateValue: date];
    }

    if (lastDate == nil && [[ShortDate dateWithDate: date] compare: [ShortDate dateWithDate: lastStatement.date]] != NSOrderedAscending) {
        if (currentStatement.value) {
            currentStatement.saldo = [lastStatement.saldo decimalNumberByAdding: currentStatement.value];
        }
    } else {
        // find first statement that is later than current one.
        BankStatement *foundStatement = nil;
        for (BankStatement *stat in accountStatements) {
            if ([[ShortDate dateWithDate: date] compare: [ShortDate dateWithDate: stat.date]] == NSOrderedAscending) {
                foundStatement = stat;
            } else {break; }
        }
        if (foundStatement && currentStatement.value != nil) {
            currentStatement.saldo = [[foundStatement.saldo decimalNumberBySubtracting: foundStatement.value] decimalNumberByAdding: currentStatement.value];
        }
    }
}

- (IBAction)negateValueChanged: (id)sender
{
    if ([sender state] == NSOnState) {
        [valueField setTextColor: [NSColor redColor]];
    } else {
        [valueField setTextColor: [NSColor blackColor]];
    }
    negateValue = ([sender state] == NSOnState);
    [self updateSaldo];
}

- (BOOL)check
{
    BOOL res;
    if (currentStatement.value == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP57", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }
    if (currentStatement.remoteAccount && currentStatement.remoteBankCode) {
        res = [[HBCIClient hbciClient] checkAccount: currentStatement.remoteAccount
                                            forBank: currentStatement.remoteBankCode
                                          inCountry: currentStatement.remoteCountry];


        if (res == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                            NSLocalizedString(@"AP60", nil),
                            NSLocalizedString(@"AP61", nil), nil, nil);
            return NO;
        }
    }

    return YES;
}

@end
