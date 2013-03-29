/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import "CategoryDefWindowController.h"

#import "CatAssignClassification.h"
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

#define BankStatementDataType	@"BankStatementDataType"
#define CategoryDataType		@"CategoryDataType"

@implementation CategoryDefWindowController

@synthesize timeSliceManager;
@synthesize category = currentCategory;

- (id)init
{
    self = [super init];
    if (self != nil) {
        ruleChanged = NO;
    }
    return self;
}


-(void)awakeFromNib
{
    awaking = YES;
    
    // default: hide values that are already assigned elsewhere
    hideAssignedValues = YES;
    [self setValue:@YES forKey: @"hideAssignedValues"];
    
    caClassification = [[CatAssignClassification alloc] init];
    [predicateEditor addRow:self];
    
    // sort descriptor for transactions view
    NSSortDescriptor	*sd = [[NSSortDescriptor alloc] initWithKey: @"statement.date" ascending: NO];
    NSArray				*sds = @[sd];
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
    statementsListView.autoResetNew = NO;
    [statementsListView setCellSpacing: 0];
    [statementsListView setAllowsEmptySelection: YES];
    [statementsListView setAllowsMultipleSelection: YES];

    predicatesBackground.fillColor = [NSColor colorWithCalibratedWhite: 233 / 255.0 alpha: 1];
    
    awaking = NO;
}

-(void)setManagedObjectContext:(NSManagedObjectContext*)context
{
    [assignPreviewController setManagedObjectContext: context];
    [assignPreviewController prepareContent];
}


- (IBAction)saveRule:(id)sender 
{
    NSError* error;
    
    if (currentCategory == nil) {
        return;
    }
    
    NSPredicate* predicate = [predicateEditor objectValue];
    if(predicate) {
        // check predicate
        NSString *rule = [predicate description ];
        @try {
            [NSPredicate predicateWithFormat:rule ];
        }
        @catch (NSException * e) {
            NSRunAlertPanel(NSLocalizedString(@"AP113", nil),
                            NSLocalizedString(@"AP75", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil,
                            e.reason
                            );
            return;
        }
        
        [currentCategory setValue: rule forKey: @"rule"];
        
        // save updates
        NSManagedObjectContext *context = [[MOAssistant assistant] context];
        if([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return;
        }
        ruleChanged = NO;
    }
}

- (IBAction)deleteRule:(id)sender
{
    NSError* error;
    
    if (currentCategory == nil) {
        return;
    }
    
    int res = NSRunAlertPanel(NSLocalizedString(@"AP307", nil),
                              NSLocalizedString(@"AP308", nil),
                              NSLocalizedString(@"AP3", nil),
                              NSLocalizedString(@"AP4", nil),
                              nil,
                              [currentCategory localName]
                              );
    if (res != NSAlertDefaultReturn) return;
    
    [currentCategory setValue: nil forKey: @"rule"];
    ruleChanged = NO;
    
    // save updates
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    if([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    NSPredicate* pred = [NSCompoundPredicate predicateWithFormat: @"statement.purpose CONTAINS[c] ''"];
    if([pred class] != [NSCompoundPredicate class]) {
        NSCompoundPredicate* comp = [[NSCompoundPredicate alloc] initWithType: NSOrPredicateType subpredicates: @[pred]];
        pred = comp;
    }
    [predicateEditor setObjectValue: pred];
    
    [self calculateCatAssignPredicate];
}

-(void)calculateCatAssignPredicate
{
    NSPredicate* pred = nil;
    NSPredicate* compoundPredicate = nil;
    
    // first add selected category
    if (currentCategory == nil) {
        return;
    }
    
    NSMutableArray *orPreds = [NSMutableArray arrayWithCapacity: 5];
    
    if ([currentCategory valueForKey: @"parent"] != nil) {
        pred = [NSPredicate predicateWithFormat: @"(category = %@)", currentCategory];
        [orPreds addObject: pred];
    }
    NSPredicate* predicate = [predicateEditor objectValue];
    
    // Not assigned statements
    pred = [NSPredicate predicateWithFormat: @"(category = %@)", [Category nassRoot]];
    if (predicate != nil) {
        pred = [NSCompoundPredicate andPredicateWithSubpredicates: @[pred, predicate]];
    }
    [orPreds addObject: pred];
    
    // already assigned statements 
    if(!hideAssignedValues) {
        pred = [NSPredicate predicateWithFormat: @"(category.isBankAccount = 0)"];
        if (predicate != nil) {
            pred = [NSCompoundPredicate andPredicateWithSubpredicates: @[pred, predicate]];
        }
        [orPreds addObject: pred];
    }
    
    compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates: orPreds];
    pred = [timeSliceManager predicateForField: @"date"];
    compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[compoundPredicate, pred]];
    
    
    // update classification Context
    if (currentCategory == [Category nassRoot]) {
        [caClassification setCategory: nil];
    } else {
        [caClassification setCategory: currentCategory];
    }
    
    // set new fetch predicate
    if (compoundPredicate) {
        [assignPreviewController setFilterPredicate: compoundPredicate];
    }
}

- (BOOL)categoryShouldChange
{
    if (currentCategory == nil) {
        return YES;
    }
    
    if (ruleChanged) {
        int res = NSRunAlertPanel(NSLocalizedString(@"AP305", nil),
                                  NSLocalizedString(@"AP306", nil),
                                  NSLocalizedString(@"AP3", nil),
                                  NSLocalizedString(@"AP4", nil),
                                  nil,
                                  [currentCategory localName]
                                  );
        if (res == NSAlertDefaultReturn) {
            [self saveRule: self];
        }
        ruleChanged = NO;
    }
    return YES;
}


- (IBAction)predicateEditorChanged:(id)sender
{	
    if (awaking) {
        return;
    }
    
    // check NSApp currentEvent for the return key
    NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSKeyDown)
    {
        NSString* characters = [event characters];
        if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D)
        {
            [self calculateCatAssignPredicate];
            ruleChanged = YES;
        }
    }
    
}

