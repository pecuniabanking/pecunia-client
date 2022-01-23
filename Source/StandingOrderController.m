/**
 * Copyright (c) 2010, 2015, Pecunia Project. All rights reserved.
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

#import "StandingOrderController.h"
#import "MOAssistant.h"
#import "StandingOrder.h"
#import "BankAccount.h"
#import "TransactionLimits.h"
#import "MCEMTableView.h"
#import "AmountCell.h"
#import "PecuniaError.h"
#import "StatusBarController.h"
#import "ShortDate.h"
#import "TransferFormularView.h"
#import "SupportedTransactionInfo.h"
#import "GraphicsAdditions.h"
#import "AnimationHelper.h"
#import "BankingController.h"

#import "NSButton+PecuniaAdditions.h"

NSString *const OrderDataType = @"pecunia.OrderDataType"; // For dragging an existing order to the bin.

@interface DeleteOrderTargetView : NSImageView
{
}

@property (nonatomic, weak) StandingOrderController *controller;

@end

@implementation DeleteOrderTargetView

@synthesize controller;

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];

    // Register for types that can be deleted.
    [self registerForDraggedTypes: @[OrderDataType]];
}

- (NSDragOperation)draggingEntered: (id <NSDraggingInfo>)info {
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString     *type = [pasteboard availableTypeFromArray: @[OrderDataType]];
    if (type == nil) {
        return NSDragOperationNone;
    }

    NSData  *data = [pasteboard dataForType: type];
    NSArray *entries = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    NSManagedObjectID      *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [entries lastObject]];
    if (objectId == nil) {
        return NSDragOperationNone;
    }
    StandingOrder *order = (StandingOrder *)[context objectWithID: objectId];
    if ([order.toDelete boolValue]) {
        return NSDragOperationNone; // Don't allow to delete this order if it is already marked for deletion.
    }

    [[NSCursor disappearingItemCursor] set];
    return NSDragOperationDelete;
}

- (void)draggingExited: (id <NSDraggingInfo>)info {
    [[NSCursor arrowCursor] set];
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)info {
    if ([controller concludeDropDeleteOperation: info]) {
        return YES;
    }
    return NO;
}

@end

//--------------------------------------------------------------------------------------------------

@implementation StandingOrderController

@synthesize requestRunning;

@synthesize oldMonthCycle;
@synthesize oldMonthDay;
@synthesize oldWeekCycle;
@synthesize oldWeekDay;
@synthesize currentLimits;
@synthesize currentOrder;

- (id)init {
    self = [super init];
    if (self != nil) {
        managedObjectContext = MOAssistant.sharedAssistant.context;

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        weekDays = formatter.weekdaySymbols;
        NSUInteger firstWeekdayIndex = [NSCalendar.currentCalendar firstWeekday] - 1;
        if (firstWeekdayIndex > 0) {
            weekDays = [[weekDays subarrayWithRange: NSMakeRange(firstWeekdayIndex, 7 - firstWeekdayIndex)]
                        arrayByAddingObjectsFromArray: [weekDays subarrayWithRange: NSMakeRange(0, firstWeekdayIndex)]];
        }

        self.requestRunning = @NO;
    }

    return self;
}

- (void)awakeFromNib {
    initializing = YES;

    monthCell.textColor = [NSColor whiteColor];
    weekCell.textColor = [NSColor whiteColor];

    [self disableCycles];

    [self updateSourceAccountSelector];

    [ordersListView setCellSpacing: 0];
    [ordersListView setAllowsEmptySelection: NO];
    [ordersListView setAllowsMultipleSelection: NO];

    // We don't use any explicit sorting for the orders, as especially for new orders many values are not available yet,
    // creating so problems with the sorting.
    ordersListView.owner = self;

    // Actually, the values for the bound property and the key path don't matter as the listview has
    // a very clear understanding what it needs to bind to. It's just there to make the listview
    // establish its bindings.
    [ordersListView bind: @"dataSource" toObject: orderController withKeyPath: @"arrangedObjects" options: nil];

    [orderController bind: @"selectionIndexes" toObject: ordersListView withKeyPath: @"selectedRows" options: nil];
    [ordersListView bind: @"selectedRows" toObject: orderController withKeyPath: @"selectionIndexes" options: nil];

    standingOrderForm.icon = [NSImage imageNamed: @"cyclic"];
    standingOrderForm.bottomArea = 30;

    // We listen to selection changes in the pending transfers list.
    [orderController addObserver: self
                      forKeyPath: @"selectionIndexes"
                         options: 0
                         context: @"order-selection"];

    deleteImage.controller = self;

    initializing = NO;
}

- (NSString *)monthDayToString: (int)day {
    if (day == 97) {
        return @"Ultimo-2";
    } else if (day == 98) {
        return @"Ultimo-1";
    } else if (day == 99) {
        return @"Ultimo";
    } else {
        return [NSString stringWithFormat: @"%d.", day];
    }
}

- (NSString *)weekDayToString: (int)day {
    if (day > 0 && day < 8) {
        return weekDays[day - 1];
    }
    return weekDays[1];
}

- (int)stringToMonthDay: (NSString *)s {
    if ([s isEqualToString: @"Ultimo-2"]) {
        return 97;
    } else if ([s isEqualToString: @"Ultimo-1"]) {
        return 98;
    } else if ([s isEqualToString: @"Ultimo"]) {
        return 99;
    } else {
        return [[s substringToIndex: [s length] - 1] intValue];
    }
}

- (void)initCycles {
    currentOrder.cycle = @1;
    currentOrder.executionDay = @1;
}

- (int)stringToWeekDay: (NSString *)s {
    return (int)[weekDays indexOfObject: s] + 1;
}

- (void)enableWeekly: (BOOL)weekly {
    if (weekly) {
        [execDaysMonthPopup setTitle: @""];
        [monthCyclesPopup setTitle: @""];
    } else {
        [execDaysWeekPopup setTitle: @""];
        [weekCyclesPopup setTitle: @""];
    }
    [execDaysMonthPopup setEnabled: !weekly];
    [monthCyclesPopup setEnabled: !weekly];
    [execDaysWeekPopup setEnabled: weekly];
    [weekCyclesPopup setEnabled: weekly];
}

- (void)disableCycles {
    [execDaysMonthPopup setEnabled: NO];
    [monthCyclesPopup setEnabled: NO];
    [execDaysWeekPopup setEnabled: NO];
    [weekCyclesPopup setEnabled: NO];
    [weekCell setEnabled: NO];
    [monthCell setEnabled: NO];
}

- (void)updateWeekCycles {
    NSInteger      selectedIndex = 0;
    NSInteger      currentCycle = currentOrder.cycle.intValue;
    NSMutableArray *weekCycles = [NSMutableArray arrayWithCapacity: 52];

    if (currentLimits == nil) {
        return;
    }

    if (currentLimits.weekCycles == nil || currentLimits.weekCycles.count == 0 || [[currentLimits.weekCycles lastObject] intValue] == 0) {
        [weekCycles addObject: NSLocalizedString(@"AP451",  nil)];
        if (currentCycle == 1) {
            selectedIndex = 0;
        }
        for (int i = 2; i <= 52; i++) {
            [weekCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP453",  nil), i]];
            if (i == currentCycle) {
                selectedIndex = i - 1;
            }
        }
    } else {
        NSInteger index = 0;
        for (NSString *s in currentLimits.weekCycles) {
            if (s.intValue == 1) {
                [weekCycles addObject: NSLocalizedString(@"AP451",  nil)];
            } else {
                [weekCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP453",  nil), s.intValue]];
            }
            if (s.intValue == currentCycle) {
                selectedIndex = index;
            }
            index++;
        }
    }
    [weekCyclesController setContent: weekCycles];
    [weekCyclesPopup selectItemAtIndex: selectedIndex];

    NSMutableArray *execDays = [NSMutableArray arrayWithCapacity: 7];
    if (currentLimits.execDaysWeek == nil || [currentLimits.execDaysWeek count] == 0 || [[currentLimits.execDaysWeek lastObject] intValue] == 0) {
        for (int i = 1; i <= 7; i++) {
            [execDays addObject: [self weekDayToString: i]];
        }
    } else {
        for (NSString *s in currentLimits.execDaysWeek) {
            [execDays addObject: [self weekDayToString: s.intValue]];
        }
    }

    [execDaysWeekController setContent: execDays];
    [execDaysWeekPopup selectItemWithTitle: [self weekDayToString: currentOrder.executionDay.intValue]];
}

- (void)updateMonthCycles {
    NSInteger      selectedIndex = 0;
    NSInteger      currentCycle = currentOrder.cycle.intValue;
    NSMutableArray *monthCycles = [NSMutableArray arrayWithCapacity: 12];

    if (currentLimits == nil) {
        return;
    }

    if (currentLimits.monthCycles == nil || currentLimits.monthCycles.count == 0 || [[currentLimits.monthCycles lastObject] intValue] == 0) {
        [monthCycles addObject: NSLocalizedString(@"AP450",  nil)];
        if (currentCycle == 1) {
            selectedIndex = 0;
        }
        for (NSInteger i = 2; i <= 12; i++) {
            [monthCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP452",  nil), i]];
            if (i == currentCycle) {
                selectedIndex = i - 1;
            }
        }
    } else {
        NSInteger index = 0;
        for (NSString *s in currentLimits.monthCycles) {
            if (s.intValue == 1) {
                [monthCycles addObject: NSLocalizedString(@"AP450",  nil)];
            } else {
                [monthCycles addObject: [NSString stringWithFormat: NSLocalizedString(@"AP452",  nil), s.intValue]];
            }
            if (s.intValue == currentCycle) {
                selectedIndex = index;
            }
            index++;
        }
    }

    [monthCyclesController setContent: monthCycles];
    [monthCyclesPopup selectItemAtIndex: selectedIndex];

    NSMutableArray *execDays = [NSMutableArray arrayWithCapacity: 31];
    if (currentLimits.execDaysMonth == nil || currentLimits.execDaysMonth.count == 0 || [[currentLimits.execDaysMonth lastObject] intValue] == 0) {
        for (int i = 1; i <= 28; i++) {
            [execDays addObject: [NSString stringWithFormat: @"%d.", i]];
        }
        [execDays addObject: @"Ultimo-2"];
        [execDays addObject: @"Ultimo-1"];
        [execDays addObject: @"Ultimo"];
    } else {
        for (NSString *s in currentLimits.execDaysMonth) {
            [execDays addObject: [self monthDayToString: s.intValue]];
        }
    }

    [execDaysMonthController setContent: execDays];
    [execDaysMonthPopup selectItemWithTitle: [self monthDayToString: currentOrder.executionDay.intValue]];
}

- (NSMenuItem *)createItemForAccountSelector: (BankAccount *)account {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [account localName] action: nil keyEquivalent: @""];
    item.representedObject = account;

    return item;
}

/**
 * Refreshes the content of the source account selector.
 * An attempt is made to keep the current selection.
 */
