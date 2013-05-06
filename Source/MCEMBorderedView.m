/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

#import "MCEMBorderedView.h"

@implementation MCEMBorderedView

- (void)drawRect: (NSRect)rect
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect: [self bounds]];

    NSGradient *aGradient = [[NSGradient alloc]
                             initWithColorsAndLocations: [NSColor colorWithDeviceHue: 0.589 saturation: 0.068 brightness: 0.9 alpha: 1.0], (CGFloat) - 0.1, [NSColor whiteColor], (CGFloat)1.1,
                             nil];

    [aGradient drawInBezierPath: path angle: 90.0];

    [[NSColor colorWithDeviceRed: 0.745 green: 0.745 blue: 0.745 alpha: 1.0] setStroke];
    [NSBezierPath setDefaultLineWidth: 2.0];
    [NSBezierPath strokeRect: [self bounds]];
}

@end
