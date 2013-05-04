//
//  StatSplitController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 21.02.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "StatSplitController.h"
#import "MOAssistant.h"
#import "BankStatement.h"
#import "StatCatAssignment.h"
#import "Category.h"


@implementation StatSplitController

- (id)initWithStatement: (BankStatement *)stat view: (NSView *)view;
{
    self = [super initWithWindowNibName: @"StatSplitController"];
    managedObjectContext = [[MOAssistant assistant] context];
    statement = stat;
    catView = view;
    return self;
}

- (void)awakeFromNib
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"category == nil OR (category.isBankAcc == 0 AND category.name != \"++nassroot\")"];
    [splitStatController setFilterPredicate: predicate];
    [currentStat setContent: statement];
    [self setValue: statement.nassValue forKey: @"residualAmount"];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"localName" ascending: YES];
    NSArray          *sds = @[sd];
    [catController setSortDescriptors: sds];

}

- (void)windowDidLoad
{
    [[self window] center];
}

- (void)windowWillClose: (NSNotification *)notification
{
    [NSApp stopModal];
}

- (void)addAssignment: (id)sender
{
    [statement assignAmount: statement.nassValue toCategory: nil];
    [self setValue: [NSDecimalNumber zero] forKey: @"residualAmount"];
}

- (void)removeAssignment: (id)sender
{
    NSArray *sel = [splitStatController selectedObjects];
    if (sel && [sel count] == 1) {
        StatCatAssignment *stat = sel[0];
        [stat remove];
        [self setValue: statement.nassValue forKey: @"residualAmount"];
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    // Value field changed (todo: replace by key value observation)
    if ([aNotification object] == splitView) {
        int idx = [splitView editedColumn];
        if (idx < 0) {
            return;
        }
        NSTableColumn *col = [splitView tableColumns][idx];
        if (![[col identifier] isEqualToString: @"value"]) {
            return;
        }

        NSArray *sel = [splitStatController selectedObjects];
        if (sel && [sel count] == 1) {
            StatCatAssignment *stat = sel[0];
            // ensure statement.value and stat.value have the same sign
            if ([statement.value compare: [NSDecimalNumber zero]] != [stat.value compare: [NSDecimalNumber zero]]) {
                stat.value = [stat.value decimalNumberByMultiplyingBy: [NSDecimalNumber decimalNumberWithString: @"-1"]];
            }

            [statement updateAssigned];
            [self setValue: statement.nassValue forKey: @"residualAmount"];
            Category *cat = stat.category;
            if (cat !=  nil) {
                [cat invalidateBalance];
                [Category updateCatValues];
                //				[catView setNeedsDisplay: YES ];
            }
        }
    }
}

- (IBAction)manageAssignments: (id)sender
{
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment: clickedSegment];
    switch (clickedSegmentTag) {
        case 0:[self addAssignment: sender]; break;

        case 1:[self removeAssignment: sender]; break;

        default: return;
    }

}

@end