- (void)updateSourceAccountSelector {
    [self prepareSourceAccountSelector: sourceAccountSelector.selectedItem.representedObject];
}

/**
 * Updates the selected item of the account selector with currentObject's account.
 */
- (void)updateSourceAccountSelection {
    NSInteger selectedItem = 0;
    NSMenu    *menu = [sourceAccountSelector menu];
    NSArray   *items = [menu itemArray];
    for (NSMenuItem *item in items) {
        if (item.representedObject == currentOrder.account) {
            [sourceAccountSelector selectItemAtIndex: selectedItem];
            return;
        }
        selectedItem += 1;
    }
    [sourceAccountSelector selectItemAtIndex: -1];
}

/**
 * Refreshes the content of the source account selector and selects the given account (if found).
 */
- (void)prepareSourceAccountSelector: (BankAccount *)selectedAccount {
    [sourceAccountSelector removeAllItems];

    NSMenu *sourceMenu = [sourceAccountSelector menu];

    BankingCategory         *category = [BankingCategory bankRoot];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES];
    NSArray          *sortDescriptors = @[sortDescriptor];
    NSArray          *institutes = [[category children] sortedArrayUsingDescriptors: sortDescriptors];

    // Convert list of accounts in their institutes branches to a flat list
    // usable by the selector.
    NSInteger selectedItem = -1;
    for (BankingCategory *currentInstitute in institutes) {
        if (![currentInstitute isKindOfClass: [BankAccount class]]) {
            continue;
        }

        NSArray        *accountsForInstitute = [[currentInstitute children] sortedArrayUsingDescriptors: sortDescriptors];
        NSMutableArray *validAccounts = [NSMutableArray arrayWithCapacity: 10];

        for (BankingCategory *currentAccount in accountsForInstitute) {
            if (![currentAccount isKindOfClass: [BankAccount class]]) {
                continue;
            }

            BankAccount *account = (BankAccount *)currentAccount;

            // Exclude manual accounts and those that don't support standing orders from the list.
            if ([[account isManual] boolValue] || ![HBCIBackend.backend isTransactionSupportedForAccount: TransactionType_StandingOrderSEPA account: account]) {
                continue;
            }

            [validAccounts addObject: account];
        }
        if ([validAccounts count] > 0) {
            NSMenuItem *item = [self createItemForAccountSelector: (BankAccount *)currentInstitute];
            [sourceMenu addItem: item];
            [item setEnabled: NO];
            for (BankAccount *account in validAccounts) {
                item = [self createItemForAccountSelector: account];
                [item setEnabled: YES];
                item.indentationLevel = 1;
                [sourceMenu addItem: item];
                if (account == selectedAccount) {
                    selectedItem = sourceMenu.numberOfItems - 1;
                }
            }
        }
    }
    if (sourceMenu.numberOfItems > 1) {
        [sourceAccountSelector selectItemAtIndex: selectedItem];
    } else {
        [sourceAccountSelector selectItemAtIndex: -1];
    }
    [self sourceAccountChanged: sourceAccountSelector];
}

