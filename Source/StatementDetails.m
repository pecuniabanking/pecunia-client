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

#import "StatementDetails.h"
#import "GraphicsAdditions.h"
#import "NSView+PecuniaAdditions.h"

@implementation StatementDetails

- (id) initWithFrame: (NSRect) frameRect
{
    self = [super initWithFrame: frameRect];
    if (self) {
        backgroundImage = [NSImage imageNamed: @"banknote"];
    }

    return self;
}


// Shared objects.
static NSShadow* borderShadow = nil;
static NSGradient* innerGradient = nil;

- (void) drawRect: (NSRect) rect
{
    // Initialize shared objects.
    if (borderShadow == nil)
    {
    borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.5]
                                            offset: NSMakeSize(3, -3)
                                        blurRadius: 8.0];
      innerGradient = [[NSGradient alloc] initWithColorsAndLocations: 
                       [NSColor colorWithDeviceRed: 240 / 255.0 green: 231 / 255.0 blue: 209 / 255.0 alpha: 1], 
                       (CGFloat) 0,
                       [NSColor whiteColor], 
                       (CGFloat) 1,
                       nil];
    }

    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect([self bounds], 10, 10) xRadius: 8 yRadius: 8];
    [NSGraphicsContext saveGraphicsState];
    [borderShadow set];
    [[NSColor whiteColor] set];
    [borderPath fill];
    [NSGraphicsContext restoreGraphicsState];
    [borderPath addClip];

    [innerGradient drawInBezierPath: borderPath angle: 95.0];

    // The image overlay. Scale it with the height of the view.
    CGFloat scaleFactor = ([self bounds].size.height - 40) / [backgroundImage size].height;
    NSRect targetRect = NSMakeRect([self bounds].size.width - 400, 10, scaleFactor * [backgroundImage size].width,
                                 [self bounds].size.height - 40);
    [backgroundImage drawInRect: targetRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 0.15];

    // Assigned categories bar background.
    [[NSColor colorWithDeviceWhite: 0.25 alpha: 1] set];
    targetRect = NSMakeRect(10, 28, [self bounds].size.width, 30);
    [NSBezierPath fillRect: targetRect];

    // TextFelder zeichnen
    [self drawTextFields ];
}

@end
