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
@class MBTableGrid;
@class SynchronousScrollView;
@class MAAttachedWindow;
@class StatementsListView;

@interface CategoryPeriodsWindowController : NSObject <PecuniaSectionItem> {
	IBOutlet NSArrayController  *catPeriodDatesController;
	IBOutlet NSPopUpButton      *fromButton;
	IBOutlet NSPopUpButton      *toButton;
    IBOutlet MBTableGrid        *valueGrid;
	IBOutlet NSView             *mainView;
	IBOutlet NSView             *printView;
	IBOutlet NSArrayController  *statementsController;
    IBOutlet NSSlider           *groupingSlider;
    IBOutlet NSView             *statementDetailsView;
    IBOutlet StatementsListView *statementsListView;

    @private
	CategoryReportingNode		*dataRoot;
	CategoryReportingNode		*periodRoot;
	NSDictionary				*categoryHistory;
	NSMutableArray				*selectedDates;
	ShortDate					*fromDate;
	ShortDate					*toDate;
	ShortDate					*minDate;
	ShortDate					*maxDate;
	CatHistoryType				histType;
	NSManagedObjectContext		*managedObjectContext;

    // Data storage.
    NSMutableArray *dates;
    NSMutableArray *balances;     // An array of balance arrays.
    NSMutableArray *turnovers;    // An array of balance counts arrays.
    
    GroupingInterval groupingInterval;
    
    __weak NSOutlineView* outline; // The controlling outline.
    BOOL active; // YES if we are the active section.
    BOOL fadeInProgress; // YES if we are currently fading out the popup.
    
   MAAttachedWindow *detailsPopupWindow;
}

@property (nonatomic, assign) NSOutlineView* outline; // weak reference

- (IBAction)setGrouping: (id)sender;
- (IBAction)fromButtonPressed:(id)sender;
- (IBAction)toButtonPressed:(id)sender;
- (IBAction)filterStatements: (id)sender;

- (void)updatePeriodDates;
- (NSString*)keyForDate:(ShortDate*)date;
- (void)updatePeriodDataForNode:(CategoryReportingNode*)node;
- (ShortDate*)periodRefDateForDate:(ShortDate*)date;
- (void)adjustDates;
- (void)updateData;
- (void)connectScrollViews: (SynchronousScrollView *)other;

// PecuniaSectionItem protocol

@property (nonatomic, retain) Category* category;

- (NSView*)mainView;
- (void)activate;
- (void)deactivate;
- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to;

@end




