/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import "MessageLog.h"

#import "RecentTransfersCard.h"
#import "ShortDate.h"
#import "Category.h"
#import "StatCatAssignment.h"
#import "BankStatement.h"
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
    LogEnter;

    self = [super initWithFrame: frame];
    if (self != nil) {
        if (![NSBundle loadNibNamed: @"HomeScreenTransfersView" owner: self]) {
            LogError(@"Internal error: home screen recent transfers view loading failed.");
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

    LogLeave;

    return self;
}

- (void)dealloc
{
    LogEnter;

    [NSNotificationCenter.defaultCenter removeObserver: self];

    LogLeave;
}

- (void)handleDataModelChange: (NSNotification *)notification
{
    LogEnter;

    @try {
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

            // First remove all headers, so that new and old entries are comparable.
            NSIndexSet *headerIndexes = [entries indexesOfObjectsPassingTest: ^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [obj isKindOfClass: StatementsHeader.class];
            }];
            [entries removeObjectsAtIndexes: headerIndexes];
            [transfersView removeRowsAtIndexes: headerIndexes withAnimation: NSTableViewAnimationSlideUp];

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
            [self updateHeadersWithAnimation: YES];
            [transfersView endUpdates];

            [transfersView reloadData];
        }
        
    }
    @catch (NSException *error) {
        LogError(@"%@", error.debugDescription);
    }
    
    LogLeave;
}

- (void)loadData
{
    LogEnter;

    // Retrieve assignments from the past two weeks.
    entries = [[Category.bankRoot allAssignmentsOrderedBy: DateOrderDate
                                                    limit: 50
                                                recursive: YES
                                                ascending: NO] mutableCopy];

    [self updateHeadersWithAnimation: NO];
    [transfersView reloadData];

    LogLeave;
}

/**
 * Inserts grouping entries between entries of different dates.
 */
- (void)updateHeadersWithAnimation: (BOOL)animate
{
    LogEnter;

    if (entries.count > 0) {
        ShortDate *lastDate = [ShortDate dateWithDate: [entries[0] statement].date];
        StatementsHeader *header = [[StatementsHeader alloc] init];
        header.date = lastDate;
        [entries insertObject: header atIndex: 0];
        if (animate) {
            [transfersView insertRowsAtIndexes: [NSIndexSet indexSetWithIndex: 0]
                                 withAnimation: NSTableViewAnimationSlideDown];
        }

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
                [entries insertObject: header atIndex: index];
                if (animate) {
                    [transfersView insertRowsAtIndexes: [NSIndexSet indexSetWithIndex: index++]
                                         withAnimation: NSTableViewAnimationSlideDown];
                }
                lastDate = date;
            }
        }
    }

    LogLeave;
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    LogEnter;

    NSRect frame = NSInsetRect(self.bounds, 30, 45);
    frame.origin.y += 10;

    // We actually have only one child view.
    for (NSView *child in self.subviews) {
        child.frame = frame;
        frame.origin.y += frame.size.height;
    }

    LogLeave;
}

#pragma mark - NSTableViewDataSource protocol

- (NSInteger)numberOfRowsInTableView: (NSTableView *)tableView
{
    return entries.count;
}

- (NSView *)tableView: (NSTableView *)tableView
   viewForTableColumn: (NSTableColumn *)tableColumn
                  row: (NSInteger)row
{
    if (row >= (NSInteger)entries.count) {
        return nil;
    }
    
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
    if (row < (NSInteger)entries.count && [entries[row] isKindOfClass: StatementsHeader.class]) {
        return 20;
    } else {
        return 40;
    }
}

- (BOOL)tableView: (NSTableView *)tableView isGroupRow:( NSInteger)row
{
    if (row < (NSInteger)entries.count) {
        return [entries[row] isKindOfClass: StatementsHeader.class];
    }
    return NO;
}

@end
