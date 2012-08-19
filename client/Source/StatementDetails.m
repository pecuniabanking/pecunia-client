//
//  StatementDetails.m
//  Pecunia
//
//  Created by Frank Emminghaus on 16.11.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "StatementDetails.h"
#import "GraphicsAdditions.h"

@implementation StatementDetails

- (id) initWithFrame: (NSRect) frameRect
{
  self = [super initWithFrame: frameRect];
  if (self)
    backgroundImage = [[NSImage imageNamed: @"banknote"] retain];
  
  return self;
}

- (void) dealloc
{
  [super dealloc];
  [backgroundImage release];
}

// Shared objects.
static NSShadow* borderShadow = nil;
static NSGradient* innerGradient = nil;

- (void) drawRect: (NSRect) rect
{
  // Initialize shared objects.
  if (borderShadow == nil)
  {
    borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.5]
                                            offset: NSMakeSize(3, -3)
                                        blurRadius: 8.0];
	  innerGradient = [[NSGradient alloc]
                     initWithColorsAndLocations:
                       [NSColor colorWithDeviceRed: 240 / 255.0 green: 231 / 255.0 blue: 209 / 255.0 alpha: 1], (CGFloat) 0,
                       [NSColor whiteColor], (CGFloat) 1,
                       nil];
  }
  
  NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect: NSInsetRect([self bounds], 10, 10) xRadius: 8 yRadius: 8];
  [NSGraphicsContext saveGraphicsState];
  [borderShadow set];
  [[NSColor whiteColor] set];
  [borderPath fill];
  [NSGraphicsContext restoreGraphicsState];
  [borderPath addClip];
  
	[innerGradient drawInBezierPath: borderPath angle: 95.0];
  
  // The image overlay. Scale it with the height of the view.
  CGFloat scaleFactor = ([self bounds].size.height - 40) / [backgroundImage size].height;
  NSRect targetRect = NSMakeRect([self bounds].size.width - 400, 10, scaleFactor * [backgroundImage size].width,
                                 [self bounds].size.height - 40);
  [backgroundImage drawInRect: targetRect fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 0.15];
  
  // Assigned categories bar background.
  [[NSColor colorWithDeviceWhite: 0.25 alpha: 1] set];
  targetRect = NSMakeRect(10, 28, [self bounds].size.width, 30);
  [NSBezierPath fillRect: targetRect];
    
    // TextFelder zeichnen
    NSArray *views = [self subviews];
    for(NSView *view in views) {
        if([view isKindOfClass:[NSTextField class]]) {
            NSTextField *field = (NSTextField*)view;
            if ([field isEnabled ] && [field isHidden ]) {
                NSRect r = [view frame];
                NSAttributedString *as = [[field cell] attributedStringValue];
                [as drawInRect:r];
            }
        }
    }    
}

@end
