//
//  AccountRepWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainTabViewItem.h"

@class SM2DGraphView;
@class Category;
@class ShortDate;
@class TimeSliceManager;

@interface AccountRepWindowController : NSObject <MainTabViewItem>
{
    IBOutlet NSTreeController	*accountsController;
	IBOutlet NSOutlineView      *accountsView;
	IBOutlet SM2DGraphView	    *graphView;
	IBOutlet NSSplitView		*splitView;
	IBOutlet NSView				*mainView;
	IBOutlet NSView				*printView;

	NSPoint minValues;
	NSPoint maxValues;
	
	NSMutableArray				*points;
	NSDictionary				*balanceHistory;
	NSArray						*balanceKeys;
	ShortDate					*firstDate;
	ShortDate					*fromDate;
	ShortDate					*toDate;
	NSManagedObjectContext		*managedObjectContext;
	
	double						xTickCountFactor;
	BOOL						drawAsBars;
	NSColor						*balanceColor;
	IBOutlet TimeSliceManager	*tsManager;
	
	IBOutlet NSString			*sincome;
	IBOutlet NSString			*sexpense;
	IBOutlet NSString			*sbalance;
}

@property (nonatomic, retain) ShortDate *firstDate;
@property (nonatomic, retain) ShortDate *fromDate;
@property (nonatomic, retain) ShortDate *toDate;



-(IBAction) setGraphStyle: (id)sender;
-(IBAction) setBarStyle: (id)sender;

-(void)prepare;
-(void)terminate;

-(void)drawGraph;
-(void)updateValues;
-(void)clearGraph;
-(NSView*)mainView;

-(Category*)currentSelection;

@end

