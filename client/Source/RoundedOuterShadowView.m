//
//  StatementDetails.m
//  Pecunia
//
//  Created by Frank Emminghaus on 16.11.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "RoundedOuterShadowView.h"
#import "GraphicsAdditions.h"

@implementation RoundedOuterShadowView

@synthesize indicatorColor;

- (id) initWithFrame: (NSRect) frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil)
    {
    }
    
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

// Shared objects.
static NSShadow* borderShadow = nil;
static NSImage* headerImage;

- (void) drawRect: (NSRect) rect
{
    [NSGraphicsContext saveGraphicsState];
    
    // Initialize shared objects.
    if (borderShadow == nil)
    {
        borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.75]
                                                offset: NSMakeSize(3, -3)
                                            blurRadius: 8.0];
        headerImage = [NSImage imageNamed: @"slanted_stripes_red.png"];
    }
    
    // Outer bounds with shadow.
    NSRect bounds = [self bounds];
    bounds.size.width -= 20;
    bounds.size.height -= 10;
    bounds.origin.x += 10;
    bounds.origin.y += 10;

    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect: bounds xRadius: 8 yRadius: 8];
    [borderShadow set];
    [[NSColor whiteColor] set];
    [borderPath fill];
    
    // Top bar.
    NSRect barRect = [self bounds];
    barRect.origin.y = barRect.size.height - 10;
    barRect.size.height = 10;
    [[NSColor colorWithDeviceWhite: 0.25 alpha: 1] set];
    NSRectFill(barRect);
    bounds = barRect;
    
    barRect.size.width = [headerImage size].width;
    NSRect imageRect = NSMakeRect(0, 0, [headerImage size].width, [headerImage size].height);
    while (barRect.origin.x < bounds.size.width)
    {
        [headerImage drawInRect: barRect fromRect: imageRect operation: NSCompositeSourceOver fraction: .75];
        barRect.origin.x += headerImage.size.width;
    }
    
    [NSGraphicsContext restoreGraphicsState];

    if (self.indicatorColor != nil) {
        [borderPath setClip];
        [self.indicatorColor set];
        barRect = bounds;
        barRect.origin.y = 8;
        barRect.size.height = 8;
        NSRectFill(barRect);
    }
    
}

- (void)setIndicatorColor: (NSColor*)color
{
    [indicatorColor release];
    indicatorColor = [color retain];
    [self setNeedsDisplay: YES];
}

@end
