//
//  AccountRepWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SM2DGraphView;
@class Category;
@class ShortDate;
@class TimeSliceManager;

@interface AccountRepWindowController : NSObject 
{
    IBOutlet NSTreeController	*accountsController;
	IBOutlet NSOutlineView      *accountsView;
	IBOutlet SM2DGraphView	    *graphView;
	IBOutlet NSSplitView		*splitView;

	NSPoint minValues;
	NSPoint maxValues;
	
	NSMutableArray				*points;
	NSDictionary				*balanceHistory;
	NSArray						*balanceKeys;
	ShortDate					*firstDate;
	ShortDate					*fromDate, *toDate;
	
	double						xTickCountFactor;
	BOOL						drawAsBars;
	NSColor						*balanceColor;
	IBOutlet TimeSliceManager	*tsManager;
	
	IBOutlet NSString			*sincome;
	IBOutlet NSString			*sexpense;
	IBOutlet NSString			*sbalance;
}

-(IBAction) setGraphStyle: (id)sender;
-(IBAction) setBarStyle: (id)sender;

-(void)prepare;
-(void)terminateController;

-(void)drawGraph;
-(void)updateValues;
-(void)clearGraph;

-(Category*)currentSelection;

@end
