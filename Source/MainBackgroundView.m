/**
 * Copyright (c) 2011, 2015, Pecunia Project. All rights reserved.
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

#import "MainBackgroundView.h"
#import "GraphicsAdditions.h"

/**
 * Provides a custom background for the main view in the account page (and potentially other views).
 */
@implementation MainBackgroundView

#define HEADER_HEIGHT 31

static NSImage *background = nil;

- (void)drawRect: (NSRect)dirtyRect
{
    [NSGraphicsContext saveGraphicsState];

    NSRect bounds = [self bounds];
    bounds.size.height -= HEADER_HEIGHT; // Upper border transfer list.
    NSColor *color;
    color = [NSColor colorWithDeviceWhite: 1 alpha: 1];
    [color setFill];
    [NSBezierPath fillRect: [self bounds]];

    // Draw a highlight effect over the background.
    NSGradient *highlight = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.6]
                                                          endingColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0]];

    CGFloat height = self.bounds.size.height;
    NSPoint centerPoint = NSMakePoint(NSMidX(self.bounds), 2 * height - 61);
    NSPoint otherPoint = NSMakePoint(centerPoint.x, height - 61);
    [highlight drawFromCenter: centerPoint radius: 1 toCenter: otherPoint radius: height options: 0];

    bounds.origin.x = 0;
    bounds.origin.y = bounds.size.height; // Area above the transfer list.
    bounds.size.height = HEADER_HEIGHT;


    NSGradient *topGradient = [[NSGradient alloc] initWithColorsAndLocations:
                               [NSColor colorWithDeviceWhite: 60 / 255.0 alpha: 1], (CGFloat)0,
                               [NSColor colorWithDeviceWhite: 100 / 255.0 alpha: 1], (CGFloat)1,
                               nil
                               ];

    [topGradient drawInRect: bounds angle: 90.0];
    [NSGraphicsContext restoreGraphicsState];
}

@end
