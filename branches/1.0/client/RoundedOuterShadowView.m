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

- (id) initWithFrame: (NSRect) frameRect
{
  self = [super initWithFrame: frameRect];
  if (self != nil)
    headerImage = [NSImage imageNamed: @"slanted_stripes_red.png"];
  
  return self;
}

- (void) dealloc
{
  [headerImage release];
  [super dealloc];
}

// Shared objects.
static NSShadow* borderShadow = nil;

- (void) drawRect: (NSRect) rect
{
  [NSGraphicsContext saveGraphicsState];

  // Initialize shared objects.
  if (borderShadow == nil)
  {
    borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.75]
                                            offset: NSMakeSize(3, -3)
                                        blurRadius: 8.0];
  }
  
  NSRect bounds = [self bounds];

  // Outer bounds with shadow.
  NSBezierPath* borderPath = [NSBezierPath bezierPath];
  [borderPath moveToPoint: NSMakePoint(10, bounds.size.height)];
  [borderPath lineToPoint: NSMakePoint(bounds.size.width - 10, bounds.size.height)];
  [borderPath appendBezierPathWithArcFromPoint: NSMakePoint(bounds.size.width - 10, 8)
                                       toPoint: NSMakePoint(bounds.size.height - 10, 0)
                                        radius: 8];
  [borderPath appendBezierPathWithArcFromPoint: NSMakePoint(10, 10) toPoint: NSMakePoint(10, 18) radius: 8];

  [borderShadow set];
  [[NSColor whiteColor] set];
  [borderPath fill];
  
  // Top bar.
  NSRect barRect = bounds;
  barRect.origin.y = barRect.size.height - 10;
  barRect.size.height = 10;
  [[NSColor colorWithDeviceWhite: 0.25 alpha: 1] set];
  NSRectFill(barRect);
  
  barRect.size.width = [headerImage size].width;
  NSRect imageRect = NSMakeRect(0, 0, [headerImage size].width, [headerImage size].height);
  while (barRect.origin.x < bounds.size.width - 4)
  {
    [headerImage drawInRect: barRect fromRect: imageRect operation: NSCompositeSourceOver fraction: .75];
    barRect.origin.x += headerImage.size.width;
  }
  
  [NSGraphicsContext restoreGraphicsState];
}

@end
