//
//  CategoryRepWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 19.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

#import "PecuniaSectionItem.h"
#import "ColumnLayoutCorePlotLayer.h"

@class ShortDate;
@class PecuniaGraphHost;
@class Category;
@class MAAttachedWindow;

@interface CategoryRepWindowController : NSObject <PecuniaSectionItem, CPTPlotSpaceDelegate, CPTPieChartDataSource, CPTBarPlotDelegate> {
    IBOutlet NSView* topView;
    IBOutlet PecuniaGraphHost* pieChartHost;
    
    IBOutlet NSButton* helpButton;
    IBOutlet NSView* helpContentView;
    IBOutlet NSTextField* helpText;
    
@private
    CPTXYGraph* pieChartGraph;
    CPTPieChart* earningsPlot;
    CPTPieChart* spendingsPlot;
    CPTBarPlot* earningsMiniPlot;
    CPTBarPlot* spendingsMiniPlot;
    
    NSPoint lastMousePosition;
    CGFloat lastMouseDistance; // Distinance of the mouse from the center of the current plot.
    CGFloat lastAngle;
    CPTPieChart* currentPlot;
    NSPoint currentPlotCenter; // Center of the current plot. Only valid if currentPlot is not nil.
    
    ColumnLayoutCorePlotLayer* infoLayer; // Content layer of the info annotation.
    CPTAnnotation* infoAnnotation;        // The host of the info layer placed in the plot area.
    CPTTextLayer* categoryInfoLayer;
    CPTTextLayer* earningsInfoLayer;
    CPTTextLayer* spendingsInfoLayer;
    NSNumberFormatter* infoTextFormatter;

    NSMutableArray* spendingsCategories;
    NSMutableArray* sortedSpendingValues;
    NSMutableArray* earningsCategories;
    NSMutableArray* sortedEarningValues;
    Category* currentCategory;
    ShortDate* fromDate;
    ShortDate* toDate;
    
    NSInteger earningsExplosionIndex;
    NSInteger spendingsExplosionIndex;
    NSInteger lastEarningsIndex;
    NSInteger lastSpendingsIndex;
    BOOL inMouseMoveHandling;
    
    MAAttachedWindow* helpWindow;
}

@property (nonatomic, retain) Category* category;

- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to;

- (IBAction)balancingRuleChanged: (id)sender;
- (IBAction)toggleHelp: (id)sender;

// PecuniaSectionItem protocol.
- (NSView*)mainView;
- (void)print;
- (void)prepare;
- (void)activate;
- (void)deactivate;

@end

