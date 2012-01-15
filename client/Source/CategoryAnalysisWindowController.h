//
//  CategoryAnalysisWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

#import "PecuniaSectionItem.h"
#import "ColumnLayoutCorePlotLayer.h"

#import "Category.h"

@class Category;
@class ShortDate;
@class MAAttachedWindow;

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
    
    CGFloat barWidth;
    NSDecimalNumber* minValue;            // The minimum value of the currently selected category.
    NSDecimalNumber* maxValue;            // Ditto for maximum.
    
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

