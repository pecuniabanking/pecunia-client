/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "StatementsListview.h"

#import "MOAssistant.h"
#import "Category.h"
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

#import "NSColor+PecuniaAdditions.h"

#import "Tag.h"
#import "TagView.h"

extern void *UserDefaultsBindingContext;

//----------------------------------------------------------------------------------------------------------------------

@interface StatementsOverviewController ()
{
    NSDecimalNumber *saveValue;
    NSUInteger      lastSplitterPosition; // Last position of the splitter between list and details.

    // Sorting statements.
    int  sortIndex;
    BOOL sortAscending;
}

@end

@implementation StatementsOverviewController

@synthesize mainView;
@synthesize selectedCategory;
@synthesize toggleDetailsButton;

- (void)awakeFromNib
{
    sortAscending = NO;
    sortIndex = 0;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
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

    lastSplitterPosition = [[userDefaults objectForKey: @"rightSplitterPosition"] intValue];
    if (lastSplitterPosition > 0) {
        // The details pane was collapsed when Pecunia closed last time.
        [statementDetails setHidden: YES];
        [mainView adjustSubviews];
    }

    mainView.fixedIndex = 1;

    [self updateSorting];
    [self updateValueColors];

    // Setup statements listview.
    [statementsListView bind: @"dataSource" toObject: categoryAssignments withKeyPath: @"arrangedObjects" options: nil];

    // Bind controller to selectedRow property and the listview to the controller's
    // selectedIndex property to get notified about selection changes.
    [categoryAssignments bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: categoryAssignments withKeyPath: @"selectionIndexes" options: nil];

    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];

    [categoryAssignments addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];

    NSString * path = [[NSBundle mainBundle] pathForResource: @"icon14-1"
                                                      ofType: @"icns"
                                                 inDirectory: @"Collections/1"];
    if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
        tagButton.image = [[NSImage alloc] initWithContentsOfFile: path];
    }

    [attachment1 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref1" options: nil];
    [attachment2 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref2" options: nil];
    [attachment3 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref3" options: nil];
    [attachment4 bind: @"reference" toObject: categoryAssignments withKeyPath: @"selection.statement.ref4" options: nil];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES];
    [statementTags setSortDescriptors: @[sd]];
    [tagsController setSortDescriptors: @[sd]];
    tagButton.bordered = NO;
    
    categoryAssignments.managedObjectContext = MOAssistant.assistant.context;
    tagsController.managedObjectContext = MOAssistant.assistant.context;
    [tagsController prepareContent];

    tagViewPopup.datasource = tagsController;
    tagViewPopup.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 10];
    tagViewPopup.canCreateNewTags = YES;

    tagsField.datasource = statementTags;
    tagsField.defaultFont = [NSFont fontWithName: PreferenceController.popoverFontName size: 10];
    tagsField.canCreateNewTags = YES;

}

- (IBAction)showTagPopup: (id)sender
{
    NSButton *button = sender;
    [tagViewPopup showTagPopupAt: button.bounds forView: button host: tagViewHost];
}

#pragma mark - Sorting and searching statements

- (IBAction)filterStatements: (id)sender
{
    NSTextField *te = sender;
    NSString    *searchName = [te stringValue];

    if ([searchName length] == 0) {
        [categoryAssignments setFilterPredicate:nil];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithFormat: @"statement.purpose contains[c] %@ or statement.remoteName contains[c] %@ or userInfo contains[c] %@ or value = %@",
                             searchName, searchName, searchName, [NSDecimalNumber decimalNumberWithString: searchName locale: [NSLocale currentLocale]]];
        if (pred != nil) {
            [categoryAssignments setFilterPredicate: pred];
        }
    }
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

#pragma mark - Other actions

- (IBAction)attachmentClicked: (id)sender
{
    AttachmentImageView *image = sender;

    if (image.reference == nil) {
        // No attachment yet. Allow adding one if editing is possible.
        if (self.canEditAttachment) {
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            panel.title = NSLocalizedString(@"AP118", nil);
            panel.canChooseDirectories = NO;
            panel.canChooseFiles = YES;
            panel.allowsMultipleSelection = NO;

            int runResult = [panel runModal];
            if (runResult == NSOKButton) {
                [image processAttachment: panel.URL];
            }
        }
    } else {
        [image openReference];
    }
}

#pragma mark - General logic

- (BOOL)canEditAttachment
{
    return categoryAssignments.selectedObjects.count == 1;
}

