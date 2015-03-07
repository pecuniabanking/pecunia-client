/**
 * Copyright (c) 2014, 2015, Pecunia Project. All rights reserved.
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

@interface PopoverAnimation : NSAnimation {
    @private
    NSRect    startRect;
    NSRect    endRect;
    NSPopover *target;
}
@end

@implementation PopoverAnimation

- (id)initWithPopover: (NSPopover *)popover startRect: (NSRect)start endRect: (NSRect)end {
    self = [super initWithDuration: 0.125 animationCurve: NSAnimationEaseInOut];
    if (self != nil) {
        target = popover;
        startRect = start;
        endRect = end;
    }
    return self;
}

- (void)setCurrentProgress: (NSAnimationProgress)progress {
    [super setCurrentProgress: progress];

    NSRect newRect = startRect;
    newRect.origin.x += progress * (NSMinX(endRect) - NSMinX(startRect));
    newRect.origin.y += progress * (NSMinY(endRect) - NSMinY(startRect));
    target.positioningRect = newRect;
}

@end

@implementation DetailsView

@synthesize representedObject;

- (void)moveUp: (id)sender {
    [self.owner moveUp: sender];
}

- (void)moveDown: (id)sender {
    [self.owner moveDown: sender];
}

- (void)keyDown: (NSEvent *)theEvent {
    [self.owner keyDown: theEvent];
}

- (BOOL)suppressFirstResponderWhenPopoverShows {
    return YES;
}

@end

@interface PecuniaPopover : NSPopover {
    @public BOOL wantClose;
}
@end

@implementation PecuniaPopover

- (IBAction)performClose: (id)sender {
    wantClose = YES;
    [super performClose: sender];
}

@end

@interface PecuniaListView () <NSPopoverDelegate> {
    PecuniaPopover   *detailsPopover;
    NSViewController *detailsPopoverController;
    DetailsView      *detailsView;
    PopoverAnimation *positionAnimation;

    BOOL popoverWillOpen;
}

@end

@implementation PecuniaListView

- (void)initDetailsWithNibName: (NSString *)nibName {
    [NSNotificationCenter.defaultCenter addObserver: self
                                           selector: @selector(updateVisibleCells)
                                               name: WordMapping.pecuniaWordsLoadedNotification
                                             object: nil];

    detailsPopoverController = [[NSViewController alloc] initWithNibName: nibName bundle: nil];
    detailsView = (id)detailsPopoverController.view;
    detailsView.owner = self;

    detailsPopover = [PecuniaPopover new];
    detailsPopover.contentViewController = detailsPopoverController;
    detailsPopover.behavior = NSPopoverBehaviorSemitransient;
    detailsPopover.animates = YES;
    detailsPopover.delegate = self;
}

- (void)popoverWillShow: (NSNotification *)notification {
    popoverWillOpen = YES;
}

- (void)popoverDidShow: (NSNotification *)notification {
    detailsPopover->wantClose  = NO;
    popoverWillOpen            = NO;
}

- (BOOL)popoverShouldClose: (NSPopover *)popover {
    BOOL allowClose = YES;

    if (!detailsPopover->wantClose) {
        // Lets see if the mouse is over the popover ...
        NSRect globalLocation = NSMakeRect(NSEvent.mouseLocation.x, NSEvent.mouseLocation.y, 0, 0);
        NSRect windowLocation = [popover.contentViewController.view.window convertRectFromScreen: globalLocation];
        NSPoint viewLocation = [popover.contentViewController.view convertPoint: windowLocation.origin fromView: nil];
        if (NSPointInRect(viewLocation, [popover.contentViewController.view bounds]) ) {
            allowClose = NO;
        }
    }
    return allowClose;
}

- (BOOL)resignFirstResponder {
    if (popoverWillOpen) {
        return NO;
    }
    return YES;
}

- (void)updateVisibleCells {
    // Implemented by descendants.
}

- (void)updateCells {
    // Called when the content view is scrolled.
    [super updateCells];
    [self updatePopoverPositionWithAnimation: NO];
}

- (void)moveUp: (id)sender {
    [super moveUp: sender];

    if (detailsPopover.shown) {
        [self updateDetails];
        [self updatePopoverPositionWithAnimation: YES];
    }
}

- (void)moveDown: (id)sender {
    [super moveDown: sender];

    if (detailsPopover.shown) {
        [self updateDetails];
        [self updatePopoverPositionWithAnimation: YES];
    }
}

- (void)scrollToBeginningOfDocument: (id)sender {
    [self scrollRowToVisible: 0];
}

- (void)scrollToEndOfDocument: (id)sender {
    [self scrollRowToVisible: self.numberOfRows - 1];
}

- (void)insertNewline: (id)sender {
    [self toggleStatementDetails];
}

- (void)insertText: (id)insertString {
    if ([insertString isEqualToString: @" "]) { // Acting like quick view
        [self toggleStatementDetails];
    }
}

- (void)handleMouseDown: (NSEvent *)theEvent inCell: (PXListViewCell *)theCell {
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
        [self updatePopoverPositionWithAnimation: YES];
    }
}

- (NSRect)popoverRect {
    // We use forDragging: YES here to exclude the header, if there's any.
    NSRect rect = [self rectOfRow: self.selectedRow forDragging: YES];
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

    self.selectedRow = self.selectedRows.lastIndex; // Make it a single selection.
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
- (void)updatePopoverPositionWithAnimation: (BOOL)animate {
    if (detailsPopover.shown) {
        NSRect rect = self.popoverRect;
        if (NSIntersectsRect(self.bounds, rect)) {
            if (positionAnimation != nil) {
                [positionAnimation stopAnimation];
            }
            if (fabs(NSMinY(detailsPopover.positioningRect) - NSMinY(rect)) < NSHeight([self rectOfRow: self.selectedRow forDragging: YES])) {
                animate = NO;
            }
            if (animate) {
                positionAnimation = [[PopoverAnimation alloc] initWithPopover: detailsPopover
                                                                    startRect: detailsPopover.positioningRect
                                                                      endRect: rect];
                positionAnimation.animationBlockingMode = NSAnimationNonblockingThreaded;
                positionAnimation.delegate = self;
                [positionAnimation startAnimation];
            } else {
                detailsPopover.positioningRect = rect;
            }
        } else {
            [detailsPopover close];
        }
    }
}

- (void)cancelOperation: (id)sender {
    [positionAnimation stopAnimation];
    [detailsPopover performClose: self];
}

- (void)animationDidStop: (NSAnimation *)animation {
    positionAnimation = nil;
}

- (void)animationDidEnd: (NSAnimation *)animation {
    positionAnimation = nil;
}

@end
