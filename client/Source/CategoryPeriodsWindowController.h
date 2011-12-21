//
//  CategoryPeriodsWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 09.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Category.h"
#import "PecuniaSectionItem.h"

@class ShortDate;
@class CategoryReportingNode;

@interface CategoryPeriodsWindowController : NSObject <PecuniaSectionItem> {
    IBOutlet NSTreeController	*categoryController;
	IBOutlet NSArrayController  *catPeriodDatesController;
	IBOutlet NSPopUpButton		*fromButton;
	IBOutlet NSPopUpButton		*toButton;
	IBOutlet NSSplitView		*splitView;
	IBOutlet NSOutlineView		*categoryView;
	IBOutlet NSView				*mainView;
	IBOutlet NSView				*printView;
	IBOutlet NSArrayController  *statementsController;
	IBOutlet NSSegmentedControl *periodControl;

	CategoryReportingNode		*dataRoot;
	CategoryReportingNode		*periodRoot;
	NSDictionary				*categoryHistory;
	NSMutableArray				*dates;
	NSMutableArray				*selectedDates;
	NSNumberFormatter			*formatter;
	ShortDate					*fromDate;
	ShortDate					*toDate;
	ShortDate					*minDate;
	ShortDate					*maxDate;
	CatHistoryType				histType;
	NSManagedObjectContext		*managedObjectContext;
	int							selectedColumn;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSNumberFormatter *formatter;
@property (nonatomic, retain) ShortDate *minDate;
@property (nonatomic, retain) ShortDate *maxDate;
@property (nonatomic, retain) CategoryReportingNode *dataRoot;
@property (nonatomic, retain) CategoryReportingNode *periodRoot;
@property (nonatomic, retain) NSDictionary *categoryHistory;
@property (nonatomic, retain) NSMutableArray *dates;
@property (nonatomic, retain) NSMutableArray *selectedDates;
@property (nonatomic, retain) ShortDate *fromDate;
@property (nonatomic, retain) ShortDate *toDate;

-(IBAction)histTypeChanged: (id)sender;
-(IBAction)fromButtonPressed:(id)sender;
-(IBAction)toButtonPressed:(id)sender;
-(IBAction)doubleClicked:(id)sender;

-(NSView*)mainView;

-(void)getMinMaxDatesForNode: (CategoryReportingNode*)node;
-(void)updatePeriodDates;
-(NSString*)keyForDate:(ShortDate*)date;
-(void)updatePeriodDataForNode:(CategoryReportingNode*)node;
-(ShortDate*)periodRefDateForDate:(ShortDate*)date;
-(void)adjustDates;
-(void)updateData;
-(void)updateStatements;


-(Category*)currentSelection;

@end