- (void)controlTextDidBeginEditing: (NSNotification *)aNotification
{
    if ([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];
            saveValue = stat.value;
        }
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    // Value field changed (todo: replace by key value observation).
    if ([aNotification object] == valueField) {
        NSArray *sel = [categoryAssignments selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];

            // do some checks
            // amount must have correct sign
            NSDecimal d1 = [stat.statement.value decimalValue];
            NSDecimal d2 = [stat.value decimalValue];
            if (d1._isNegative != d2._isNegative) {
                NSBeep();
                stat.value = saveValue;
                return;
            }

            // amount must not be higher than original amount
            if (d1._isNegative) {
                if ([stat.value compare: stat.statement.value] == NSOrderedAscending) {
                    NSBeep();
                    stat.value = saveValue;
                    return;
                }
            } else {
                if ([stat.value compare: stat.statement.value] == NSOrderedDescending) {
                    NSBeep();
                    stat.value = saveValue;
                    return;
                }
            }

            // [Category updateCatValues] invalidates the selection we got. So re-set it first and then update.
            [categoryAssignments setSelectedObjects: sel];

            [stat.statement updateAssigned];
            [selectedCategory invalidateBalance];
            [Category updateCatValues];
            [statementsListView updateVisibleCells];
        }
    }
}

- (BOOL)validateMenuItem: (NSMenuItem *)item
{
    if ([item action] == @selector(deleteStatement:)) {
        if (!selectedCategory.isBankAccount || categoryAssignments.selectedObjects.count == 0) {
            return NO;
        }
    }
    if ([item action] == @selector(splitStatement:)) {
        if (categoryAssignments.selectedObjects.count != 1) {
            return NO;
        }
    }
    return YES;
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
            statementsListView.canShowHeaders = NO;
            key = @"statement.remoteName";
            break;

        case 2:
            statementsListView.canShowHeaders = NO;
            key = @"statement.purpose";
            break;

        case 3:
            statementsListView.canShowHeaders = NO;
            key = @"statement.categoriesDescription";
            break;

        case 4:
            statementsListView.canShowHeaders = NO;
            key = @"value";
            break;

        default: {
            statementsListView.canShowHeaders = YES;
            key = @"statement.date";
            break;
        }
    }
    [categoryAssignments setSortDescriptors: @[[[NSSortDescriptor alloc] initWithKey: key ascending: sortAscending]]];
}

- (void)deleteSelectedStatements
{
    // Process all selected assignments. If only a single assignment is selected then do an extra round
    // regarding duplication check and confirmation from the user. Otherwise just confirm the delete operation as such.
    NSArray *assignments = [categoryAssignments selectedObjects];
    BOOL    doDuplicateCheck = assignments.count == 1;

    if (!doDuplicateCheck) {
        int result = NSRunAlertPanel(NSLocalizedString(@"AP806", nil),
                                     NSLocalizedString(@"AP809", nil),
                                     NSLocalizedString(@"AP3", nil),
                                     NSLocalizedString(@"AP4", nil),
                                     nil, assignments.count);
        if (result != NSAlertDefaultReturn) {
            return;
        }
    }

    NSManagedObjectContext *context = MOAssistant.assistant.context;
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
                if (res == NSAlertDefaultReturn) {
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

            [context deleteObject: statement];

            // Rebuild balances - only for manual accounts.
            if (isManualAccount) {
                NSPredicate *balancePredicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", account, statement.date];
                request.predicate = balancePredicate;
                NSArray *remainingStatements = [context executeFetchRequest: request error: &error];
                if (error != nil) {
                    NSAlert *alert = [NSAlert alertWithError: error];
                    [alert runModal];
                    return;
                }

                for (BankStatement *remainingStatement in remainingStatements) {
                    remainingStatement.saldo = [remainingStatement.saldo decimalNumberBySubtracting: statement.value];
                }
                account.balance = [account.balance decimalNumberBySubtracting: statement.value];
            }
        }
    }

    for (BankAccount *account in affectedAccounts) {
        // Special behaviour for top bank accounts.
        if (account.accountNumber == nil) {
            [context processPendingChanges];
        }
        [account updateBoundAssignments];
    }

    [[Category bankRoot] rollupRecursive: YES];
    [categoryAssignments prepareContent];
}

- (void)splitSelectedStatement
{
    NSArray *sel = [categoryAssignments selectedObjects];
    if (sel != nil && [sel count] == 1) {
        StatSplitController *splitController = [[StatSplitController alloc] initWithStatement: [sel[0] statement]];
        [NSApp runModalForWindow: [splitController window]];
    }
}

/**
 * Shows or hides the statement details pane and returns YES if the pane is now visible, NO otherwise.
 */
- (BOOL)toggleDetailsPane
{
    BOOL result;
    NSView *firstChild = (mainView.subviews)[0];
    if (lastSplitterPosition == 0) {
        [statementDetails setHidden: YES];
        lastSplitterPosition = NSHeight(firstChild.frame);
        [mainView adjustSubviews];
        result = NO;
    } else {
        [statementDetails setHidden: NO];
        NSRect frame = firstChild.frame;
        frame.size.height = lastSplitterPosition;
        firstChild.frame = frame;
        [mainView adjustSubviews];
        lastSplitterPosition = 0;
        result = YES;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue: @((int)lastSplitterPosition) forKey: @"rightSplitterPosition"];

    return result;
}

- (void)reloadList
{
    // Updating the assignments (statements) list kills the current selection, so we preserve it here.
    // Reassigning it after the update has the neat side effect that the details pane is properly updated too.
    NSUInteger selection = categoryAssignments.selectionIndex;
    categoryAssignments.selectionIndex = NSNotFound;
    [statementsListView reloadData];
    categoryAssignments.selectionIndex = selection;
}

