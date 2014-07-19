/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "PecuniaSectionItem.h"
#import "PXListView.h"

@class CategoryHeatMapController;

@interface ValuePopupCell : PXListViewCell

@property (strong) IBOutlet NSTextField *remoteNameText;
@property (strong) IBOutlet NSTextField *valueText;
@property (strong) IBOutlet NSTextField *currencyText;
@property (strong) NSColor              *categoryColor;

@end

typedef enum {
    HeatMapBlockType,
    HeatMapStripeType
} HeatMapType;

@interface HeatMapView : NSView
{
    BOOL resettingDate;
}

@property (strong) CategoryHeatMapController *controller;
@property (nonatomic, assign) HeatMapType    mapType;
@property (nonatomic, assign) NSUInteger     currentYear;

@end

@class OnOffSwitchControlCell;

@interface CategoryHeatMapController : NSObject <PecuniaSectionItem, PXListViewDelegate>
{
    IBOutlet HeatMapView        *heatMapView;
    IBOutlet NSTextField        *yearLabel;
    IBOutlet NSSegmentedControl *dataSourceSwitch;

    IBOutlet NSButton    *helpButton;
    IBOutlet NSView      *helpContentView;
    IBOutlet NSTextField *helpText;
    IBOutlet NSPopover   *helpPopover;

    IBOutlet NSTextField *perDayText;
    IBOutlet NSTextField *perMonthText;

    IBOutlet NSPopover  *statementsPopover;
    IBOutlet PXListView *valuePopupList;

    IBOutlet OnOffSwitchControlCell *switchTypeButtonCell;

@private
    unsigned          currentYear;
    NSNumberFormatter *formatter;

    NSArray *currentAssignments;   // Assignments for the day we show the popup for.
}

@property (nonatomic, strong) IBOutlet NSView *mainView;

// PecuniaSectionItem protocol
@property (nonatomic, weak) Category *selectedCategory;

- (void)activate;
- (void)deactivate;
- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to;
- (void)print;

@end