- (void)ruleEditorRowsDidChange:(NSNotification *)notification
{
    [self calculateCatAssignPredicate];
}

- (IBAction)hideAssignedChanged:(id)sender
{
    [self calculateCatAssignPredicate];
}

- (IBAction)assignEntries:(id)sender {
    NSArray *entries = assignPreviewController.selectedObjects;
    if (entries.count == 0) {
        entries = assignPreviewController.arrangedObjects;
    }
    for (StatCatAssignment *entry in entries) {
        [entry.statement assignAmount: [entry value] toCategory: currentCategory];
    }

    [currentCategory invalidateBalance];
    [Category updateCatValues];

    // Explicitly reload the listview. When removing from a category it happens automatically.
    // Not so when adding, though.
    [statementsListView reloadData];

    NSError* error;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (void)assignToCategory: (StatCatAssignment*)assignment
{
    if (currentCategory == nil) {
        return;
    }

    [assignment.statement assignAmount: [assignment value] toCategory: currentCategory];
    
    [currentCategory invalidateBalance];
    [Category updateCatValues];
    
    [statementsListView reloadData];
    
    NSError* error;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (void)unassignFromCategory: (StatCatAssignment*)assignment 
{
    NSError* error;
    if (currentCategory == nil) {
        return;
    }
    
    [assignment remove];
    [assignPreviewController rearrangeObjects];
    
    [currentCategory invalidateBalance];
    [Category updateCatValues];
    
    // save updates
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    if([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    
}

- (void)activationChanged: (BOOL)active forIndex: (NSUInteger)index
{
    StatCatAssignment* assignment = [assignPreviewController arrangedObjects][index];
    if (assignment != nil) {
        if (active) {
            [self assignToCategory: assignment];
        } else {
            [self unassignFromCategory: assignment];
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
        } else {
            assignEntriesButton.title = NSLocalizedString(@"AP551", nil);
        }
        [assignEntriesButton setEnabled: [assignPreviewController.arrangedObjects count] > 0];
    }
}

#pragma mark -
#pragma mark PecuniaSectionItem protocol

- (void)print
{
    NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSFitPagination];
    NSPrintOperation *printOp;

    printOp = [NSPrintOperation printOperationWithView: topView printInfo: printInfo];

    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

-(NSView*)mainView
{
    return topView;
}

-(void)prepare
{
    [BankStatement setClassificationContext: caClassification];
    [self calculateCatAssignPredicate];
}

- (void)activate;
{
}

- (void)deactivate
{
}

- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to
{
    [self calculateCatAssignPredicate];
}

- (void)setCategory:(Category *)newCategory
{
    if (currentCategory != newCategory) {
        currentCategory = newCategory;

        if (currentCategory == [Category nassRoot] || currentCategory == [Category catRoot]) {
            [[[[predicateEditor superview] superview] animator] setHidden: YES];
            [[saveButton animator] setHidden: YES];
            [[discardButton animator] setHidden: YES];
        } else {
            [[[[predicateEditor superview] superview] animator] setHidden: NO];
            [[saveButton animator] setHidden: NO];
            [[discardButton animator] setHidden: NO];
        }
        
        NSString* s = [currentCategory valueForKey: @"rule"];
        if(s == nil) s = @"statement.purpose CONTAINS[c] ''";
        NSPredicate* pred = [NSCompoundPredicate predicateWithFormat: s];
        if([pred class] != [NSCompoundPredicate class]) {
            NSCompoundPredicate* comp = [[NSCompoundPredicate alloc] initWithType: NSOrPredicateType subpredicates: @[pred]];
            pred = comp;
        }
        [predicateEditor setObjectValue: pred];
        [self calculateCatAssignPredicate];
    }
}

@end
