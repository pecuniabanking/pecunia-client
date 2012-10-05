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
	NSRect oldLeftFrame = [[[self subviews] objectAtIndex:0] frame];
	NSRect oldRightFrame = [[[self subviews] objectAtIndex:1] frame];
	
	if (initDone == NO) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
		NSArray *items = [defaults objectForKey:[NSString stringWithFormat:@"NSSplitView Subview Frames %@", [self autosaveName ] ] ];
		if (items) {
			oldLeftFrame = NSRectFromString([items objectAtIndex:0 ]);
			oldRightFrame = NSRectFromString([items objectAtIndex:1 ]);
		}
		initDone = YES;
	} 
	
	CGFloat dividerThickness = [self dividerThickness];
	NSRect newFrame = [self frame];
	
	oldLeftFrame.size.height = newFrame.size.height;
	oldLeftFrame.origin = NSMakePoint(0, 0);
	oldRightFrame.size.width = newFrame.size.width - oldLeftFrame.size.width - dividerThickness;
	oldRightFrame.size.height = newFrame.size.height;
	oldRightFrame.origin.x = oldLeftFrame.size.width + dividerThickness;
	
	[[[self subviews] objectAtIndex:0] setFrame:oldLeftFrame];
	[[[self subviews] objectAtIndex:1] setFrame:oldRightFrame];
}

-(void)setFixLeftSubview:(BOOL)fix
{
	fixLeftSubview = fix;
}


@end
