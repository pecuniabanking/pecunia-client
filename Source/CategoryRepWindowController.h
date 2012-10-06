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

@class ShortDate;
@class PecuniaGraphHost;
@class Category;
@class MAAttachedWindow;

@interface CategoryRepWindowController : NSObject <PecuniaSectionItem, CPTPlotSpaceDelegate, CPTPieChartDataSource, CPTBarPlotDelegate>
{
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

