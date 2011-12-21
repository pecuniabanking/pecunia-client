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

@class ShortDate;
@class PecuniaGraphHost;
@class Category;
@class MAAttachedWindow;

@interface CategoryRepWindowController : NSObject <PecuniaSectionItem, CPTPlotSpaceDelegate, CPTPieChartDataSource> {
    IBOutlet NSView* topView;
    IBOutlet PecuniaGraphHost* pieChartHost;
    
    IBOutlet NSButton* helpButton;
    IBOutlet NSView* helpContentView;
    IBOutlet NSTextField* helpText;
    
@private
    CPTXYGraph* pieChartGraph;
    CPTPieChart* earningsPlot;
    CPTPieChart* spendingsPlot;
    
    NSPoint lastMousePosition;
    CGFloat lastMouseDistance; // Distinance of the mouse from the center of the current plot.
    CGFloat lastAngle;
    CPTPieChart* currentPlot;
    NSPoint currentPlotCenter; // Center of the current plot. Only valid if currentPlot is not nil.
    
    NSMutableArray *spendingsCategories;
    NSMutableArray *earningsCategories;
    Category* currentCategory;
    ShortDate* fromDate;
    ShortDate* toDate;
    
    int earningsExplosionIndex;
    int spendingsExplosionIndex;
    
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

