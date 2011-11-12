//
//  MCEMPieChartView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 29.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "MCEMPieChartView.h"

@interface NSObject(MCEMPieChartView)
-(void)pieChartView: (MCEMPieChartView*)view mouseOverSlice: (int)slice;
@end


@implementation MCEMPieChartView

-(void)viewDidMoveToWindow {
	[super viewDidMoveToWindow ];
    trackingRect = [self addTrackingRect:[self bounds ] owner:self userData:NULL assumeInside:NO];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	int n = [self convertToSliceFromPoint: [theEvent locationInWindow] fromView: nil ];
	if(n != slice) {
		if([delegate respondsToSelector: @selector(pieChartView:mouseOverSlice:) ])	[delegate pieChartView: self mouseOverSlice: n ];
		slice = n;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
    [[self window] setAcceptsMouseMovedEvents:YES];
    [[self window] makeFirstResponder:self];
	slice = -1;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[[self window] setAcceptsMouseMovedEvents:wasAcceptingMouseEvents];
	if([delegate respondsToSelector: @selector(pieChartView:mouseOverSlice:) ])	[delegate pieChartView: self mouseOverSlice: -1 ];
	slice = -1;
}
@end
