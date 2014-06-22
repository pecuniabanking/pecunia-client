/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "PecuniaListView.h"
#import "PXListView+UserInteraction.h"

extern NSString *PecuniaWordsLoadedNotification;

@implementation DetailsView

@synthesize representedObject;

- (void)moveUp:(id)sender {
    [self.owner moveUp: sender];
}

- (void)moveDown:(id)sender {
    [self.owner moveDown: sender];
}

- (void)keyDown: (NSEvent *)theEvent {
    [self.owner keyDown: theEvent];
}

- (BOOL)suppressFirstResponderWhenPopoverShows {
    return YES;
}

@end

@interface PecuniaListView () {

    NSPopover        *detailsPopover;
    NSViewController *detailsPopoverController;

    DetailsView *detailsView;
}

@end

@implementation PecuniaListView

- (void)initDetailsWithNibName: (NSString *)nibName {
    [NSNotificationCenter.defaultCenter addObserver: self
                                           selector: @selector(updateVisibleCells)
                                               name: PecuniaWordsLoadedNotification
                                             object: nil];

    detailsPopoverController = [[NSViewController alloc] initWithNibName: nibName bundle: nil];
    detailsView = (id)detailsPopoverController.view;
    detailsView.owner = self;

    detailsPopover = [NSPopover new];
    detailsPopover.contentViewController = detailsPopoverController;
    detailsPopover.behavior = NSPopoverBehaviorSemitransient;
}

- (void)updateVisibleCells {
    // Implemented by descendants.
}

- (void)updateCells {
    // Called when the content view is scrolled.
    [super updateCells];
    [self updatePopoverPosition];
}

- (void)moveUp: (id)sender {
    [super moveUp: sender];

    if (detailsPopover.shown) {
        [self updateDetails];
        [self updatePopoverPosition];
    }
}

- (void)moveDown: (id)sender {
    [super moveDown: sender];

    if (detailsPopover.shown) {
        [self updateDetails];
        [self updatePopoverPosition];
    }
}

- (void)scrollToBeginningOfDocument: (id)sender {
    [self scrollRowToVisible: 0];
    [self updatePopoverPosition];
}

- (void)scrollToEndOfDocument: (id)sender {
    [self scrollRowToVisible: self.numberOfRows - 1];
    [self updatePopoverPosition];
}

- (void)insertNewline: (id)sender {
    [self toggleStatementDetails];
}

- (void)insertText: (id)insertString {
    if ([insertString isEqualToString: @" "]) { // Acting like quick view
        [self toggleStatementDetails];
    }
}

- (void)handleMouseDown: (NSEvent*)theEvent inCell: (PXListViewCell*)theCell {
    // A mouse down will implicitly hide the popover in semi-transient mode, so temporarily
    // take over full control of the visibility.
    if (detailsPopover.shown) {
        detailsPopover.behavior = NSPopoverBehaviorApplicationDefined;
    } else {
        if (theEvent.clickCount > 1 && !detailsPopover.shown) {
            [self toggleStatementDetails];
        }
    }
    [super handleMouseDown: theEvent inCell: theCell];

    if (detailsPopover.shown) {
        detailsPopover.behavior = NSPopoverBehaviorSemitransient;

        [self updateDetails];
        [self updatePopoverPosition];
    }
}

- (NSRect)popoverRect {
    NSRect rect = [self rectOfRow: self.selectedRow];
    NSRect frame = [self.contentView documentVisibleRect];
    rect.origin.y -= frame.origin.y;

    // Center over the row.
    CGFloat midX = NSMidX(rect);
    CGFloat midY = NSMidY(rect);
    rect.origin.x = midX - 5;
    rect.origin.y = midY - 5;
    rect.size = NSMakeSize(10, 10);

    return rect;
}

- (void)toggleStatementDetails {
    if (detailsPopover.shown) {
        [detailsPopover performClose: nil];
        return;
    }

    self.selectedRow = self.selectedRows.firstIndex; // Make it a single selection.
    [self updateDetails];

    // Will not show the popover if the computed rect is outside the current view.
    [detailsPopover showRelativeToRect: self.popoverRect ofView: self preferredEdge: NSMaxXEdge];
}

- (void)updateDetails {
    detailsView.representedObject = self.dataSource[self.selectedRow];
}

/**
 * Similar to NSTableView positions the details popover to the currently selected row (while scrolling).
 * The popover is hidden when the selected row moves out of the visible area.
 */
- (void)updatePopoverPosition {
    if (detailsPopover.shown) {
        NSRect rect = self.popoverRect;
        if (NSContainsRect(self.bounds, rect)) {
            detailsPopover.positioningRect = rect;
        } else {
            [detailsPopover close];
        }
    }
}

- (void)cancelOperation: (id)sender {
    [detailsPopover performClose: self];
}

@end
