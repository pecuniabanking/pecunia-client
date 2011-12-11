//
//  RoundedSidebar.m
//  Pecunia
//
//  Created by Mike on 28.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "RoundedSidebar.h"
#import "GraphicsAdditions.h"

/**
 * Gradient background with rounded corners and a shadow for sidebars. There is an additional area with a dark
 * background which provides room for buttons.
 */
@implementation RoundedSidebar

- (id) initWithFrame: (NSRect) frameRect
{
    self = [super initWithFrame: frameRect];
    if (self)
    {
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

// Background graphic elements, used in all sidebars.
static NSShadow* borderShadow = nil;
static NSGradient* backgroundGradient = nil;
static NSGradient* insetGradient = nil;

// Inset graphic elements, used in all sidebars.
static NSColor* strokeColor = nil;
static NSShadow* innerShadow1 = nil;
static NSShadow* innerShadow2 = nil;
	
- (void)drawRect: (NSRect)rect
{
    if (borderShadow == nil)
    {
        // One time initialization.
        borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.75]
                                                offset: NSMakeSize(3, -3)
                                            blurRadius: 8.0];
        
        backgroundGradient = [[NSGradient alloc]
                              initWithColorsAndLocations:
                              [NSColor colorWithDeviceRed: 240 / 255.0 green: 231 / 255.0 blue: 209 / 255.0 alpha: 1], (CGFloat) 0,
                              [NSColor whiteColor], (CGFloat) 1,
                              nil
                              ];
        insetGradient = [[NSGradient alloc]
                         initWithColorsAndLocations:
                         [NSColor colorWithDeviceWhite: 82 / 256.0 alpha: 1], (CGFloat) 0,
                         [NSColor colorWithDeviceWhite: 130 / 255.0 alpha: 1], (CGFloat) 1,
                         nil
                         ];
        innerShadow1 = [[NSShadow alloc] initWithColor: [NSColor blackColor]
                                                offset: NSZeroSize
                                            blurRadius: 3.0];
        innerShadow2 = [[NSShadow alloc] initWithColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: .52]
                                                offset: NSMakeSize(0.0, -2.0) blurRadius: 8.0];
        strokeColor = [[NSColor colorWithCalibratedWhite: .26 alpha: 1.0] retain];
    }
    
    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect([self bounds], 10, 10) xRadius: 8 yRadius: 8];
    [NSGraphicsContext saveGraphicsState];
    [borderShadow set];
    [[NSColor whiteColor] set];
    [borderPath fill];
    [borderPath addClip];
    
    [backgroundGradient drawInBezierPath: borderPath angle: 95.0];
    
    // Inset.
    NSBezierPath* insetPath = [NSBezierPath bezierPath];
    int height = [self bounds].size.height;
    [insetPath moveToPoint: NSMakePoint(47, height - 10)];
    [insetPath appendBezierPathWithArcFromPoint: NSMakePoint(47, height - 210) toPoint: NSMakePoint(39, height - 210) radius: 8];
    [insetPath lineToPoint: NSMakePoint(10, height - 210)];
    [insetPath appendBezierPathWithArcFromPoint: NSMakePoint(10, height - 10) toPoint: NSMakePoint(18, height - 10) radius: 8];
    
    // Draw the background.
    [insetGradient drawInBezierPath: insetPath angle: 90];
    
    insetPath = [NSBezierPath bezierPath];
    [insetPath moveToPoint: NSMakePoint(47, height - 10)];
    [insetPath appendBezierPathWithArcFromPoint: NSMakePoint(47, height - 210) toPoint: NSMakePoint(39, height - 210) radius: 8];
    [insetPath lineToPoint: NSMakePoint(10, height - 210)];
    
    // Inner stroke as part of the inner shadow.
    [strokeColor setStroke];
    [insetPath strokeInside];
    
    // Twofold inner shadow.
    [insetPath fillWithInnerShadow: innerShadow1 borderOnly: YES];
    [insetPath fillWithInnerShadow: innerShadow2 borderOnly: YES];

    [NSGraphicsContext restoreGraphicsState];
}

@end
