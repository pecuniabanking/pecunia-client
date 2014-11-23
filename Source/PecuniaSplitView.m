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

#import "PecuniaSplitView.h"

@interface PecuniaSplitView ()
{
    NSInteger pendingPosition; // > 0 if we need to apply an initial position in the next resize event.
}
@end

@implementation PecuniaSplitView

@synthesize fixedIndex;

- (id)initWithCoder: (NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self != nil) {
        fixedIndex = NSNotFound;
    }
    return self;
}

- (NSColor *)dividerColor
{
    return [NSColor clearColor];
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    if (fixedIndex == NSNotFound || fixedIndex >= self.subviews.count || self.subviews.count != 2) {
        [super resizeSubviewsWithOldSize: oldSize];
    } else {
        // Fixed size support currently only for 2 subviews.
        NSSize totalSize = self.bounds.size;

        // If there's a pending position (from a restore) then it takes precedence over our normal processing.
        if (pendingPosition > 0) {
            if (self.isVertical) {
                NSRect frame = [self.subviews[0] frame];
                if (![(NSView *)self.subviews[1] isHidden]) {
                    frame.size.width = pendingPosition;
                }
                [self.subviews[0] setFrame: frame];

                frame = [self.subviews[1] frame];
                if ([(NSView *)self.subviews[0] isHidden]) {
                    frame.size.width = totalSize.width;
                    frame.origin.x = 0;
                } else {
                    frame.size.width = totalSize.width - self.dividerThickness - pendingPosition;
                    frame.origin.x = self.dividerThickness + pendingPosition;
                }
                [self.subviews[1] setFrame: frame];
            } else {
                NSRect frame = [self.subviews[0] frame];
                if (![(NSView *)self.subviews[1] isHidden]) {
                    frame.size.height = pendingPosition;
                }
                [self.subviews[0] setFrame: frame];

                frame = [self.subviews[1] frame];
                if ([(NSView *)self.subviews[0] isHidden]) {
                    frame.size.height = totalSize.height;
                    frame.origin.y = 0;
                } else {
                    frame.size.height = totalSize.height - self.dividerThickness - pendingPosition;
                    frame.origin.y = self.dividerThickness + pendingPosition;
                }
                [self.subviews[1] setFrame: frame];
            }

            pendingPosition = 0;
        } else {
            NSUInteger variableIndex = fixedIndex == 0 ? 1 : 0;
            NSSize     fixedSize = [self.subviews[fixedIndex] frame].size;

            if ([(NSView *)self.subviews[fixedIndex] isHidden]) {
                fixedSize = NSZeroSize;
            }

            if (self.isVertical) {
                NSSize size;
                size.height = totalSize.height;
                size.width = totalSize.width - self.dividerThickness - fixedSize.width;
                [self.subviews[variableIndex] setFrameSize: size];
                size.width = [self.subviews[fixedIndex] frame].size.width;
                [self.subviews[fixedIndex] setFrameSize: size];
                if (fixedIndex == 1) {
                    NSPoint origin = NSMakePoint(totalSize.width - fixedSize.width, 0);
                    [self.subviews[fixedIndex] setFrameOrigin: origin];
                }
            } else {
                NSSize size;
                size.width = totalSize.width;
                size.height = totalSize.height - self.dividerThickness - fixedSize.height;
                [self.subviews[variableIndex] setFrameSize: size];
                size.height = [self.subviews[fixedIndex] frame].size.height;
                [self.subviews[fixedIndex] setFrameSize: size];
                if (fixedIndex == 1) {
                    NSPoint origin = NSMakePoint(0, totalSize.height - fixedSize.height);
                    [self.subviews[fixedIndex] setFrameOrigin: origin];
                }
            }
        }
    }
}

// Position of the splitter either from left (for a vertical splitter) or from top.
- (void)savePosition
{
    if (self.identifier == nil || self.subviews.count == 0) {
        return;
    }

    NSString *key = [NSString stringWithFormat: @"%@Position", self.identifier];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    NSRect frame = [self.subviews[0] frame];
    NSInteger position;
    if (self.isVertical ) {
        position = frame.size.width;
    } else {
        position = frame.size.height;
    }
    [defaults setInteger: position forKey: key];
}

- (void)restorePosition
{
    if (self.identifier == nil) {
        return;
    }

    NSString *key = [NSString stringWithFormat: @"%@Position", self.identifier];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey: key] != nil) {
        pendingPosition = [defaults integerForKey: key];
        [self resizeSubviewsWithOldSize: self.bounds.size];
    }
}

@end
