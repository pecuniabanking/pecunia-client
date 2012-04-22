/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "TransfersBackgroundView.h"

#import "GraphicsAdditions.h"

/**
 * This view is a specialized background for the transfers page and as such tightly coupled
 * with that page (e.g. it expects a splitview as direct child).
 */
@implementation TransfersBackgroundView

- (void) dealloc
{
    [super dealloc];
}

static NSImage* background = nil;

- (void)drawRect: (NSRect)dirtyRect
{
    if (background == nil) {
        background = [NSImage imageNamed: @"background-pattern.png"];
    }
    
    [NSGraphicsContext saveGraphicsState];
    
    NSColor* color;
    if (background != nil) {
        color = [NSColor colorWithPatternImage: background];
    } else {
        color = [NSColor colorWithDeviceWhite: 110.0 / 255.0 alpha: 1];
    }
    [color setFill];
    [NSBezierPath fillRect: [self bounds]];

    // Get the content splitview if not yet done as we need to draw specifically to the space
    // under the right pane.
    if (contentSplitView == nil) {
        for (NSView *view in [self subviews]) {
            if ([view isKindOfClass: [NSSplitView class]]) {
                contentSplitView = (NSSplitView*)view;
                break;
            }
        }
    }
    if (contentSplitView != nil) {
        NSView *rightPane = [[contentSplitView subviews] objectAtIndex: 1];
        NSRect dragTargetFrame = [rightPane frame];
        dragTargetFrame.size.width -= 130;
        dragTargetFrame.size.height = 380;
        dragTargetFrame.origin.x += 64;
        dragTargetFrame.origin.y = [contentSplitView frame].origin.y + 35;
        
        NSBezierPath* dragTargetPath = [NSBezierPath bezierPathWithRoundedRect: dragTargetFrame xRadius: 20 yRadius: 20];
        [dragTargetPath setLineWidth: 8];
        [[NSColor colorWithCalibratedWhite: 90 / 255.0 alpha: 1] setStroke];
        CGFloat lineDash[2] = {20, 5};
        [dragTargetPath setLineDash: lineDash count: 2 phase: 0];
        [dragTargetPath stroke];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
