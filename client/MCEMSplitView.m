//
//  MCEMSplitView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 01.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "MCEMSplitView.h"


@implementation MCEMSplitView

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	CGFloat dividerThickness = [self dividerThickness];
	NSRect leftRect = [[[self subviews] objectAtIndex:0] frame];
	NSRect rightRect = [[[self subviews] objectAtIndex:1] frame];
	NSRect newFrame = [self frame];
	
	leftRect.size.height = newFrame.size.height;
	leftRect.origin = NSMakePoint(0, 0);
	rightRect.size.width = newFrame.size.width - leftRect.size.width - dividerThickness;
	rightRect.size.height = newFrame.size.height;
	rightRect.origin.x = leftRect.size.width + dividerThickness;
	
	[[[self subviews] objectAtIndex:0] setFrame:leftRect];
	[[[self subviews] objectAtIndex:1] setFrame:rightRect];
}


@end
