/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

#import "CategoryDefWindowController.h"

#import "TimeSliceManager.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "Category.h"
#import "CategoryView.h"
#import "ShortDate.h"
#import "StatCatAssignment.h"
#import "ImageAndTextCell.h"

#import "StatementsListview.h"
#import "GraphicsAdditions.h"

#import "BWGradientBox.h"

#define BankStatementDataType @"BankStatementDataType"
#define CategoryDataType      @"CategoryDataType"

@implementation CategoryDefWindowController

@synthesize timeSliceManager;
@synthesize selectedCategory;
@synthesize hideAssignedValues;
@synthesize mainView;

- (id)init
{
    self = [super init];
    if (self != nil) {
    }
    return self;
}

- (void)awakeFromNib
{
    awaking = YES;

    // Hide values that are already assigned elsewhere, by default.
    // Intentionally use the property to have KVO working for the checkbox that mirrors this state.
    self.hideAssignedValues = YES;

    [predicateEditor addRow: self];

    // sort descriptor for transactions view
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"statement.date" ascending: NO];
    NSArray          *sds = @[sd];
    [assignPreviewController setSortDescriptors: sds];

    // Setup statements listview.
    [statementsListView bind: @"dataSource" toObject: assignPreviewController withKeyPath: @"arrangedObjects" options: nil];

    // The assignments list listens to selection changes in the statements listview (and vice versa).
    [assignPreviewController bind: @"selectionIndexes" toObject: statementsListView withKeyPath: @"selectedRows" options: nil];
    [statementsListView bind: @"selectedRows" toObject: assignPreviewController withKeyPath: @"selectionIndexes" options: nil];

    // We listen to selection changes in the list.
    [assignPreviewController addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: nil];

    statementsListView.owner = self;
    statementsListView.showAssignedIndicators = YES;
    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];

    predicatesBackground.fillColor = [NSColor colorWithCalibratedWhite: 233 / 255.0 alpha: 1];

    awaking = NO;
}

- (void)setManagedObjectContext: (NSManagedObjectContext *)context
{
    [assignPreviewController setManagedObjectContext: context];
    [assignPreviewController prepareContent];
}

- (IBAction)saveRule: (id)sender
{
    NSError *error;

    if (selectedCategory == nil) {
        return;
    }

    NSPredicate *predicate = [predicateEditor objectValue];
    if (predicate) {
        // check predicate
        NSString *rule = [predicate description];
        @try {
            [NSPredicate predicateWithFormat: rule];
        }
        @catch (NSException *error) {
            LogError(@"%@", error.debugDescription);
            NSRunAlertPanel(NSLocalizedString(@"AP113", nil),
                            NSLocalizedString(@"AP75", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil,
                            error.reason
                            );
            return;
        }

        [selectedCategory setValue: rule forKey: @"rule"];

        // save updates
        NSManagedObjectContext *context = [[MOAssistant assistant] context];
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }
        ruleChanged = NO;
    }
}

- (IBAction)deleteRule: (id)sender
{
    NSError *error;

    if (selectedCategory == nil) {
        return;
    }

    int res = NSRunAlertPanel(NSLocalizedString(@"AP307", nil),
                              NSLocalizedString(@"AP308", nil),
                              NSLocalizedString(@"AP3", nil),
                              NSLocalizedString(@"AP4", nil),
                              nil,
                              [selectedCategory localName]
                              );
    if (res != NSAlertDefaultReturn) {
        return;
    }

    [selectedCategory setValue: nil forKey: @"rule"];
    ruleChanged = NO;

    // save updates
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    if ([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    NSPredicate *pred = [NSCompoundPredicate predicateWithFormat: @"statement.purpose CONTAINS[c] ''"];
    if ([pred class] != [NSCompoundPredicate class]) {
        NSCompoundPredicate *comp = [[NSCompoundPredicate alloc] initWithType: NSOrPredicateType subpredicates: @[pred]];
        pred = comp;
    }
    [predicateEditor setObjectValue: pred];

    [self calculateCatAssignPredicate];
}

- (void)calculateCatAssignPredicate
{
    NSPredicate *pred = nil;
    NSPredicate *compoundPredicate = nil;

    // first add selected category
    if (selectedCategory == nil) {
        return;
    }

    NSMutableArray *orPreds = [NSMutableArray arrayWithCapacity: 5];

    if ([selectedCategory valueForKey: @"parent"] != nil) {
        pred = [NSPredicate predicateWithFormat: @"(category = %@)", selectedCategory];
        [orPreds addObject: pred];
    }
    NSPredicate *predicate = [predicateEditor objectValue];

    // Not assigned statements
    pred = [NSPredicate predicateWithFormat: @"(category = %@)", [Category nassRoot]];
    if (predicate != nil) {
        pred = [NSCompoundPredicate andPredicateWithSubpredicates: @[pred, predicate]];
    }
    [orPreds addObject: pred];

    // already assigned statements
    if (!hideAssignedValues) {
        pred = [NSPredicate predicateWithFormat: @"(category.isBankAcc = 0)"];
        if (predicate != nil) {
            pred = [NSCompoundPredicate andPredicateWithSubpredicates: @[pred, predicate]];
        }
        [orPreds addObject: pred];
    }

    compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates: orPreds];
    pred = [timeSliceManager predicateForField: @"date"];
    compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[compoundPredicate, pred]];

    // set new fetch predicate
    if (compoundPredicate) {
        [assignPreviewController setFetchPredicate: compoundPredicate];
    }
}

