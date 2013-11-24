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

#import "PecuniaSplitView.h"

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
        NSSize     totalSize = self.bounds.size;
        NSUInteger variableIndex = fixedIndex == 0 ? 1 : 0;
        NSSize     fixedSize = [self.subviews[fixedIndex] frame].size;

        if ([(NSView *)(self.subviews[fixedIndex])isHidden]) {
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

@end
