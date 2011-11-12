//
//  RoundedShadowView.m
//  Pecunia
//
//  Created by Mike Lischke on 21.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "RoundedInnerShadowView.h"
#import "GraphicsAdditions.h"

/**
 * Provides a specialized NSView that draws with rounded borders and an inner shadow. It also allows
 * to set a transparency for the background.
 */
@implementation RoundedInnerShadowView

static NSShadow* innerShadow = nil;

- (void)drawRect: (NSRect)dirtyRect
{
  NSGraphicsContext *context = [NSGraphicsContext currentContext];
  [context saveGraphicsState];

  NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect: [self bounds] xRadius: 8 yRadius: 8];


  [[NSColor colorWithDeviceWhite: 1 alpha: 0.35] set];
  [path fill];
  
  if (innerShadow == nil)
  {
    innerShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: .40]
                                           offset: NSMakeSize(2.0, -1.0)
                                       blurRadius: 4.0];
  }

  [path fillWithInnerShadow: innerShadow borderOnly: NO];

  [context restoreGraphicsState];
}

@end
