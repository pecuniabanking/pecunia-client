/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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
#import <CorePlot/CorePlot.h>

#import "PecuniaSectionItem.h"
#import "ColumnLayoutCorePlotLayer.h"

#import "Category.h"

@class Category;
@class ShortDate;
@class MAAttachedWindow;
@class BWGradientBox;

@interface PecuinaGraphHost : CPTGraphHostingView
{
    NSTrackingArea* trackingArea; // To get mouse events, regardless of responder or key window state.
}

@end

@interface PecuinaSelectionGraphHost : PecuinaGraphHost
{
    CPTLimitBand* selector;
}

@property (nonatomic, retain) CPTLimitBand* selector;

@end

@interface CategoryAnalysisWindowController : NSObject <PecuniaSectionItem, CPTScatterPlotDataSource,
  CPTPlotSpaceDelegate, CPTPlotDataSource, CPTBarPlotDelegate>
{
	IBOutlet NSView* topView;

    IBOutlet PecuinaGraphHost* mainHostView;
    IBOutlet PecuinaGraphHost* turnoversHostView;
    IBOutlet PecuinaSelectionGraphHost* selectionHostView;

    IBOutlet NSSlider* groupingSlider;

    IBOutlet NSButton* helpButton;
    IBOutlet NSView* helpContentView;
    IBOutlet NSTextField* helpText;
    IBOutlet BWGradientBox *selectionBox;

    @private
	CPTXYGraph* mainGraph;
    CPTXYGraph* turnoversGraph;
    CPTXYGraph* selectionGraph;
    CPTXYAxis* mainIndicatorLine;
    CPTXYAxis* turnoversIndicatorLine;
    ColumnLayoutCorePlotLayer* infoLayer; // Content layer of the info annotation.
    CPTAnnotation* infoAnnotation;        // The host of the info layer placed in the plot area.
    CPTTextLayer* dateInfoLayer;
    CPTTextLayer* valueInfoLayer;
    CPTLimitBand* selectionBand;
    
    Category* mainCategory;

	ShortDate *referenceDate;             // The date at which the time points start.

    NSUInteger rawCount;                  // Raw number of values we have.
    NSUInteger selectionSampleCount;      // Number of values we use for the selection graph.
    
    double *timePoints;                   // Contains for each data point the relative distance in date units from the reference day.
    double *selectionTimePoints;          // Down sampled time points for the selection graph (if sampling is active at all).
    double *totalBalances;                // A balance value for each time point (full set).

    double *selectionBalances;            // Sampled balance values.
    double *positiveBalances;             // A balance value for each time point (positive main plot).
    double *negativeBalances;             // A balance value for each time point (negative main plot).
    double *balanceCounts;                // The number balances per unit for each time point.
    NSNumberFormatter* infoTextFormatter;

	ShortDate* fromDate;
	ShortDate* toDate;
    double lastInfoTimePoint;             // The time point for which the info text was last updated.
    bool doingGraphUpdates;
    
    CGFloat barWidth;
    NSDecimalNumber* totalMinValue;       // The minimum value of the currently selected category.
    NSDecimalNumber* totalMaxValue;       // Ditto for maximum.
    
    GroupingInterval groupingInterval;
    
    MAAttachedWindow* helpWindow;
}

@property (nonatomic, retain) Category* category;

@property (nonatomic, readwrite) CGFloat barWidth;
@property (nonatomic, readwrite) GroupingInterval groupingInterval;

- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to;

- (void)updateTrackingAreas;

- (IBAction)setGrouping: (id)sender;
- (IBAction)toggleHelp: (id)sender;

// PecuniaSectionItem protocol.
- (NSView*)mainView;
- (void)print;
- (void)prepare;
- (void)activate;
- (void)deactivate;

@end

