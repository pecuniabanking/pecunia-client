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


static NSImage* background = nil;
static NSShadow* borderShadow = nil;

- (void)drawRect: (NSRect)dirtyRect
{
    if (background == nil) {
        background = [NSImage imageNamed: @"background-pattern.png"];
        
        borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 1 alpha: 0.5]
                                                offset: NSMakeSize(1, -1)
                                            blurRadius: 3.0];
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
    
    NSRect dropTargetFrame = [rightPane dropTargetFrame];
    
    // Draw the target area for drop operations from the preview images or one of the transfer
    // lists (unsent/sent transfers and transfer templates).
    NSBezierPath* dragTargetPath = [NSBezierPath bezierPathWithRoundedRect: dropTargetFrame xRadius: 20 yRadius: 20];
    [dragTargetPath setLineWidth: 8];
    CGFloat lineDash[2] = {20, 5};
    [dragTargetPath setLineDash: lineDash count: 2 phase: 0];

    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy: 3 yBy: -3];
    [dragTargetPath transformUsingAffineTransform: transform];
    [[NSColor colorWithCalibratedWhite: 100 / 255.0 alpha: 1] setStroke];
    [dragTargetPath stroke];

    [[NSColor colorWithCalibratedWhite: 30 / 255.0 alpha: 1] setStroke];
    [transform translateXBy: -5 yBy: 5];
    [dragTargetPath transformUsingAffineTransform: transform];
    [dragTargetPath stroke];
    
    [[NSColor colorWithCalibratedWhite: 60 / 255.0 alpha: 1] setStroke];
    [transform translateXBy: 3 yBy: -3];
    [dragTargetPath transformUsingAffineTransform: transform];
    [dragTargetPath stroke];
    
    // Draw a highlight effect over everything.
    NSGradient *highlight = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0.3]
                                                          endingColor: [NSColor colorWithCalibratedWhite: 1 alpha: 0]];

    CGFloat height = self.bounds.size.height;
    NSPoint centerPoint = NSMakePoint(NSMidX(self.bounds), height + 1);
    NSPoint otherPoint = NSMakePoint(centerPoint.x, height);
    [highlight drawFromCenter: centerPoint radius: 1 toCenter: otherPoint radius: height options: 0];
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
