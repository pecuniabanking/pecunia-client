/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

#import "PecuniaSectionItem.h"
#import "ColumnLayoutCorePlotLayer.h"

#import "BankingCategory.h"

@class BankingCategory;
@class ShortDate;
@class BWGradientBox;

@interface PecuinaGraphHost : CPTGraphHostingView
{
    NSTrackingArea *trackingArea; // To get mouse events, regardless of responder or key window state.
}

@end

@interface PecuinaSelectionGraphHost : PecuinaGraphHost
{
    CPTLimitBand *selector;
}

@property (nonatomic, strong) CPTLimitBand *selector;

@end

@interface CategoryAnalysisWindowController : NSObject <PecuniaSectionItem, CPTPlotSpaceDelegate,
  CPTPlotDataSource, CPTBarPlotDelegate, CPTAnimationDelegate>
{
    IBOutlet NSView *topView;

    IBOutlet PecuinaGraphHost          *mainHostView;
    IBOutlet PecuinaGraphHost          *turnoversHostView;
    IBOutlet PecuinaSelectionGraphHost *selectionHostView;

    IBOutlet NSSlider *groupingSlider;

    IBOutlet NSButton    *helpButton;
    IBOutlet NSView      *helpContentView;
    IBOutlet NSTextField *helpText;
    IBOutlet NSPopover   *helpPopover;

    IBOutlet BWGradientBox *selectionBox;
}

@property (nonatomic, weak) BankingCategory *selectedCategory;

@property (nonatomic, readwrite) CGFloat          barWidth;
@property (nonatomic, readwrite) GroupingInterval groupingInterval;

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to;

- (void)updateTrackingAreas;

- (IBAction)setGrouping: (id)sender;

// PecuniaSectionItem protocol.
- (NSView *)mainView;
- (void)print;
- (void)prepare;
- (void)activate;
- (void)deactivate;

@end