- (IBAction)monthCycle: (id)sender {
    StandingOrderPeriod period = [currentOrder.period intValue];
    if (period == stord_weekly) {
        self.oldWeekDay = currentOrder.executionDay;
        self.oldWeekCycle = currentOrder.cycle;
        if (oldMonthDay) {
            currentOrder.executionDay = oldMonthDay;
        } else {
            currentOrder.executionDay = @1;
        }
        if (oldMonthCycle) {
            currentOrder.cycle = oldMonthCycle;
        } else {
            currentOrder.cycle = @1;
        }
    }
    [self enableWeekly: NO];
    currentOrder.period = @(stord_monthly);
    currentOrder.isChanged = @YES;
    [self updateMonthCycles];
}

- (IBAction)weekCycle: (id)sender {
    StandingOrderPeriod period = [currentOrder.period intValue];
    if (period == stord_monthly) {
        self.oldMonthDay = currentOrder.executionDay;
        self.oldMonthCycle = currentOrder.cycle;
        if (oldWeekDay) {
            currentOrder.executionDay = oldWeekDay;
        } else {
            currentOrder.executionDay = @1;
        }
        if (oldWeekCycle) {
            currentOrder.cycle = oldWeekCycle;
        } else {
            currentOrder.cycle = @1;
        }
    }
    [self enableWeekly: YES];
    currentOrder.period = @(stord_weekly);
    currentOrder.isChanged = @YES;
    [self updateWeekCycles];

}

