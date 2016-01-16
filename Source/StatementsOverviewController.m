/**
 * Copyright (c) 2013, 2015, Pecunia Project. All rights reserved.
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

#import "StatementsOverviewController.h"

#import "MessageLog.h"

#import "MOAssistant.h"
#import "BankingCategory.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"
#import "BankStatementPrintView.h"
#import "BankAccount.h"
#import "StatSplitController.h"
#import "PreferenceController.h"
#import "StatementDetails.h"
#import "PecuniaSplitView.h"
#import "AttachmentImageView.h"
#import "BankingController.h"
#import "BankStatementController.h"
#import "HBCIController.h"

#import "NSColor+PecuniaAdditions.h"
#import "NSImage+PecuniaAdditions.h"

extern void *UserDefaultsBindingContext;
extern NSString *const BankStatementDataType;

//----------------------------------------------------------------------------------------------------------------------

@interface StatementsOverviewController () {
    NSDecimalNumber *saveValue;

    // Sorting statements.
    int  sortIndex;
    BOOL sortAscending;

    IBOutlet NSArrayController  *categoryAssignments;
    __weak IBOutlet StatementsTable *statementsTable;

    IBOutlet NSTextField *selectedSumField;
    IBOutlet NSTextField *totalSumField;

    IBOutlet NSSegmentedControl *sortControl;
}

@end

@implementation StatementsOverviewController

@synthesize selectedCategory;

- (void)awakeFromNib {
    sortAscending = NO;
    sortIndex = 0;

    selectedSumField.formatter = [NSNumberFormatter sharedFormatter: NO blended: NO];
    totalSumField.formatter = [NSNumberFormatter sharedFormatter: NO blended: NO];

    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    if ([userDefaults objectForKey: @"mainSortIndex"]) {
        sortIndex = [[userDefaults objectForKey: @"mainSortIndex"] intValue];
        if (sortIndex < 0 || sortIndex >= sortControl.segmentCount) {
            sortIndex = 0;
        }
        sortControl.selectedSegment = sortIndex;
    }

    if ([userDefaults objectForKey: @"mainSortAscending"]) {
        sortAscending = [[userDefaults objectForKey: @"mainSortAscending"] boolValue];
    }
    
    [userDefaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"markNAStatements" options: 0 context: UserDefaultsBindingContext];
    [userDefaults addObserver: self forKeyPath: @"markNewStatements" options: 0 context: UserDefaultsBindingContext];

    [self updateSorting];
    [self updateValueColors];

    [categoryAssignments addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];
    categoryAssignments.managedObjectContext = MOAssistant.sharedAssistant.context;

    [statementsTable setDraggingSourceOperationMask: NSDragOperationEvery forLocal: YES];
    [statementsTable setDraggingSourceOperationMask: NSDragOperationEvery forLocal: NO];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver: self];
    [NSUserDefaults.standardUserDefaults removeObserver: self forKeyPath: @"markNAStatements"];
    [NSUserDefaults.standardUserDefaults removeObserver: self forKeyPath: @"markNewStatements"];
}

- (void)updateStatementsTable {
    [statementsTable setNeedsDisplay];
}

#pragma mark - Sorting and searching statements

- (IBAction)filterStatements: (id)sender
{
    NSTextField *te = sender;
    NSString    *searchName = [te stringValue];

    if ([searchName length] == 0) {
        [categoryAssignments setFilterPredicate: nil];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                             searchName, searchName, searchName, [NSDecimalNumber decimalNumberWithString: searchName locale: [NSLocale currentLocale]]];
        if (pred != nil) {
            [categoryAssignments setFilterPredicate: pred];
        }
    }
}

- (void)clearStatementFilter
{
    [categoryAssignments setFilterPredicate:nil];
}

- (IBAction)sortingChanged: (id)sender
{
    if ([sender selectedSegment] == sortIndex) {
        sortAscending = !sortAscending;
    } else {
        sortAscending = NO; // Per default entries are sorted by date in decreasing order.
    }

    [self updateSorting];
}

#pragma mark - General logic

- (BOOL)canEditAttachment
{
    return categoryAssignments.selectedObjects.count == 1;
}

- (void)updateSorting
{
    [sortControl setImage: nil forSegment: sortIndex];
    sortIndex = [sortControl selectedSegment];
    if (sortIndex < 0) {
        sortIndex = 0;
    }
    NSImage *sortImage = sortAscending ? [NSImage imageNamed: @"sort-indicator-inc"] : [NSImage imageNamed: @"sort-indicator-dec"];
    [sortControl setImage: sortImage forSegment: sortIndex];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: @((int)sortIndex) forKey: @"mainSortIndex"];
    [userDefaults setValue: @(sortAscending) forKey: @"mainSortAscending"];

    NSString *key;
    switch (sortIndex) {
        case 1:
            //statementsListView.canShowHeaders = NO;
            key = @"statement.remoteName";
            break;

        case 2:
            //statementsListView.canShowHeaders = NO;
            key = @"statement.purpose";
            break;

        case 3:
            //statementsListView.canShowHeaders = NO;
            key = @"statement.categoriesDescription";
            break;

        case 4:
            //statementsListView.canShowHeaders = NO;
            key = @"value";
            break;

        default: {
            //statementsListView.canShowHeaders = YES;
            key = @"statement.date";
            break;
        }
    }
    [categoryAssignments setSortDescriptors: @[[[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending]]];
    [categoryAssignments rearrangeObjects];
}

- (void)deleteSelectedStatements
{
    // Process all selected assignments. If only a single assignment is selected then do an extra round
    // regarding duplication check and confirmation from the user. Otherwise just confirm the delete operation as such.
    NSArray *assignments;
    if (statementsTable.clickedRow > -1 && ![statementsTable isRowSelected: statementsTable.clickedRow]) {
        assignments = [NSArray arrayWithObject: categoryAssignments.arrangedObjects[statementsTable.clickedRow]];
    } else {
        assignments = [categoryAssignments selectedObjects];
    }

    BOOL doDuplicateCheck = assignments.count == 1;

    if (!doDuplicateCheck) {
        int result = NSRunAlertPanel(NSLocalizedString(@"AP806", nil),
                                     NSLocalizedString(@"AP809", nil),
                                     NSLocalizedString(@"AP4", nil),
                                     NSLocalizedString(@"AP3", nil),
                                     nil, assignments.count);
        if (result != NSAlertAlternateReturn) {
            return;
        }
    }

    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSMutableSet *affectedAccounts = [[NSMutableSet alloc] init];
    for (StatCatAssignment *assignment in assignments) {
        BankStatement *statement = assignment.statement;

        NSError *error = nil;
        BOOL    deleteStatement = NO;

        if (doDuplicateCheck) {
            // Check if this statement is a duplicate. Select all statements with same date.
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date = %@)", statement.account, statement.date];
            [request setPredicate: predicate];

            NSArray *possibleDuplicates = [context executeFetchRequest: request error: &error];
            if (error) {
                NSAlert *alert = [NSAlert alertWithError: error];
                [alert runModal];
                return;
            }

            BOOL hasDuplicate = NO;
            for (BankStatement *possibleDuplicate in possibleDuplicates) {
                if (possibleDuplicate != statement && [possibleDuplicate matches: statement]) {
                    hasDuplicate = YES;
                    break;
                }
            }
            int res;
            if (hasDuplicate) {
                res = NSRunAlertPanel(NSLocalizedString(@"AP805", nil),
                                      NSLocalizedString(@"AP807", nil),
                                      NSLocalizedString(@"AP4", nil),
                                      NSLocalizedString(@"AP3", nil),
                                      nil);
                if (res == NSAlertAlternateReturn) {
                    deleteStatement = YES;
                }
            } else {
                res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP805", nil),
                                              NSLocalizedString(@"AP808", nil),
                                              NSLocalizedString(@"AP4", nil),
                                              NSLocalizedString(@"AP3", nil),
                                              nil);
                if (res == NSAlertAlternateReturn) {
                    deleteStatement = YES;
                }
            }
        } else {
            deleteStatement = YES;
        }

        if (deleteStatement) {
            BOOL isManualAccount = [statement.account.isManual boolValue];
            BankAccount *account = statement.account;
            [affectedAccounts addObject: account]; // Automatically ignores duplicates.

            [context deleteObject: assignment];
            [context deleteObject: statement];

            // Remove deleted amount from the acount's balance, so we can recompute the intermittant values at the end.
            if (isManualAccount) {
                account.balance = [account.balance decimalNumberBySubtracting: statement.value];
            }
        }
    }
    
    for (BankAccount *account in affectedAccounts) {
        [account invalidateCacheIncludeParents: YES recursive: NO];
    }
    
    [context processPendingChanges];
    for (BankAccount *account in affectedAccounts) {
        [account updateAssignmentsForReportRange];
        [account updateStatementBalances];
    }
    [[BankingCategory bankRoot] updateCategorySums];
    [categoryAssignments prepareContent];
}

- (void)splitSelectedStatement
{
    // Only a single statement can be split.
    StatCatAssignment *assignment;
    if (statementsTable.clickedRow > -1 && ![categoryAssignments.selectionIndexes containsIndex: statementsTable.clickedRow]) {
        assignment = categoryAssignments.arrangedObjects[statementsTable.clickedRow];
    } else {
        assignment = categoryAssignments.selectedObjects.lastObject;
    }

    StatSplitController *splitController = [[StatSplitController alloc] initWithStatement: assignment.statement];
    [NSApp runModalForWindow: [splitController window]];
}

- (void)markSelectedStatementsRead {
    NSArray *assignments;
    if (statementsTable.clickedRow > -1 && ![categoryAssignments.selectionIndexes containsIndex: statementsTable.clickedRow]) {
        assignments = [[NSArray alloc] initWithObjects: categoryAssignments.arrangedObjects[statementsTable.clickedRow], nil];
    } else {
        assignments = categoryAssignments.selectedObjects;
    }

    if (assignments.count > 0) {
        for (StatCatAssignment *assignment in assignments) {
            assignment.statement.isNew = @NO;
        }
        [BankingController.controller updateUnread];
    }
}

- (void)markSelectedStatementsUnread {
    NSArray *assignments;
    if (statementsTable.clickedRow > -1 && ![categoryAssignments.selectionIndexes containsIndex: statementsTable.clickedRow]) {
        assignments = [[NSArray alloc] initWithObjects: categoryAssignments.arrangedObjects[statementsTable.clickedRow], nil];
    } else {
        assignments = categoryAssignments.selectedObjects;
    }

    if (assignments.count > 0) {
        for (StatCatAssignment *assignment in assignments) {
            if (!assignment.statement.isPreliminary.boolValue) {
                assignment.statement.isNew = @YES;
            }
        }
        [BankingController.controller updateUnread];
    }
}

- (void)updateValueColors
{
    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};

    NSNumberFormatter *formatter = [selectedSumField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [selectedSumField setNeedsDisplay];

    formatter = [totalSumField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [totalSumField setNeedsDisplay];
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
         if ([keyPath isEqualToString: @"colors"]) {
            [self updateValueColors];
             statementsTable.needsDisplay = true;
            return;
        }

        if ([keyPath isEqualToString: @"markNAStatements"]) {
            statementsTable.needsDisplay = true;
            return;
        }

        if ([keyPath isEqualToString: @"markNewStatements"]) {
            statementsTable.needsDisplay = true;
            return;
        }

        return;
    }

    if (object == categoryAssignments) {
        static NSIndexSet *oldIdx;

        if ([keyPath isEqualToString: @"selectionIndexes"]) {
            NSIndexSet *selIdx = categoryAssignments.selectionIndexes;
            if (oldIdx == nil && selIdx == nil) {
                return;
            }
            if (oldIdx != nil && selIdx != nil) {
                if ([oldIdx isEqualTo: selIdx]) {
                    return;
                }
            }
            oldIdx = selIdx;

            // If the currently selected entry is marked as unread mark it now as read (if that is enabled).
            if ([NSUserDefaults.standardUserDefaults boolForKey: @"autoResetNew"]) {
                BOOL needUnreadUpdate = NO;
                for (StatCatAssignment *assignment in categoryAssignments.selectedObjects) {
                    if (assignment.statement.isNew.boolValue) {
                        needUnreadUpdate = YES;
                        assignment.statement.isNew = @NO;
                    }
                }
                if (needUnreadUpdate) {
                    [BankingController.controller updateUnread];
                }
            }
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark - Table View delegate methods

- (id)tableView: (NSTableView *)table viewForTableColumn: (nullable NSTableColumn *)tableColumn row: (NSInteger)row {
    return [table makeViewWithIdentifier: @"DataCellView" owner: table];
}

- (CGFloat)tableView: (NSTableView *)tableView heightOfRow: (NSInteger)row {
    return 70;
}

- (id)tableView: (NSTableView *)tableView rowViewForRow: (NSInteger)row {
    return [StatementsTableRowView new];
}

- (BOOL)tableView: (NSTableView *)tableView shouldTypeSelectForEvent: (nonnull NSEvent *)event withCurrentSearchString: (nullable NSString *)searchString {
    return NO;
}

- (BOOL)tableView: (NSTableView *)tableView writeRowsWithIndexes: (nonnull NSIndexSet *)rowIndexes toPasteboard: (nonnull NSPasteboard *)pboard {

    NSMutableArray *uris = [NSMutableArray arrayWithCapacity: rowIndexes.count];
    [rowIndexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL * _Nonnull stop) {
        StatCatAssignment *assignment = categoryAssignments.arrangedObjects[idx];
        if (!assignment.statement.isPreliminary.boolValue) {
            [uris addObject: assignment.objectID.URIRepresentation];
        }
    }];

    if (uris.count == 0) {
        return NO;
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: uris];
    [pboard declareTypes: @[BankStatementDataType] owner: self];
    [pboard setData: data forType: BankStatementDataType];
    
    return YES;
}

#pragma mark - Menu handling

- (void)menuAction: (NSMenuItem *)item {
    LogEnter;

    NSArray *assignments;
    if (![categoryAssignments.selectionIndexes containsIndex: statementsTable.clickedRow]) {
        assignments = [[NSArray alloc] initWithObjects: categoryAssignments.arrangedObjects[statementsTable.clickedRow], nil];
    } else {
        assignments = categoryAssignments.selectedObjects;
    }

    switch (item.tag) {
        case StatementMenuActionShowDetails: // Only called for single selection.
            [statementsTable toggleStatementDetails];
            break;

        case StatementMenuActionAddStatement:
            if (selectedCategory.accountNumber != nil) {
                BankStatementController *controller = [[BankStatementController alloc] initWithAccount: (BankAccount *)selectedCategory
                                                                                             statement: nil];

                int res = [NSApp runModalForWindow: controller.window];
                if (res != 0) {
                    [selectedCategory updateAssignmentsForReportRange];
                }
            }

            break;

        case StatementMenuActionSplitStatement:
            [self splitSelectedStatement];
            break;

        case StatementMenuActionDeleteStatement:
            [self deleteSelectedStatements];
            break;

        case StatementMenuActionMarkRead:
            [self markSelectedStatementsRead];
            break;

        case StatementMenuActionMarkUnread:
            [self markSelectedStatementsUnread];
            break;

        case StatementMenuActionStartTransfer: {
            BankAccount *account = [assignments[0] statement].account;
            if ([[HBCIController controller] isTransferSupported: TransferTypeSEPA forAccount: account]) {
                [BankingController.controller startTransferOfType: TransferTypeSEPA
                                                      fromAccount: account
                                                        statement: [assignments[0] statement]];
            } else {
                if ([[HBCIController controller] isTransferSupported: TransferTypeInternalSEPA forAccount: account]) {
                    [BankingController.controller startTransferOfType: TransferTypeInternalSEPA
                                                          fromAccount: account
                                                            statement: [assignments[0] statement]];
                }
            }
            break;
        }

        case StatementMenuActionCreateTemplate: {
            BankAccount *account = [assignments[0] statement].account;
            if ([[HBCIController controller] isTransferSupported: TransferTypeSEPA forAccount: account]) {
                [BankingController.controller createTemplateOfType: TransferTypeSEPA fromStatement: [assignments[0] statement]];
            } else {
                if ([[HBCIController controller] isTransferSupported: TransferTypeInternalSEPA forAccount: account]) {
                    [BankingController.controller createTemplateOfType: TransferTypeInternalSEPA fromStatement: [assignments[0] statement]];
                }
            }
            break;
        }
    }

    LogLeave;
}

- (void)menuNeedsUpdate: (NSMenu *)menu {
    LogEnter;

    [menu removeAllItems];
    BOOL isManualAccount = NO;

    if (selectedCategory.isBankAccount && !selectedCategory.isBankingRoot) {
        isManualAccount = [(BankAccount *)selectedCategory isManual].boolValue;
    }

    NSMenuItem *item;
    if (isManualAccount) {
        item = [menu addItemWithTitle: NSLocalizedString(@"AP238", nil)
                               action: @selector(menuAction:)
                        keyEquivalent: @"n"];
        item.target = self;
        item.keyEquivalentModifierMask = NSCommandKeyMask;
        item.tag = StatementMenuActionAddStatement;

        [menu addItem: NSMenuItem.separatorItem];
    }
    item = [menu addItemWithTitle: NSLocalizedString(@"AP240", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: @" "];
    item.target = self;
    item.keyEquivalentModifierMask = 0;
    item.tag = StatementMenuActionShowDetails;

    item = [menu addItemWithTitle: NSLocalizedString(@"AP233", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: @"s"];
    item.target = self;
    item.tag = StatementMenuActionSplitStatement;

    item = [menu addItemWithTitle: NSLocalizedString(@"AP234", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: [NSString stringWithFormat: @"%c", NSBackspaceCharacter]];
    item.target = self;
    item.tag = StatementMenuActionDeleteStatement;

    [menu addItem: NSMenuItem.separatorItem];

    __block BOOL allRead = YES;
    if (![categoryAssignments.selectionIndexes containsIndex: statementsTable.clickedRow]) {
        allRead = ![categoryAssignments.arrangedObjects[statementsTable.clickedRow] statement].isNew.boolValue;
    } else {
        for (StatCatAssignment *assignment in categoryAssignments.selectedObjects) {
            if (assignment.statement.isNew.boolValue) {
                allRead = NO;
                break;
            }
        }
    }
    item = [menu addItemWithTitle: allRead ? NSLocalizedString(@"AP235", nil): NSLocalizedString(@"AP239", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: @""];
    item.target = self;
    item.tag = allRead ? StatementMenuActionMarkUnread : StatementMenuActionMarkRead;

    if (!isManualAccount) {
        [menu addItem: [NSMenuItem separatorItem]];
        item = [menu addItemWithTitle: NSLocalizedString(@"AP236", nil)
                               action: @selector(menuAction:)
                        keyEquivalent: @""];
        item.target = self;
        item.tag = StatementMenuActionStartTransfer;
    }

    item = [menu addItemWithTitle: NSLocalizedString(@"AP237", nil)
                           action: @selector(menuAction:)
                    keyEquivalent: @""];
    item.target = self;
    item.tag = StatementMenuActionCreateTemplate;

    LogLeave;
}

- (BOOL)validateMenuItem: (NSMenuItem *)item
{
    if (item.target != self) { // Call from the main menu.
        if (item.action == @selector(deleteStatement:)) {
            return categoryAssignments.selectedObjects.count > 0;
        }

        if (item.action == @selector(splitStatement:)) {
            return categoryAssignments.selectedObjects.count == 1;

            StatCatAssignment *stat = categoryAssignments.selectedObjects.lastObject;
            return !stat.statement.isPreliminary.boolValue;
        }

        if (item.action == @selector(markSelectedUnread:)) {
            return categoryAssignments.selectedObjects.count > 0;
        }
    } else {
        // Call from the context menu.
        BOOL isManualAccount = NO;
        if (selectedCategory.isBankAccount && !selectedCategory.isBankingRoot) {
            isManualAccount = [(BankAccount *)selectedCategory isManual].boolValue;
        }

        // Determine the selected assignement, if there is only one.
        StatCatAssignment *singleAssignment = nil;
        if (![categoryAssignments.selectionIndexes containsIndex: statementsTable.clickedRow]
            || (categoryAssignments.selectedObjects.count == 1)) {
            singleAssignment = categoryAssignments.arrangedObjects[statementsTable.clickedRow];
        }

        BOOL isPreliminary = (singleAssignment == nil) ? NO : singleAssignment.statement.isPreliminary.boolValue;

        switch (item.tag) {
            case StatementMenuActionShowDetails:
                return singleAssignment != nil;

            case StatementMenuActionSplitStatement:
            case StatementMenuActionStartTransfer:
            case StatementMenuActionCreateTemplate:
                return singleAssignment != nil && !isPreliminary;

            case StatementMenuActionMarkUnread:
            case StatementMenuActionMarkRead:
                return !isPreliminary;

            case StatementMenuActionDeleteStatement:
                item.title = NSLocalizedString((singleAssignment == nil) ? @"AP806" : @"AP805", nil);
                break;
        }
    }
    
    return YES;
}

#pragma mark - PecuniaSectionItem protocol

- (void)activate {
}

- (void)deactivate {
}

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to {
}

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];

    // Set the maxium possible print area.
    // Note: there's a minimum marging area set by the printer. Values below that only confuse
    //       the print preview page size computation. NSPrintInfo.imageablePageBounds is supposed to have that info
    //       but returns, at least for my printer, twice as large vertical margins as what are really possible.
    printInfo.topMargin = 20;
    printInfo.bottomMargin = 20;
    printInfo.leftMargin = 18;
    printInfo.rightMargin = 18;

    NSPrintOperation *printOp;
    NSView *view = [[BankStatementPrintView alloc] initWithStatements: [categoryAssignments arrangedObjects]
                                                            printInfo: printInfo
                                                                title: nil
                                                             category: selectedCategory
                                                       additionalText: nil];
    printOp = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (void)setSelectedCategory: (BankingCategory *)newCategory
{
    if (selectedCategory != newCategory) {
        selectedCategory = newCategory;
    }
}

- (void)terminate
{
    categoryAssignments.content = nil;
}

@end
