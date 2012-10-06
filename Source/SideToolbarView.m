//
//  SideMenuView.m
//  Pecunia
//
//  Created by Mike Lischke on 04.12.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "SideToolbarView.h"
#import "GraphicsAdditions.h"

@implementation SideToolbarView

#define BORDER_RADIUS 8

- (void)updateTrackingArea
{
    if (trackingArea != nil)
    {
        [self removeTrackingArea: trackingArea];
        [trackingArea release];
    }

    trackingArea = [[[NSTrackingArea alloc] initWithRect: self.bounds
                                                 options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp
                                                   owner: self
                                                userInfo: nil]
                    retain];
    [self addTrackingArea: trackingArea];
}

- (id)initWithFrame: (NSRect)frame {

    // Move the view so that only the small are is visible.
    frame.origin.x += frame.size.width - 12; 
    self = [super initWithFrame: frame];
    
    if (self) {
        [self updateTrackingArea];
    }
    return self;
}

- (void)dealloc
{
    [trackingArea release];
    [super dealloc];
}

#pragma mark -
#pragma mark Event handling

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self updateTrackingArea];
}

- (void)mouseEntered: (NSEvent*)theEvent
{
    [super mouseEntered: theEvent];
    [self slideIn];
}

- (void)mouseExited: (NSEvent*)theEvent
{
    [super mouseExited: theEvent];
    [self slideOut];
}

#pragma mark -
#pragma mark Drawing

static NSGradient* backgroundGradient = nil;
static NSColor* strokeColor = nil;

- (void)drawRect: (NSRect)rect
{
    if (backgroundGradient == nil)
    {
        backgroundGradient = [[NSGradient alloc] initWithColorsAndLocations:
                              [NSColor colorWithDeviceRed: 240 / 255.0 green: 240 / 255.0 blue: 240 / 255.0 alpha: 1], (CGFloat) 0,
                              [NSColor whiteColor], (CGFloat) 1,
                              nil
                              ];
        strokeColor = [[NSColor colorWithCalibratedWhite: 0.35 alpha: 1.0] retain];
    }
    
    [NSGraphicsContext saveGraphicsState];
    
    NSBezierPath* borderPath = [NSBezierPath bezierPath];
    NSSize size = [self bounds].size;
    [borderPath moveToPoint: NSMakePoint(size.width - 1, 0)];
    [borderPath appendBezierPathWithArcFromPoint: NSMakePoint(0, 0)
                                         toPoint: NSMakePoint(0, BORDER_RADIUS)
                                          radius: BORDER_RADIUS];
    [borderPath appendBezierPathWithArcFromPoint: NSMakePoint(0, size.height - 1)
                                         toPoint: NSMakePoint(BORDER_RADIUS, size.height - 1)
                                          radius: BORDER_RADIUS];
    [borderPath lineToPoint: NSMakePoint(size.width - 1, size.height - 1)];
    [borderPath lineToPoint: NSMakePoint(size.width - 1, 0)];

    [backgroundGradient drawInBezierPath: borderPath angle: 90.0];

    // Draw border. For sharp lines move the points between pixels.
    NSAffineTransform* transform = [[NSAffineTransform alloc] init];
    [transform translateXBy: 0.5 yBy: 0.5];
    [borderPath transformUsingAffineTransform: transform];
    
    [strokeColor setStroke];
    [borderPath stroke];
    
    [transform release];
    
    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark -
#pragma mark Application logic

/**
 * Slides the view out leaving only a small band visible for mouse hit testing.
 */
- (void)slideOut
{
    NSRect parentBounds = self.superview.bounds;
    NSRect newFrame = self.frame;
    newFrame.origin.x = parentBounds.size.width - 12;
    [[self animator] setFrame: newFrame];
}

/**
 * Slides the view fully into view.
 */
- (void)slideIn
{
    NSRect parentBounds = self.superview.frame;
    NSRect newFrame = self.frame;
    
    newFrame.origin.x = parentBounds.size.width - newFrame.size.width;
    [[self animator] setFrame: newFrame];
}

@end
