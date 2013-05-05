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

#import "FlickerView.h"

@implementation FlickerView

@synthesize size;
@synthesize code;

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        // Initialization code here.
        code = 0;
        size = 45;
    }
    return self;
}

- (void)drawRect: (NSRect)dirtyRect
{
    NSRect r;
    int    i;
    int    anchor;

    NSRect bounds = [self bounds];
    int    flickerSize = size * 5 + 20;

    r.origin = NSMakePoint((bounds.size.width - flickerSize) / 2, 0);
    r.size = NSMakeSize(size, 60);

    [[NSColor blackColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    anchor = r.origin.x + size / 2;
    [path moveToPoint: NSMakePoint(anchor, 62)];
    [path lineToPoint: NSMakePoint(anchor + 10, 80)];
    [path lineToPoint: NSMakePoint(anchor - 10, 80)];
    [path closePath];
    [path fill];

    path = [NSBezierPath bezierPath];
    anchor += 4 * size + 20;
    [path moveToPoint: NSMakePoint(anchor, 62)];
    [path lineToPoint: NSMakePoint(anchor + 10, 80)];
    [path lineToPoint: NSMakePoint(anchor - 10, 80)];
    [path closePath];
    [path fill];

    char mask = 1;
    for (i = 0; i < 5; i++) {
        if (code & mask) {
            [[NSColor whiteColor] setFill];
        } else {
            [[NSColor blackColor] setFill];
        }

        [NSBezierPath fillRect: r];
        r.origin.x += size + 5;
        mask = mask << 1;

    }
}

@end
