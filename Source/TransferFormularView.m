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

#import "TransfersController.h"
#import "TransferFormularView.h"
#import "GraphicsAdditions.h"
#import "NSView+PecuniaAdditions.h"

NSString* const TransferReadyForUseDataType = @"TransferReadyForUseDataType";

@implementation TransferFormularView

@synthesize bottomArea;
@synthesize draggable;
@synthesize draggingArea;
@synthesize icon;
@synthesize controller;

- (id) initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil)
    {
        bottomArea = 60;
    }
    
    return self;
}


#pragma mark -
#pragma mark Drag and drop

// The formular as drag source.
- (void)mouseDragged: (NSEvent *)theEvent
{
    if (draggable) {
        NSPoint viewPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
        if (NSPointInRect(viewPoint,  draggingArea)) {
            [[NSCursor closedHandCursor] set];
            
            NSPasteboard *pasteBoard = [NSPasteboard pasteboardWithUniqueName];
            [pasteBoard setString: @"transfer-ready" forType: TransferReadyForUseDataType];
            
            NSImageView *imageView = (NSImageView*)[self printViewForLayerBackedView];
            
            [self dragImage: [imageView image]
                         at: NSMakePoint(0, 0)
                     offset: NSZeroSize
                      event: theEvent
                 pasteboard: pasteBoard
                     source: self
                  slideBack: YES];
        }
    } else {
        [super mouseDragged: theEvent];
    }
}

// The formular as drag target.
- (NSDragOperation)draggingEntered: (id<NSDraggingInfo>)sender
{
    return NSDragOperationNone;
}

- (void)draggingExited: (id<NSDraggingInfo>)sender
{
    [[NSCursor arrowCursor] set];
}

#pragma mark -
#pragma mark Drawing

// Shared objects.
static NSShadow* borderShadow = nil;
static NSShadow* smallShadow = nil;
static NSImage* stripes;

#define TOP_PANE_HEIGHT 100

- (void)drawRect: (NSRect) rect
{
    [NSGraphicsContext saveGraphicsState];
    
    // Initialize shared objects.
    if (borderShadow == nil)
    {
        borderShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.5]
                                                offset: NSMakeSize(3, -3)
                                            blurRadius: 8.0];
        smallShadow = [[NSShadow alloc] initWithColor: [NSColor colorWithDeviceWhite: 0 alpha: 0.2]
                                                offset: NSMakeSize(0, 0)
                                            blurRadius: 3];
        stripes = [NSImage imageNamed: @"green-slanted-stripes.png"];
    }
    
    // Outer bounds with shadow.
    NSRect bounds = self.bounds;
    bounds.size.width -= 20;
    bounds.size.height -= 10;
    bounds.origin.x += 10;
    bounds.origin.y += 10;

    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect: bounds xRadius: 8 yRadius: 8];
    [borderShadow set];
    [[NSColor colorWithPatternImage: stripes] set];
    [borderPath fill];
    [borderPath setClip];
    
    // Top pane.
    bounds.origin.x += 30;
    bounds.size.width -= 60;
    bounds.origin.y = self.bounds.size.height - 90;
    bounds.size.height = TOP_PANE_HEIGHT;
    
    draggingArea = bounds;
    
    // For composition of top shade and a semitransparent icon we need a separate image which
    // we then blend over the background.
    NSImage *shadeImage = [[NSImage alloc] initWithSize: NSMakeSize(bounds.size.width, bounds.size.height)];
    NSBezierPath *shadePath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(0, 0, bounds.size.width, bounds.size.height)
                                                              xRadius: 6
                                                              yRadius: 6];
    [shadeImage lockFocus];
    [[NSColor whiteColor] set];
    [shadePath fill];
    [icon drawAtPoint: NSMakePoint(bounds.size.width - 120, TOP_PANE_HEIGHT - icon.size.height - 19) fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1];
    [shadeImage unlockFocus];

    [smallShadow set];
    [shadeImage drawAtPoint: bounds.origin fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 0.75];
    
    // Main pane.
    bounds.size.height = self.bounds.size.height - TOP_PANE_HEIGHT - bottomArea - 5;
    bounds.origin.y = bottomArea;
    shadePath = [NSBezierPath bezierPathWithRoundedRect: bounds xRadius: 6 yRadius: 6];
    [[NSColor colorWithCalibratedRed: 131 / 255.0 green: 171 / 255.0 blue: 113 / 255.0 alpha: 0.76] set];
    [shadePath fill];

    [NSGraphicsContext restoreGraphicsState];
}

@end
