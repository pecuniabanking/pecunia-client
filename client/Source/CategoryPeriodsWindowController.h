/** 
 * Copyright (c) 2010, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

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

    @private
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

-(void)getMinMaxDatesForNode: (CategoryReportingNode*)node;
-(void)updatePeriodDates;
-(NSString*)keyForDate:(ShortDate*)date;
-(void)updatePeriodDataForNode:(CategoryReportingNode*)node;
-(ShortDate*)periodRefDateForDate:(ShortDate*)date;
-(void)adjustDates;
-(void)updateData;
-(void)updateStatements;


-(Category*)currentSelection;

// PecuniaSectionItem protocol
- (NSView*)mainView;
- (void)activate;
- (void)deactivate;
- (void)setCategory: (Category*)category;
- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to;

@end




