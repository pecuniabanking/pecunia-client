/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

- (id)initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self) {
    }

    return self;
}

// Shared objects.
static NSShadow *borderShadow = nil;

- (void)drawRect: (NSRect)rect
{
    NSRect bounds = [self bounds];
    if (bounds.size.width <= 20 || bounds.size.height <= 20) {
        return;
    }

    // Initialize shared objects.
    if (borderShadow == nil) {
        borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.5]
                                                offset: NSMakeSize(1, -1)
                                            blurRadius: 5.0];
    }

    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect(bounds, 10, 10) xRadius: 5 yRadius: 5];
    [NSGraphicsContext saveGraphicsState];
    [borderShadow set];
    [[NSColor whiteColor] set];
    [borderPath fill];
    [NSGraphicsContext restoreGraphicsState];
    [borderPath addClip];

    // Assigned categories bar background.
    [[NSColor colorWithDeviceWhite: 0.25 alpha: 1] set];
    NSRect targetRect = NSMakeRect(10, 28, bounds.size.width, 30);
    [NSBezierPath fillRect: targetRect];
}

@end
