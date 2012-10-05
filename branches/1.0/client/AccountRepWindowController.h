//
//  AccountRepWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

#import "MainTabViewItem.h"

@class SM2DGraphView;
@class Category;
@class ShortDate;
@class TimeSliceManager;

@interface PecuinaGraphHost : CPTGraphHostingView
{
}
@end

@interface AccountRepWindowController : NSObject <MainTabViewItem, CPTScatterPlotDataSource, CPTPlotSpaceDelegate, CPTPlotDataSource, CPTBarPlotDelegate>
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
    
    // New graph
    IBOutlet PecuinaGraphHost *mainHostView;
    IBOutlet PecuinaGraphHost *turnoversHostView;
    IBOutlet PecuinaGraphHost *selectionHostView;
    
    @private
	CPTXYGraph* mainGraph;
    CPTXYGraph* turnoversGraph;
    CPTXYGraph* selectionGraph;
    CPTXYAxis* mainIndicatorLine;
    
	NSArray* dates;
    NSArray* balances;
    NSArray* balanceCounts; // Number of balances per day.
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
-(void)clearGraphs;
-(NSView*)mainView;

-(Category*)currentSelection;

-(void)setupMainGraph;
-(void)setupTurnoversGraph;

-(void)setupMainPlots;
-(void)setupTurnoversPlot;

-(void)updateMainGraph;
-(void)updateTurnoversGraph;

@end

