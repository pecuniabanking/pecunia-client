/**
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "SynchronousScrollView.h"

/**
 * Implementation of a scrollview which can scroll synchronously with another scrollview.
 * Code mostly from a Mac OS X dev library example.
 */
@implementation SynchronousScrollView

- (void)setSynchronizedScrollView: (NSScrollView*)scrollview
{
    [self.contentView setCopiesOnScroll: YES];
    
    NSView *synchronizedContentView;

    [self stopSynchronizing];
    synchronizedScrollView = scrollview;
    synchronizedContentView = [synchronizedScrollView contentView];
    [synchronizedContentView setPostsBoundsChangedNotifications:YES];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(synchronizedViewContentBoundsDidChange:)
                                                 name: NSViewBoundsDidChangeNotification
                                               object: synchronizedContentView];
}

- (void)synchronizedViewContentBoundsDidChange: (NSNotification *)notification
{
    NSClipView *changedContentView  =[notification object];
    NSPoint changedBoundsOrigin = [changedContentView documentVisibleRect].origin;
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;

    // We only sync vertically.
    if (newOffset.y != changedBoundsOrigin.y) {
        newOffset.y = changedBoundsOrigin.y;
        if (!NSEqualPoints(curOffset, changedBoundsOrigin)) {
            [[self contentView] scrollToPoint: newOffset];
            [self reflectScrolledClipView: [self contentView]];
        }
    }
}

- (void)stopSynchronizing
{
    if (synchronizedScrollView != nil) {
        NSView* synchronizedContentView = [synchronizedScrollView contentView];

        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: NSViewBoundsDidChangeNotification
                                                      object: synchronizedContentView];
        synchronizedScrollView = nil;
    }
}

@end
