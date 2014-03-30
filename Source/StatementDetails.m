/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

- (void)drawRect: (NSRect)rect
{
    [super drawRect: rect];

    NSRect bounds = [self bounds];

    // Assigned categories bar background.
    [[NSColor colorWithDeviceWhite: 0.25 alpha: 1] set];
    NSRect targetRect = NSMakeRect(self.leftMargin, self.bottomMargin + 18, bounds.size.width - self.leftMargin - self.rightMargin, 30);
    [NSBezierPath fillRect: targetRect];
}

@end
