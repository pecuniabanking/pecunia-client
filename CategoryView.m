//
//  CategoryView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 27.05.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "CategoryView.h"


@implementation CategoryView

@synthesize saveCatName;

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	
    NSPoint curLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	int row = [self  rowAtPoint: curLoc ];
	if(row < 0) return nil;
    [self selectRowIndexes: [NSIndexSet indexSetWithIndex: row ] byExtendingSelection: NO ];
	
	return [self menu ];
}

-(void)editSelectedCell
{
	[self editColumn:0 row:[self selectedRow ] withEvent:nil select:YES ];
}

@end
