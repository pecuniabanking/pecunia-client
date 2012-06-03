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
#import "iCarousel.h"
#import "TransfersController.h"

/**
 * This view is a specialized background for the transfers page.
 */
@implementation TransfersBackgroundView

- (void) dealloc
{
    [super dealloc];
}

#define DOT_RADIUS 3.5
#define DOT_SPACING 10

static NSImage* background = nil;

- (void)drawRect: (NSRect)dirtyRect
{
    if (background == nil) {
        background = [NSImage imageNamed: @"background-pattern.png"];
    }
    
    [NSGraphicsContext saveGraphicsState];
    
    // First the background.
    NSColor* color;
    if (background != nil) {
        color = [NSColor colorWithPatternImage: background];
    } else {
        color = [NSColor colorWithDeviceWhite: 110.0 / 255.0 alpha: 1];
    }
    [color setFill];
    [NSBezierPath fillRect: [self bounds]];

    NSRect dragTargetFrame = [rightPane dropTargetFrame];

    // Draw index dots for the template carousel.
    int dotCount = templateCarousel.numberOfItems;
    float dotWidth = dotCount * 2 * DOT_RADIUS + (dotCount - 1) * DOT_SPACING;
    float dotOffset = dragTargetFrame.origin.x + (dragTargetFrame.size.width - dotWidth) / 2 + DOT_RADIUS;
    float verticalOffset = self.bounds.size.height - 260;
    [[NSColor colorWithCalibratedWhite: 70 / 255.0 alpha: 1] set];
    for (int i = 0; i < dotCount; i++)
    {
        NSRect dotRect = NSMakeRect(dotOffset, verticalOffset, 2 * DOT_RADIUS, 2 * DOT_RADIUS);
        NSBezierPath *dotPath = [NSBezierPath bezierPathWithOvalInRect: dotRect];
        [dotPath setLineWidth: 1];
        if (i == templateCarousel.currentItemIndex) {
            [dotPath fill];
        } else {
            [dotPath stroke];
        }
        dotOffset += 2 * DOT_RADIUS + DOT_SPACING;
    }
    
    // Draw the target area for drop operations from the template carousel or one of the transfer
    // lists (unsent/sent transfers and transfer templates).
    NSBezierPath* dragTargetPath = [NSBezierPath bezierPathWithRoundedRect: dragTargetFrame xRadius: 20 yRadius: 20];
    [dragTargetPath setLineWidth: 8];
    [[NSColor colorWithCalibratedWhite: 90 / 255.0 alpha: 1] setStroke];
    CGFloat lineDash[2] = {20, 5};
    [dragTargetPath setLineDash: lineDash count: 2 phase: 0];
    [dragTargetPath stroke];
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