- (void)updateValueColors
{
    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};

    NSNumberFormatter *formatter = [valueField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [valueField setNeedsDisplay];

    formatter = [nassValueField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [nassValueField setNeedsDisplay];

    formatter = [sumField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [sumField setNeedsDisplay];

    formatter = [originalAmountField.cell formatter];
    [formatter setTextAttributesForPositiveValues: positiveAttributes];
    [formatter setTextAttributesForNegativeValues: negativeAttributes];
    [originalAmountField setNeedsDisplay];
}

#pragma mark - Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainView) {
        return 240;
    }
    return proposedMin;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainView) {
        return NSHeight([mainView frame]) - 300;
    }
    return proposedMax;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainSplitPosition: (CGFloat)proposedPosition ofSubviewAt: (NSInteger)dividerIndex
{
    if (splitView == mainView) {
        // This function is called only when dragging the divider with the mouse. If the details pane is currently collapsed
        // then it is automatically shown when dragging the divider. So we have to reset our interal state.
        if (lastSplitterPosition > 0) {
            lastSplitterPosition = 0;
            [toggleDetailsButton setImage: [NSImage imageNamed: @"hide"]];
        }
    }

    return proposedPosition;
}

#pragma mark - KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
         if ([keyPath isEqualToString: @"colors"]) {
            [self updateValueColors];
            return;
        }

        return;
    }

    if (object == categoryAssignments) {
        static NSIndexSet *oldIdx;

        if ([keyPath isEqualToString: @"selectionIndexes"]) {
            // Selection did change.
            // Check if selection really changed
            NSIndexSet *selIdx = categoryAssignments.selectionIndexes;
            if (oldIdx == nil && selIdx == nil) {
                return;
            }
            if (oldIdx != nil && selIdx != nil) {
                if ([oldIdx isEqualTo:selIdx]) {
                    return;
                }
            }
            oldIdx = selIdx;

            // If the currently selected entry is a new one remove the "new" mark.
            NSDecimalNumber *firstValue = nil;
            BankStatementType firstStatementType = StatementType_Standard;
            for (StatCatAssignment *stat in [categoryAssignments selectedObjects]) {
                if (firstValue == nil) {
                    firstValue = stat.statement.value;
                    firstStatementType = stat.statement.type.intValue;
                }
                if ([stat.statement.isNew boolValue]) {
                    stat.statement.isNew = @NO;
                    BankAccount *account = stat.statement.account;
                    account.unread = account.unread - 1;
                    if (account.unread == 0) {
                        [BankingController.controller updateUnread];
                    }
                }
            }
            [(id)BankingController.controller.accountsView setNeedsDisplay: YES];

            // Check for the type of transaction and adjust remote name display accordingly.
            if (firstStatementType == StatementType_CreditCard) {
                [remoteNameLabel setStringValue: NSLocalizedString(@"AP221", nil)];
            } else {
                if ([firstValue compare: [NSDecimalNumber zero]] == NSOrderedAscending) {
                    [remoteNameLabel setStringValue: NSLocalizedString(@"AP208", nil)];
                } else {
                    [remoteNameLabel setStringValue: NSLocalizedString(@"AP209", nil)];
                }
            }

            [statementDetails setNeedsDisplay: YES];
            [BankingController.controller updateStatusbar];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark - PecuniaSectionItem protocol

- (void)activate
{

}

- (void)deactivate
{

}

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to
{

}

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    NSPrintOperation *printOp;
    NSView           *view = [[BankStatementPrintView alloc] initWithStatements: [categoryAssignments arrangedObjects] printInfo: printInfo];
    printOp = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (void)setSelectedCategory: (Category *)newCategory
{
    if (selectedCategory != newCategory) {
        selectedCategory = newCategory;

        BOOL editable = NO;
        if (!newCategory.isBankAccount && newCategory != Category.nassRoot && newCategory != Category.catRoot) {
            editable = categoryAssignments.selectedObjects.count == 1;
        }

        // value field
        [valueField setEditable: editable];
        if (editable) {
            [valueField setDrawsBackground: YES];
            [valueField setBackgroundColor: [NSColor whiteColor]];
        } else {
            [valueField setDrawsBackground: NO];
        }
    }
}

- (void)terminate
{
    selectedCategory = nil;
    [statementsListView unbind: @"dataSource"];
    [categoryAssignments unbind: @"selectionIndexes"];
    [statementsListView unbind: @"selectedRows"];
    [categoryAssignments removeObserver: self forKeyPath: @"selectionIndexes"];

    [attachment1 unbind: @"reference"];
    [attachment2 unbind: @"reference"];
    [attachment3 unbind: @"reference"];
    [attachment4 unbind: @"reference"];

    tagViewPopup.datasource = nil;
    tagsField.datasource = nil;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver: self forKeyPath: @"colors"];
    [userDefaults setValue: @((int)lastSplitterPosition) forKey: @"rightSplitterPosition"];
}

@end
