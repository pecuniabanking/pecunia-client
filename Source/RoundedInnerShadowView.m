/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "RoundedInnerShadowView.h"
#import "GraphicsAdditions.h"

/**
 * Provides a specialized NSView that draws with rounded borders and an inner shadow. It also allows
 * to set a transparency for the background.
 */
@implementation RoundedInnerShadowView

static NSShadow *innerShadow = nil;

- (void)drawRect: (NSRect)dirtyRect
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: [self bounds] xRadius: 8 yRadius: 8];


    [[NSColor colorWithDeviceWhite: 1 alpha: 0.35] set];
    [path fill];

    if (innerShadow == nil) {
        innerShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: .40]
                                               offset: NSMakeSize(2.0, -1.0)
                                           blurRadius: 4.0];
    }

    [path fillWithInnerShadow: innerShadow borderOnly: NO];

    [context restoreGraphicsState];
}

@end
