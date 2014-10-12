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
#import "BankingCategory.h"
#import "CategoryView.h"
#import "ShortDate.h"
#import "StatCatAssignment.h"
#import "ImageAndTextCell.h"

#import "StatementsListview.h"
#import "GraphicsAdditions.h"

#import "NSString+PecuniaAdditions.h"

@interface CategoryDefWindowController ()
{
    IBOutlet NSArrayController  *assignPreviewController;
    IBOutlet NSPredicateEditor  *predicateEditor;
    IBOutlet NSView             *topView;
    IBOutlet StatementsListView *statementsListView;
    IBOutlet NSButton           *saveButton;
    IBOutlet NSButton           *discardButton;
    IBOutlet NSButton           *assignEntriesButton;
    IBOutlet NSButton           *unassignEntriesButton;

    IBOutlet NSPredicateEditorRowTemplate *numberMatchRowTemplate;

    TimeSliceManager *timeSliceManager;
    BOOL             awaking;
}

@property (strong) IBOutlet NSSplitView *splitter;

@property BOOL ruleChanged;

@end

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
    statementsListView.cellSpacing = 0;
    statementsListView.allowsEmptySelection = YES;
    statementsListView.allowsMultipleSelection = YES;

    // The number text field in the number row template is much too narrow. Widen it to be able to enter larger numbers.
    NSView *numberTextField = [numberMatchRowTemplate.templateViews objectAtIndex: 2];
    NSRect frame = numberTextField.frame;
    frame.size.width = 100;
    numberTextField.frame = frame;

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
        self.ruleChanged = NO;
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
    self.ruleChanged = NO;

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

/**
 * Examines the given predicate if it contains some of our template values and constructs the appropriate real
 * predicate for that. Also triggers processing for subpredicates.
 */
- (NSPredicate *)processPredicate: (NSPredicate *)predicate {
    if (predicate == nil) {
        return nil;
    }

    if ([predicate isKindOfClass: [NSCompoundPredicate class]]) {
        NSCompoundPredicate *parent = (NSCompoundPredicate *)predicate;
        NSArray *subPredicates = parent.subpredicates;
        NSMutableArray *newSubPredicates = [NSMutableArray new];
        for (NSPredicate *subpredicate in subPredicates) {
            [newSubPredicates addObject: [self processPredicate: subpredicate]];
        }
        if (![subPredicates isEqualToArray: newSubPredicates]) {
            return [[NSCompoundPredicate alloc] initWithType: parent.compoundPredicateType subpredicates: newSubPredicates];
        }
        return predicate;
    }

    // A simple predicate.
    // Check for special predicates for certain properties of the statement. For those we have to recreate
    // the real predicate.
    NSString *predicateString = predicate.description;

    NSArray *components = [predicateString componentsSeparatedByString: @"$"];
    if (components.count > 1) {
        // Marker found. The template value is the second last part in the string then.
        NSString *template = components[components.count - 2];
        BOOL isEquality = [predicateString hasSubstring: @"=="];
        if ([template isEqualToString: @"tags"]) {
            if (isEquality) {
                return [NSPredicate predicateWithFormat: @"ANY statement.tags.caption != nil"];
            } else {
                return [NSPredicate predicateWithFormat: @"NOT (ANY statement.tags.caption != nil)"];
            }
        }

        if ([template isEqualToString: @"refs"]) {
            if (isEquality) {
                return [NSPredicate predicateWithFormat: @"statement.ref1 != nil or statement.ref2 != nil or statement.ref3 != nil or statement.ref4 != nil"];
            } else {
                return [NSPredicate predicateWithFormat: @"statement.ref1 = nil and statement.ref2 = nil and statement.ref3 = nil and statement.ref4 = nil"];
            }
        }

        // Any other template value stands for a property in the statement.
        if (isEquality) {
            return [NSPredicate predicateWithFormat: [NSString stringWithFormat: @"statement.%@ != 0", template]];
        } else {
            return [NSPredicate predicateWithFormat: [NSString stringWithFormat: @"statement.%@ == 0", template]];
        }
    }

    return predicate;
}

- (void)calculateCatAssignPredicate
{
    NSPredicate *pred = nil;
    NSPredicate *pred2 = nil;
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
    NSPredicate *predicate = [self processPredicate: predicateEditor.objectValue];

    // Not assigned statements
    pred = [NSPredicate predicateWithFormat: @"(category = %@)", [BankingCategory nassRoot]];
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
    pred2 = [NSPredicate predicateWithFormat: @"(statement.isPreliminary = 0)"];
    compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[compoundPredicate, pred, pred2]];

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

    if (self.ruleChanged) {
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
        self.ruleChanged = NO;
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
            self.ruleChanged = YES;
        }
    }

}

- (void)ruleEditorRowsDidChange: (NSNotification *)notification
{
    self.ruleChanged = YES;
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
    [BankingCategory updateBalancesAndSums];

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
    [BankingCategory updateBalancesAndSums];

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

- (void)setSelectedCategory: (BankingCategory *)newCategory
{
    if (selectedCategory != newCategory) {
        selectedCategory = newCategory;

        if (selectedCategory == [BankingCategory nassRoot] || selectedCategory == [BankingCategory catRoot]) {
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
        predicateEditor.objectValue = pred;
        [self calculateCatAssignPredicate];
        self.ruleChanged = NO;
    }
}

@end