- (BOOL)categoryShouldChange
{
    if (selectedCategory == nil) {
        return YES;
    }

    if (ruleChanged) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP305", nil),
                                  NSLocalizedString(@"AP306", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  NSLocalizedString(@"AP4", nil),
                                  nil,
                                  [selectedCategory localName]
                                  );
        if (res == NSAlertDefaultReturn) {
            [self saveRule: self];
        }
        ruleChanged = NO;
    }
    return YES;
}

- (IBAction)predicateEditorChanged: (id)sender
{
    if (awaking) {
        return;
    }

    // check NSApp currentEvent for the return key
    NSEvent *event = [NSApp currentEvent];
    if ([event type] == NSKeyDown) {
        NSString *characters = [event characters];
        if ([characters length] > 0 && [characters characterAtIndex: 0] == 0x0D) {
            [self calculateCatAssignPredicate];
            ruleChanged = YES;
        }
    }

}

- (void)ruleEditorRowsDidChange: (NSNotification *)notification
{
    [self calculateCatAssignPredicate];
}

- (IBAction)hideAssignedChanged: (id)sender
{
    [self calculateCatAssignPredicate];
}

- (IBAction)assignEntries: (id)sender
{
    NSArray *entries = assignPreviewController.selectedObjects;
    if (entries.count == 0) {
        entries = assignPreviewController.arrangedObjects;
    }
    [self assignToCategory: entries];
}

- (void)assignToCategory: (NSArray *)entries
{
    if (selectedCategory == nil) {
        return;
    }

    for (StatCatAssignment *entry in entries) {
        [entry.statement assignAmount: [entry value] toCategory: selectedCategory withInfo: nil];
    }
    [selectedCategory invalidateBalance];
    [Category updateBalancesAndSums];

    NSError *error;
    if (![MOAssistant.assistant.context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (IBAction)unassignEntries: (id)sender
{
    NSArray *entries = assignPreviewController.selectedObjects;
    if (entries.count == 0) {
        entries = assignPreviewController.arrangedObjects;
    }
    [self unassignFromCategory: entries];
}

- (void)unassignFromCategory: (NSArray *)entries
{
    if (selectedCategory == nil) {
        return;
    }

    [StatCatAssignment removeAssignments: entries];

    [selectedCategory invalidateBalance];
    [Category updateBalancesAndSums];

    NSError *error;
    if (![MOAssistant.assistant.context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (void)activationChanged: (BOOL)active forIndex: (NSUInteger)index
{
    StatCatAssignment *assignment = assignPreviewController.arrangedObjects[index];
    if (assignment != nil) {
        if (active) {
            [self assignToCategory: @[assignment]];
        } else {
            [self unassignFromCategory: @[assignment]];
        }
    }
}

#pragma mark -
#pragma mark Splitview delegate methods

- (CGFloat)splitView: (NSSplitView *)splitView constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)dividerIndex
{
    return 200;
}

- (CGFloat)splitView: (NSSplitView *)splitView constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)dividerIndex
{
    return NSHeight([splitView frame]) - 200;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object change: (NSDictionary *)change context: (void *)context
{
    if (object == assignPreviewController) {
        if (assignPreviewController.selectedObjects.count == 0) {
            assignEntriesButton.title = NSLocalizedString(@"AP550", nil);
            unassignEntriesButton.title = NSLocalizedString(@"AP552", nil);
        } else {
            assignEntriesButton.title = NSLocalizedString(@"AP551", nil);
            unassignEntriesButton.title = NSLocalizedString(@"AP553", nil);
        }
        assignEntriesButton.enabled = [assignPreviewController.arrangedObjects count] > 0 && !selectedCategory.isNotAssignedCategory;
        unassignEntriesButton.enabled = [assignPreviewController.arrangedObjects count] > 0 && !selectedCategory.isNotAssignedCategory;

        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

#pragma mark -
#pragma mark PecuniaSectionItem protocol

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSFitPagination];
    NSPrintOperation *printOp;

    printOp = [NSPrintOperation printOperationWithView: topView printInfo: printInfo];

    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (NSView *)mainView
{
    return topView;
}

- (void)prepare
{
    [self calculateCatAssignPredicate];
}

- (void)activate;
{
}

- (void)deactivate
{
}

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to
{
    [self calculateCatAssignPredicate];
}

- (void)setSelectedCategory: (Category *)newCategory
{
    if (selectedCategory != newCategory) {
        selectedCategory = newCategory;

        if (selectedCategory == [Category nassRoot] || selectedCategory == [Category catRoot]) {
            [[[[predicateEditor superview] superview] animator] setHidden: YES];
            [[saveButton animator] setHidden: YES];
            [[discardButton animator] setHidden: YES];
        } else {
            [[[[predicateEditor superview] superview] animator] setHidden: NO];
            [[saveButton animator] setHidden: NO];
            [[discardButton animator] setHidden: NO];
        }

        NSString *s = [selectedCategory valueForKey: @"rule"];
        if (s == nil) {
            s = @"statement.purpose CONTAINS[c] ''";
        }
        NSPredicate *pred = [NSCompoundPredicate predicateWithFormat: s];
        if ([pred class] != [NSCompoundPredicate class]) {
            NSCompoundPredicate *comp = [[NSCompoundPredicate alloc] initWithType: NSOrPredicateType subpredicates: @[pred]];
            pred = comp;
        }
        [predicateEditor setObjectValue: pred];
        [self calculateCatAssignPredicate];
    }
}

@end