- (IBAction)monthCycleChanged: (id)sender {
    NSInteger idx = [monthCyclesPopup indexOfSelectedItem];
    if (currentLimits.monthCycles == nil || currentLimits.monthCycles.count == 0 || [[currentLimits.monthCycles lastObject] intValue] == 0) {
        currentOrder.cycle = @(idx + 1);
    } else {
        NSString *c = (currentLimits.monthCycles)[idx];
        currentOrder.cycle = @([c intValue]);
    }

    currentOrder.isChanged = @YES;
}

- (IBAction)monthDayChanged: (id)sender {
    currentOrder.executionDay = @([self stringToMonthDay: [execDaysMonthPopup titleOfSelectedItem]]);
    currentOrder.isChanged = @YES;
}

- (IBAction)weekCycleChanged: (id)sender {
    NSInteger idx = [weekCyclesPopup indexOfSelectedItem];
    if (currentLimits.weekCycles == nil || currentLimits.weekCycles.count == 0 || [[currentLimits.weekCycles lastObject] intValue] == 0) {
        currentOrder.cycle = @(idx + 1);
    } else {
        NSString *c = (currentLimits.weekCycles)[idx];
        currentOrder.cycle = @([c intValue]);
    }

    currentOrder.cycle = @([[weekCyclesPopup titleOfSelectedItem] intValue]);
    currentOrder.isChanged = @YES;
}

