/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

#import "NSView+PecuniaAdditions.h"

/**
 * Animated splitter move. Works best if only two subviews exist. Works both horizontally and vertically.
 */
@implementation NSSplitView (PecuniaAdditions)

- (void)animateDividerToPosition: (CGFloat)dividerPosition
{
    NSView *view0 = [[self subviews] objectAtIndex: 0];
    NSView *view1 = [[self subviews] objectAtIndex: 1];
    NSRect view0Rect = [view0 frame];
    NSRect view1Rect = [view1 frame];
    NSRect overalRect = [self frame];
    CGFloat dividerSize = [self dividerThickness];

    BOOL view0AutoResizes = [view0 autoresizesSubviews];
    BOOL view1AutoResizes = [view1 autoresizesSubviews];

    if ([self isVertical]) {
        // Disable autoresizing if *current* view size <= zero.
        [view0 setAutoresizesSubviews:view0AutoResizes && view0Rect.size.width > 0];
        [view1 setAutoresizesSubviews:view1AutoResizes && view1Rect.size.width > 0];

        // Set subviews target size.
        view0Rect.origin.x = MIN(0, dividerPosition);
        view0Rect.size.width = MAX(0, dividerPosition);
        view1Rect.origin.x = MAX(0, dividerPosition + dividerSize);
        view1Rect.size.width = MAX(0, overalRect.size.width - view0Rect.size.width - dividerSize);

        // Disable autoresizing if *target* view size <= zero.
        if (view0Rect.size.width <= 0) {
            [view0 setAutoresizesSubviews: NO];
        }
        if (view1Rect.size.width <= 0) {
            [view1 setAutoresizesSubviews: NO];
        }
    } else {
        // Disable autoresizing if *current* view size <= zero.
        [view0 setAutoresizesSubviews: view0AutoResizes && view0Rect.size.height > 0];
        [view1 setAutoresizesSubviews: view1AutoResizes && view1Rect.size.height > 0];

        // Set subviews target size.
        view0Rect.origin.y = MIN(0, dividerPosition);
        view0Rect.size.height = MAX(0, dividerPosition);
        view1Rect.origin.y = MAX(0, dividerPosition + dividerSize);
        view1Rect.size.height = MAX(0, overalRect.size.height - view0Rect.size.height - dividerSize);

        // Disable autoresizing if *target* view size <= zero.
        if (view0Rect.size.height <= 0) {
            [view0 setAutoresizesSubviews: NO];
        }
        if (view1Rect.size.height <= 0) {
            [view1 setAutoresizesSubviews: NO];
        }
    }

    // Make sure views are visible after previous collapse.
    //[view0 setHidden: NO];
    //[view1 setHidden: NO];

    // Disable delegate interference.
    id delegate = [self delegate];
    [self setDelegate: nil];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration: 0.25f];
    [[NSAnimationContext currentContext] setCompletionHandler: ^(void) {
        [view0 setAutoresizesSubviews: view0AutoResizes];
        [view1 setAutoresizesSubviews: view1AutoResizes];
        [self setDelegate: delegate];
        //[self setAnimating: NO];
    }];
    [[view0 animator] setFrame: view0Rect];
    [[view1 animator] setFrame: view1Rect];
    [NSAnimationContext endGrouping];
}

@end