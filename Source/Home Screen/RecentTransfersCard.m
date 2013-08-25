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

#import <CorePlot/CorePlot.h>

#import "RecentTransfersCard.h"
#import "ShortDate.h"
#import "Category.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"
#import "MessageLog.h"
#import "TransfersCellView.h"
#import "TransfersHeaderView.h"
#import "ColorPopup.h"

#import "MOAssistant.h"
#import "BankingController.h"

@interface StatementsHeader : NSObject

@property (nonatomic, retain) ShortDate *date;
@end

@implementation StatementsHeader

@end

@interface ListColorWell : NSColorWell

@end

@implementation ListColorWell

- (void)mouseDown: (NSEvent *)theEvent
{
    // Switch off the dragging feature of NSColorWell.
}

- (void)mouseUp: (NSEvent *)theEvent
{
    // Show the color picker even though we have no border.
    NSPoint point = [self convertPoint: theEvent.locationInWindow fromView: nil];
    if (NSPointInRect(point, self.bounds)) {
        ColorPopup.sharedColorPopup.color = self.color;
        ColorPopup.sharedColorPopup.target = self;
        ColorPopup.sharedColorPopup.action = @selector(colorChanged:);
        [ColorPopup.sharedColorPopup popupRelativeToRect: self.bounds ofView: self];
    }
}

- (void)colorChanged: (id)sender
{
    self.color = ColorPopup.sharedColorPopup.color;

    // Manually write the changed color to the bound property. Just setting color doesn't do it.
    NSDictionary *bindingInfo = [self infoForBinding: NSValueBinding];
    [[bindingInfo valueForKey: NSObservedObjectKey] setValue: self.color
                                                  forKeyPath: [bindingInfo valueForKey: NSObservedKeyPathKey]];
}

@end

@interface RecentTransfersCard ()
{
    NSMutableArray *entries;
}

@end

@implementation RecentTransfersCard

@synthesize transfersView;
@synthesize transfersViewContainer;

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        NSNib *nib = [[NSNib alloc] initWithNibNamed: @"HomeScreenTransfersView" bundle: nil];
        NSArray *topLevelObjects;
        if (![nib instantiateWithOwner: self topLevelObjects: &topLevelObjects]) {
            // Can this ever fail?
            [[MessageLog log] addMessage: @"Internal error: home screen transfer view loading failed" withLevel: LogLevel_Error];
        }

        transfersView.delegate = self;
        transfersView.dataSource = self;
        [self addSubview: transfersViewContainer];

        [self loadData];
        [NSNotificationCenter.defaultCenter addObserver: self
                                               selector: @selector(handleDataModelChange:)
                                                   name: NSManagedObjectContextDidSaveNotification
                                                 object: MOAssistant.assistant.context];
    }

    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver: self];
}

- (void)handleDataModelChange: (NSNotification *)notification
{
    if (BankingController.controller.shuttingDown) {
        return;
    }

    NSSet *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    NSSet *insertedObjects = notification.userInfo[NSInsertedObjectsKey];

    // Check inserted and deleted objects.
    // Note: this doesn't work with MOAssistant.clearAllData because we simply remove the underlying file.
    //       But that's a dev feature anyway.
    if (insertedObjects.count > 0 || deletedObjects.count > 0) {
        [transfersView beginUpdates];

        // Get a new copy of the set of assignments we have now.
        NSMutableArray *newEntries = [[Category.bankRoot allAssignmentsOrderedBy: DateOrderDate
                                                                           limit: 50
                                                                       recursive: YES
                                                                       ascending: NO] mutableCopy];
        [newEntries sortUsingSelector: @selector(compareDateReverse:)];

        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        if (deletedObjects.count > 0) {
            for (id object in deletedObjects) {
                if ([object isKindOfClass: StatCatAssignment.class]) {
                    NSUInteger index = [entries indexOfObject: object];
                    if (index != NSNotFound) {
                        [indexes addIndex: index];
                    }
                }
            }
            [transfersView removeRowsAtIndexes: indexes withAnimation: NSTableViewAnimationSlideRight];
        }

        if (insertedObjects.count > 0) {
            NSIndexSet *newIndexes = [newEntries indexesOfObjectsPassingTest: ^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return ![entries containsObject: obj];
            }];

            if (newIndexes.count > 0) {
                [transfersView insertRowsAtIndexes: newIndexes withAnimation: NSTableViewAnimationSlideDown];
            }
        }

        entries = newEntries;
        [transfersView endUpdates];
    }
}

- (void)loadData
{
    // Retrieve assignments from the past two weeks.
    entries = [[Category.bankRoot allAssignmentsOrderedBy: DateOrderDate
                                                    limit: 50
                                                recursive: YES
                                                ascending: NO] mutableCopy];

    if (entries.count > 0) {
        // Insert grouping entries between entries of different dates.
        ShortDate *lastDate = [ShortDate dateWithDate: [entries[0] statement].date];
        StatementsHeader *header = [[StatementsHeader alloc] init];
        header.date = lastDate;
        [entries insertObject: header atIndex: 0];

        for (NSUInteger index = 1; index < entries.count; ++index) {
            if ([entries[index] isKindOfClass: StatementsHeader.class]) {
                continue;
            }
            StatCatAssignment *assignment = entries[index];
            ShortDate *date = [ShortDate dateWithDate: assignment.statement.date];
            if ([date compare: lastDate] != NSOrderedSame) {
                // New day. Insert a header row.
                StatementsHeader *header = [[StatementsHeader alloc] init];
                header.date = date;
                [entries insertObject: header atIndex: index++];
                lastDate = date;
            }
        }
    }

    [transfersView reloadData];
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    NSRect frame = NSInsetRect(self.bounds, 20, 30);
    frame.origin.y += 10;

    // We actually have only one child view.
    for (NSView *child in self.subviews) {
        child.frame = frame;
        frame.origin.y += frame.size.height;
    }
}

#pragma mark - NSTableViewDataSource protocol

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return entries.count;
}

- (NSView *)tableView: (NSTableView *)tableView
   viewForTableColumn: (NSTableColumn *)tableColumn
                  row: (NSInteger)row
{
    if ([entries[row] isKindOfClass: StatementsHeader.class]) {
        StatementsHeader *header = entries[row];
        TransfersHeaderView *cell = [tableView makeViewWithIdentifier: @"HeaderCell" owner: self];
        cell.textField.stringValue = [header.date description];
        return cell;
    } else {
        TransfersCellView *cell = [tableView makeViewWithIdentifier: @"MainCell" owner: self];
        cell.statement = [entries[row] statement];
        cell.category = [entries[row] category];
        return cell;
    }
}

- (NSTableRowView *)tableView: (NSTableView *)tableView rowViewForRow: (NSInteger)row
{
    TransfersRowView *view = [[TransfersRowView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    return view;
}

- (CGFloat)tableView: (NSTableView *)tableView heightOfRow: (NSInteger)row
{
    if ([entries[row] isKindOfClass: StatementsHeader.class]) {
        return 20;
    } else {
        return 40;
    }
}

- (BOOL)tableView: (NSTableView *)tableView isGroupRow:( NSInteger)row
{
    return [entries[row] isKindOfClass: StatementsHeader.class];
}

@end