- (IBAction)weekDayChanged: (id)sender {
    currentOrder.executionDay = @([self stringToWeekDay: [execDaysWeekPopup titleOfSelectedItem]]);
    currentOrder.isChanged = @YES;
}

- (IBAction)add: (id)sender {
    StandingOrder *order = [NSEntityDescription insertNewObjectForEntityForName: @"StandingOrder"
                                                         inManagedObjectContext: managedObjectContext];

    order.period = @(stord_monthly);
    order.cycle = @1;
    order.executionDay = @1;
    order.isChanged = @YES;
    ShortDate *startDate = [[ShortDate currentDate] firstDayInMonth];
    order.firstExecDate = [[startDate dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth] lowDate];
    order.lastExecDate = [[ShortDate dateWithYear: 2999 month: 12 day: 31] lowDate];

    [orderController addObject: order];
    [self prepareSourceAccountSelector: nil];
}

- (IBAction)firstExecDateChanged: (id)sender {
    currentOrder.isChanged = @YES;
}

- (IBAction)lastExecDateChanged: (id)sender {
    currentOrder.isChanged = @YES;
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification {
    NSInteger tag = [aNotification.object tag];
    if (tag == 11) {
        NSString *iban = [[aNotification.object stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *bankName = [[HBCIBackend backend] bankNameForIBAN: iban];
        currentOrder.remoteBankName = bankName == nil ? @"" : bankName;
        NSString *bic = [[HBCIBackend backend] bicForIBAN: iban];
        if (bic != nil) {
            currentOrder.remoteBIC = bic;
        }
        currentOrder.remoteIBAN = iban;
    }
}

- (void)controlTextDidChange: (NSNotification *)aNotification {
    if (!currentOrder.isChanged.boolValue) {
        currentOrder.isChanged = @YES;
    }
}

- (BOOL)checkOrder: (StandingOrder *)stord {
    NSNumber *value;
    
    [orderController commitEditing];

    // avoid rounding issues
    stord.value = [stord.value rounded];

    if (stord.remoteName == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP54", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }
    if (stord.remoteIBAN == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP55", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    if (stord.remoteBIC == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP56", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    value = stord.value;
    if (value == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP57", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    if (value.doubleValue <= 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP58", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    if (stord.purpose1 == nil || [stord.purpose1 length] == 0) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP76", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }

    if (![SepaService isValidIBAN: stord.remoteIBAN]) {
        NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                        NSLocalizedString(@"AP70", nil),
                        NSLocalizedString(@"AP61", nil), nil, nil);
        return NO;
    }

    return YES;
}

- (IBAction)update: (id)sender {
    // Make the sender the first responder to finish any pending edit action.
    [[mainView window] makeFirstResponder: sender];

    NSError *error = nil;
    NSArray *orders = [orderController arrangedObjects];

    for (StandingOrder *stord in orders) {
        // don't send
        if ([stord.isChanged boolValue] == NO && [stord.toDelete boolValue] == NO) {
            continue;
        }

        // don't send sent orders without ID
        if ([stord.isSent boolValue] == YES && stord.orderKey == nil) {
            continue;
        }

        if (![self checkOrder: stord]) {
            [orderController setSelectedObjects: @[stord]];
            return;
        }
    }
    StatusBarController *sc = [StatusBarController controller];
    [sc startSpinning];
    self.requestRunning = @YES;
    [sc setMessage: NSLocalizedString(@"AP460", nil) removeAfter: 0];

    NSMutableArray *sendOrders = [NSMutableArray arrayWithCapacity: [orders count]];
    for (StandingOrder *stord in orders) {
        // don't send unchanged
        if ([stord.isChanged boolValue] == NO && [stord.toDelete boolValue] == NO) {
            continue;
        }

        // don't send sent orders without ID
        if ([stord.isSent boolValue] == YES && stord.orderKey == nil) {
            continue;
        }

        [sendOrders addObject: stord];
    }

    error = [[HBCIBackend backend] sendStandingOrders: sendOrders];
    
    if (error != nil) {
        [sc stopSpinning];
        [sc clearMessage];
        self.requestRunning = @NO;

        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }

    // Check if there are new orders without key.
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"StandingOrder" inManagedObjectContext: managedObjectContext];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isSent == YES AND orderKey == nil"];
    [request setPredicate: predicate];
    NSArray *stords = [managedObjectContext executeFetchRequest: request error: &error];
    if ([stords count] > 0) {
        NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP463", nil),
                                        NSLocalizedString(@"AP464", nil),
                                        NSLocalizedString(@"AP3", nil),
                                        NSLocalizedString(@"AP4", nil), nil);
        if (res == NSAlertDefaultReturn) {
            [self performSelector: @selector(getOrders:) withObject: self afterDelay: 0];
        }
    }

    [sc stopSpinning];
    [sc clearMessage];
    self.requestRunning = @NO;

    // save updates
    if ([managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (IBAction)getOrders: (id)sender {
    // Make the sender the first responder to avoid changing anything if there was an ongoing
    // edit action.
    [[mainView window] makeFirstResponder: sender];

    for (StandingOrder *stord in [orderController arrangedObjects]) {
        if ([stord.isChanged boolValue]) {
            NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP84", nil),
                                            NSLocalizedString(@"AP461", nil),
                                            NSLocalizedString(@"AP462", nil),
                                            NSLocalizedString(@"AP2", nil), nil);
            if (res == NSAlertAlternateReturn) {
                return;
            } else {
                break;
            }
        }
    }
    
    NSMutableArray *accountList = [NSMutableArray new];
    NSSet          *candidates = [BankingCategory.bankRoot allCategories];
    
    for (BankingCategory *currentAccount in candidates) {
        if (![currentAccount isKindOfClass: [BankAccount class]]) {
            continue;
        }

        BankAccount *account = (BankAccount *)currentAccount;

        // Exclude manual accounts and those that don't support standing orders from the list.
        if ([[account isManual] boolValue] || ![HBCIBackend.backend isTransactionSupportedForAccount: TransactionType_StandingOrderSEPA account: account]) {
            continue;
        }

        if (account.userId != nil) {
            [accountList addObject: account];

            // remove orders for this account
            NSSet *orders = [account mutableSetValueForKey: @"standingOrders"];
            for (StandingOrder *order in orders) {
                [managedObjectContext deleteObject: order];
            }
        }
    }
    
    if (accountList.count > 0) {
        StatusBarController *sc = [StatusBarController controller];
        [sc startSpinning];
        self.requestRunning = @YES;
        [sc setMessage: NSLocalizedString(@"AP459", nil) removeAfter: 0];

        NSArray * resultList = [[HBCIBackend backend] getStandingOrders: accountList];
        [self processOrders:resultList];
        
        [self validateNewOrders];
        [orderController prepareContent];
        
        [sc stopSpinning];
        [sc clearMessage];
        self.requestRunning = @NO;
    } else {
        NSRunAlertPanel(NSLocalizedString(@"AP84", nil),
                        NSLocalizedString(@"AP457", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
    }
}

#pragma mark -
#pragma mark Other notifications

- (IBAction)sourceAccountChanged: (id)sender {
    BOOL accountSelected = [sender selectedItem] != nil;
    for (NSUInteger row = 0; row <= 5; row++) {
        for (NSUInteger index = 0; index < 5; index++) {
            [[standingOrderForm viewWithTag: row * 10 + index] setEnabled: accountSelected];
        }
    }
    if (accountSelected) {
        BankAccount *account = [sender selectedItem].representedObject;

        currentOrder.account = account;
        if (account.currency.length == 0) {
            currentOrder.currency = @"EUR";
        } else {
            currentOrder.currency = account.currency;
        }

        // re-calculate limits and check
        self.currentLimits = nil;
        if (currentOrder.orderKey == nil) {
            self.currentLimits = [[HBCIBackend backend] standingOrderLimits: currentOrder.account.defaultBankUser action: stord_create];
            self.editable = YES;
        } else {
            self.editable = NO;
            if ([HBCIBackend.backend isTransactionSupportedForAccount:TransactionType_StandingOrderSEPAEdit account:currentOrder.account]) {
                self.currentLimits = [HBCIBackend.backend standingOrderLimits: currentOrder.account.defaultBankUser action: stord_change];
                self.editable = YES;
            }
        }

        // update to new limits
        StandingOrderPeriod period = [currentOrder.period intValue];

        if (period == stord_weekly && currentLimits.allowWeekly == NO) {
            currentOrder.period = @(stord_monthly);
            period = stord_monthly;
        }

        if (currentLimits != nil) {
            if (period == stord_weekly) {
                [self enableWeekly: YES];
                [weekCell setState: NSOnState];
                [monthCell setState: NSOffState];
                [self updateWeekCycles];
                [weekCyclesPopup setEnabled: currentLimits.allowChangeCycle];
                [execDaysWeekPopup setEnabled: currentLimits.allowChangeExecDay];
            } else {
                [self enableWeekly: NO];
                [weekCell setState: NSOffState];
                [monthCell setState: NSOnState];
                [self updateMonthCycles];
                [monthCyclesPopup setEnabled: currentLimits.allowChangeCycle];
                [execDaysMonthPopup setEnabled: currentLimits.allowChangeExecDay];
            }
            
            [weekCell setEnabled: currentLimits.allowWeekly];
            [monthCell setEnabled: currentLimits.allowMonthly];
            
            if (!currentLimits.allowChangePeriod) {
                [weekCell setEnabled: NO];
                [monthCell setEnabled: NO];
            }
        }
    } else {
        [weekCell setEnabled: NO];
        [monthCell setEnabled: NO];
    }
}

- (void)processOrders: (NSArray*)resultList {
    if (resultList == nil || resultList.count == 0) {
        return;
    }
    
    for (BankQueryResult *result in resultList) {
        [result.account updateStandingOrders: result.standingOrders];
    }
    // save updates
    NSError *error;
    if ([managedObjectContext save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (void)validateNewOrders {
    for (StandingOrder *order in [orderController arrangedObjects]) {
        if (order.remoteBankName == nil) {
            order.remoteBankName = [[HBCIBackend backend] bankNameForIBAN: order.remoteIBAN];
        }
    }
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context {
    if (object == orderController) {
        if (initializing) {
            return;
        }

        NSArray *selection = [orderController selectedObjects];
        if (selection == nil || [selection count] == 0) {
            [self disableCycles];
            return;
        }
        if (currentOrder == selection[0]) {
            return;
        }
        self.currentOrder = selection[0];
        
        if(currentOrder.account == nil) {
            return;
        }

        deleteButton.hidden = [currentOrder.toDelete boolValue];

        oldWeekDay = nil;
        oldWeekCycle = nil;
        oldMonthDay =  nil;
        oldMonthCycle = nil;

        self.currentLimits = nil;
        if (currentOrder.orderKey == nil) {
            self.currentLimits = [[HBCIBackend backend] standingOrderLimits: currentOrder.account.defaultBankUser action: stord_create];
            self.editable = YES;
        } else {
            self.editable = NO;
            if ([HBCIBackend.backend isTransactionSupportedForAccount:TransactionType_StandingOrderSEPAEdit account:currentOrder.account]) {
                self.currentLimits = [HBCIBackend.backend standingOrderLimits: currentOrder.account.defaultBankUser action: stord_change];
                self.editable = YES;
            }
        }

        // source account cannot be changed after order is created
        [sourceAccountSelector setEnabled: currentOrder.orderKey == nil];

        if (self.currentOrder.remoteBankCode != nil && (self.currentOrder.remoteBankName == nil || [self.currentOrder.remoteBankName length] == 0)) {
            NSString *bankName = [[HBCIBackend backend] bankNameForCode: self.currentOrder.remoteBankCode];
            if (bankName) {
                self.currentOrder.remoteBankName = bankName;
            }
        }

        if (currentLimits != nil) {
            StandingOrderPeriod period = [currentOrder.period intValue];
            if (period == stord_weekly) {
                //[self enableWeekly: YES];
                [weekCell setState: NSOnState];
                [monthCell setState: NSOffState];
                [self updateWeekCycles];
                [weekCyclesPopup setEnabled: currentLimits.allowChangeCycle];
                [execDaysWeekPopup setEnabled: currentLimits.allowChangeExecDay];
            } else {
                //[self enableWeekly: NO];
                [weekCell setState: NSOffState];
                [monthCell setState: NSOnState];
                [self updateMonthCycles];
                [monthCyclesPopup setEnabled: currentLimits.allowChangeCycle];
                [execDaysMonthPopup setEnabled: currentLimits.allowChangeExecDay];
            }

            [weekCell setEnabled: currentLimits.allowWeekly];
            [monthCell setEnabled: currentLimits.allowMonthly];
            
            if (!currentLimits.allowChangePeriod) {
                [weekCell setEnabled: NO];
                [monthCell setEnabled: NO];
            }
        }

        // (Re)Load the set of previously entered text for the receiver combo box.
        [receiverComboBox removeAllItems];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary   *values = [userDefaults dictionaryForKey: @"transfers"];
        if (values != nil) {
            id previousReceivers = values[@"previousReceivers"];
            if ([previousReceivers isKindOfClass: [NSArray class]]) {
                [receiverComboBox addItemsWithObjectValues: previousReceivers];
            }
        }

        // update account selector
        [self updateSourceAccountSelection];
        
        if (!self.editable) {
            [self disableCycles];
        }

        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark -
#pragma mark Drag and drop

- (BOOL)doDeletionOfOrder: (StandingOrder *)order {
    // If there is no order key yet then we are deleting a newly created standing order, which
    // has not yet been sent to the bank. So we can simply remove it from the controller.
    if (order.orderKey == nil) {
        NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP454", nil),
                                        NSLocalizedString(@"AP458", nil),
                                        NSLocalizedString(@"AP2", nil),
                                        NSLocalizedString(@"AP3", nil),
                                        nil);
        if (res != NSAlertAlternateReturn) {
            return NO;
        }
        [orderController remove: self]; // The order is currently selected.
        return YES;
    }

    // Otherwise ask to mark the order for deletion. It gets then deleted when all changes are
    // sent to the bank.
    NSInteger res = NSRunAlertPanel(NSLocalizedString(@"AP454", nil),
                                    NSLocalizedString(@"AP455", nil),
                                    NSLocalizedString(@"AP2", nil),
                                    NSLocalizedString(@"AP456", nil),
                                    nil);
    if (res != NSAlertAlternateReturn) {
        return NO;
    }

    order.toDelete = @YES;
    deleteButton.hidden = YES;

    return YES;
}

/**
 * Called when the user drags transfers to the waste basket, which represents a delete operation.
 */
- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info {
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSString     *type = [pasteboard availableTypeFromArray: @[OrderDataType]];
    if (type == nil) {
        return NO;
    }

    // There can always be only one entry in the set.
    NSData  *data = [pasteboard dataForType: type];
    NSArray *entries = [NSKeyedUnarchiver unarchiveObjectWithData: data];

    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    NSManagedObjectID      *objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [entries lastObject]];
    if (objectId == nil) {
        return NO;
    }
    StandingOrder *order = (StandingOrder *)[context objectWithID: objectId];

    return [self doDeletionOfOrder: order];
}

- (IBAction)deleteOrder: (id)sender {
    [self doDeletionOfOrder: currentOrder];
}

#pragma mark -
#pragma mark PecuniaTabItem protocol

- (NSView *)mainView {
    return mainView;
}

- (void)print {
}

- (void)activate {
    [self updateSourceAccountSelector];
}

- (void)deactivate {
}

- (void)prepare {
}

- (void)terminate {
}

@end
