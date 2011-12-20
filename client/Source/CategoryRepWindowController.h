//
//  CategoryRepWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 19.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@class ShortDate;
@class PecuniaGraphHost;
@class Category;

@interface CategoryRepWindowController : NSObject <CPTPlotSpaceDelegate, CPTPieChartDataSource> {
    IBOutlet NSView* mainView;
    IBOutlet PecuniaGraphHost* pieChartHost;
    IBOutlet NSImageView* helpButton;
    
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
}

@property (nonatomic, retain) Category* category;

- (IBAction)balancingRuleChanged: (id)sender;
- (IBAction)showHelp: (id)sender;

- (NSView*)mainView;
- (void)print;
- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to;

@end

