//
//  CategoryRepWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 19.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMPieChartView;
@class ShortDate;
@class TimeSliceManager;
@class MCEMPieChartView;

@interface CategoryRepWindowController : NSObject {
    IBOutlet NSTreeController	*categoryController;
	IBOutlet NSOutlineView      *categoryView;
	IBOutlet MCEMPieChartView	*incomeView;
	IBOutlet MCEMPieChartView	*expenseView;
	IBOutlet NSTableView		*incomeLegend;
	IBOutlet NSTableView		*expenseLegend;
	IBOutlet NSSplitView		*splitView;
	IBOutlet NSTextField		*incomeLabel;
	IBOutlet NSTextField		*expenseLabel;
	
	NSMutableArray				*expensesCats;
	NSMutableArray				*incomesCats;
	ShortDate					*fromDate, *toDate;
	
	IBOutlet TimeSliceManager	*tsManager;
	int							incomeExplosionIndex;
	int							expenseExplosionIndex;
	int							expensesX;
	int							incomesX;
}

-(IBAction)balancingRuleChanged: (id)sender;

-(void)updateValues;
-(void)updateViews;
-(void)setColors;

-(void)prepare;
-(void)terminateController;

@end
