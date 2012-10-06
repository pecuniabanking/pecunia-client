//
//  CategoryHistWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 30.10.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Category.h"
#import "MainTabViewItem.h"

@class SM2DGraphView;
@class ShortDate;


@interface CategoryHistWindowController : NSObject <MainTabViewItem> {
    IBOutlet NSTreeController	*categoryController;
	IBOutlet NSArrayController  *catHistDatesController;
	IBOutlet NSOutlineView      *categoryView;
	IBOutlet SM2DGraphView	    *graphView;
	IBOutlet NSSplitView		*splitView;
	IBOutlet NSPopUpButton		*fromButton;
	IBOutlet NSPopUpButton		*toButton;
	IBOutlet NSView				*mainView;
	IBOutlet NSView				*printView;
	
	NSPoint minValues;
	NSPoint maxValues;
	
	NSManagedObjectContext		*managedObjectContext;
	NSMutableArray				*points;
	NSDictionary				*categoryHistory;
	NSMutableArray				*dates;
	NSMutableArray				*selectedDates;
	ShortDate					*fromDate;
	ShortDate					*toDate;
	
	CatHistoryType				histType;
	BOOL						invertValues;
}

@property (nonatomic, retain) NSMutableArray *points;
@property (nonatomic, retain) NSDictionary *categoryHistory;
@property (nonatomic, retain) NSMutableArray *dates;
@property (nonatomic, retain) NSMutableArray *selectedDates;
@property (nonatomic, retain) ShortDate *fromDate;
@property (nonatomic, retain) ShortDate *toDate;


-(IBAction)histTypeChanged: (id)sender;
-(IBAction)fromButtonPressed:(id)sender;
-(IBAction)toButtonPressed:(id)sender;

-(void)prepare;
-(NSView*)mainView;

-(void)drawGraph;
-(void)clearGraph;
-(void)adjustDates;
-(void)updateData;


-(Category*)currentSelection;

@end




