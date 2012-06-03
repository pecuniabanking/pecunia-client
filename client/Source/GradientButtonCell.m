/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

#import "GradientButtonCell.h"

#import "GraphicsAdditions.h"

@implementation GradientButtonCell

// Shared objects.
static NSGradient *blackGradient;


- (void)drawWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
    [NSGraphicsContext saveGraphicsState];
    
    // Initialize shared objects.
    if (blackGradient == nil)
    {
        blackGradient = [[NSGradient alloc] initWithColorsAndLocations:
                         [NSColor colorWithDeviceWhite: 120 / 255.0 alpha: 1], 0.0,
                         [NSColor colorWithDeviceWhite: 91 / 255.0 alpha: 1], 0.25,
                         [NSColor colorWithDeviceWhite: 33 / 255.0 alpha: 1], 1.0,
                         nil
                         ];
    }
    
    // Outer bounds with shadow.
    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect: cellFrame xRadius: 5 yRadius: 5];
    [blackGradient drawInBezierPath: borderPath angle: 90];
    
    [NSGraphicsContext restoreGraphicsState];

    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment: NSCenterTextAlignment];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSColor whiteColor], NSForegroundColorAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName,
                                nil
                                ];
    NSAttributedString *cellStringWithFormat = [[[NSAttributedString alloc] initWithString: [self title]
                                                                                attributes: attributes] autorelease];
    [cellStringWithFormat drawInRect: NSInsetRect(cellFrame, 10, 4)];
}

@end
