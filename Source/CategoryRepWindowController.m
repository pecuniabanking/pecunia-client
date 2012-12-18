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

#import "CategoryRepWindowController.h"
#import "Category.h"
#import "MCEMOutlineViewLayout.h"
#import "ShortDate.h"
#import "TimeSliceManager.h"
#import "MOAssistant.h"

#import "GraphicsAdditions.h"
#import "NSView+PecuniaAdditions.h"
#import "NS(Attributed)String+Geometrics.h"
#import "AnimationHelper.h"
#import "MCEMDecimalNumberAdditions.h"

#import "MAAttachedWindow.h"

#import <tgmath.h>

static NSString* const PecuniaHitNotification = @"PecuniaMouseHit";

@interface PecuniaGraphHost : CPTGraphHostingView
{
    NSTrackingArea* trackingArea; // To get mouse events, regardless of responder or key window state.
}

@end

@implementation PecuniaGraphHost

- (void)updateTrackingArea
{
    if (trackingArea != nil)
    {
        [self removeTrackingArea: trackingArea];
    }

    trackingArea = [[NSTrackingArea alloc] initWithRect: NSRectFromCGRect(self.hostedGraph.plotAreaFrame.frame)
                                                 options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp
                                                   owner: self
                                                userInfo: nil];
    [self addTrackingArea: trackingArea];
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    [self updateTrackingArea];
    return self;
}

- (void)dealloc
{
    [self removeTrackingArea: trackingArea];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    [self updateTrackingArea];
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (void)sendMouseNotification: (NSEvent*)theEvent withParameters: (NSMutableDictionary*)parameters
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"x"];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.y] forKey: @"y"];
    [parameters setObject: [NSNumber numberWithInt: [theEvent buttonNumber]] forKey: @"button"];
    [center postNotificationName: PecuniaHitNotification object: nil userInfo: parameters];
}

- (void)mouseMoved: (NSEvent*)theEvent
{
    [super mouseMoved: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseMoved" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

- (void)mouseDown: (NSEvent*)theEvent
{
    [super mouseDown: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseDown" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

- (void)mouseDragged: (NSEvent*)theEvent
{
    [super mouseDragged: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseDragged" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

- (void)mouseUp: (NSEvent*)theEvent
{
    [super mouseUp: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"mouseUp" forKey: @"type"];
    [self sendMouseNotification: theEvent withParameters: parameters];
}

@end;

//--------------------------------------------------------------------------------------------------

@interface CategoryRepWindowController(Private)

- (void)setupPieCharts;
- (void)setupMiniPlots;
- (void)setupMiniPlotAxes;

- (void)updateValues;
- (void)updatePlotsEarnings: (float)earnings spendings: (float)spendings;
- (void)updateMiniPlotAxes;
- (void)hideHelp;

- (void)showInfoFor: (NSString*)category;
- (void)updateInfoLayerPosition;

@end

#define SPENDINGS_PLOT_ID 0
#define EARNINGS_PLOT_ID 1
#define SPENDINGS_SMALL_PLOT_ID 2
#define EARNINGS_SMALL_PLOT_ID 3

@implementation CategoryRepWindowController

@synthesize category = currentCategory;

- (void)awakeFromNib
{
    earningsExplosionIndex = NSNotFound;
    spendingsExplosionIndex = NSNotFound;

    spendingsCategories = [NSMutableArray arrayWithCapacity: 10];
    earningsCategories = [NSMutableArray arrayWithCapacity: 10];
    sortedSpendingValues = [NSMutableArray arrayWithCapacity: 10];
    sortedEarningValues = [NSMutableArray arrayWithCapacity: 10];

    // Set up the pie charts and restore their transformations.
    pieChartGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(pieChartHost.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [pieChartGraph applyTheme: theme];
    pieChartHost.hostedGraph = pieChartGraph;
    
    [self setupMiniPlots];
    [self setupPieCharts];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    earningsPlot.startAngle = [userDefaults floatForKey: @"earningsRotation"];
    spendingsPlot.startAngle = [userDefaults floatForKey: @"spendingsRotation"];

    // Help text.
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* path = [mainBundle pathForResource: @"category-reporting-help" ofType: @"rtf"];
    NSAttributedString* text = [[NSAttributedString alloc] initWithPath: path documentAttributes: NULL];
    [helpText setAttributedStringValue: text];
    float height = [text heightForWidth: helpText.bounds.size.width];
    helpContentView.frame = NSMakeRect(0, 0, helpText.bounds.size.width, height);

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(mouseHit:)
                                                 name: PecuniaHitNotification
                                               object: nil];
}

- (void)setupPieCharts
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)pieChartGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO; // Disallow coreplot interaction (will do unwanted manipulations).
    plotSpace.delegate = self;
    
	// Graph padding
    pieChartGraph.paddingLeft = 0;
    pieChartGraph.paddingTop = 0;
    pieChartGraph.paddingRight = 0;
    pieChartGraph.paddingBottom = 0;
    pieChartGraph.fill = nil;
    
    CPTPlotAreaFrame* frame = pieChartGraph.plotAreaFrame;
    frame.paddingLeft = 10;
    frame.paddingRight = 10;
    frame.paddingTop = 10;
    frame.paddingBottom = 10;
    
    // Border style.
    CPTMutableLineStyle* frameStyle = [CPTMutableLineStyle lineStyle];
    frameStyle.lineWidth = 1;
    frameStyle.lineColor = [[CPTColor colorWithGenericGray: 0] colorWithAlphaComponent: 0.5];
    
    frame.cornerRadius = 10;
    frame.borderLineStyle = frameStyle;
/*
    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 2.0;
    frame.shadowOffset = CGSizeMake(1, -1);
    frame.shadowOpacity = 0.25;
 */
//    frame.fill = nil;
  
	CPTMutableLineStyle* pieLineStyle = [CPTMutableLineStyle lineStyle];
	pieLineStyle.lineColor = [CPTColor colorWithGenericGray: 1];
    pieLineStyle.lineWidth = 2;
    
	// First pie chart for earnings.
	earningsPlot = [[CPTPieChart alloc] init];
    earningsPlot.hidden = YES;
	earningsPlot.dataSource = self;
	earningsPlot.delegate = self;
	earningsPlot.pieRadius = 150;
	earningsPlot.pieInnerRadius = 30;
	earningsPlot.identifier = [NSNumber numberWithInt: EARNINGS_PLOT_ID];
	earningsPlot.borderLineStyle = pieLineStyle;
	earningsPlot.startAngle = 0;
	earningsPlot.sliceDirection = CPTPieDirectionClockwise;
    earningsPlot.centerAnchor = CGPointMake(0.25, 0.6);
    earningsPlot.alignsPointsToPixels = YES;

    CPTMutableShadow* shadow = [[CPTMutableShadow alloc] init];
    shadow.shadowColor = [CPTColor colorWithComponentRed: 0 green: 0 blue: 0 alpha: 0.3];
    shadow.shadowBlurRadius = 5.0;
    shadow.shadowOffset = CGSizeMake(3, -3);
    earningsPlot.shadow = shadow;

    // For the radial offests we use a binding with an array controller and a simple backing array for storage.
    earningsPlotRadialOffsets = [[NSArrayController alloc] init];
    earningsPlotRadialOffsets.objectClass = [NSNumber class];
    earningsPlotRadialOffsets.content = [NSMutableArray arrayWithCapacity: 10];
    earningsPlotRadialOffsets.automaticallyRearrangesObjects = NO;

    [earningsPlot bind: CPTPieChartBindingPieSliceRadialOffsets
              toObject: earningsPlotRadialOffsets
           withKeyPath: @"arrangedObjects"
               options: nil];

	[pieChartGraph addPlot: earningsPlot];

	// Second pie chart for spendings.
	spendingsPlot = [[CPTPieChart alloc] init];
    spendingsPlot.hidden = YES;
	spendingsPlot.dataSource = self;
	spendingsPlot.delegate = self;
	spendingsPlot.pieRadius = 150;
	spendingsPlot.pieInnerRadius = 30;
	spendingsPlot.identifier = [NSNumber numberWithInt: SPENDINGS_PLOT_ID];
	spendingsPlot.borderLineStyle = pieLineStyle;
	spendingsPlot.startAngle = 0;
	spendingsPlot.sliceDirection = CPTPieDirectionClockwise;
    spendingsPlot.centerAnchor = CGPointMake(0.75, 0.6);
    spendingsPlot.alignsPointsToPixels = YES;
	
    spendingsPlot.shadow = shadow;

    spendingsPlotRadialOffsets = [[NSArrayController alloc] init];
    spendingsPlotRadialOffsets.objectClass = [NSNumber class];
    spendingsPlotRadialOffsets.automaticallyRearrangesObjects = NO;

    [spendingsPlot bind: CPTPieChartBindingPieSliceRadialOffsets
               toObject: spendingsPlotRadialOffsets
            withKeyPath: @"arrangedObjects" options: nil];

	[pieChartGraph addPlot: spendingsPlot];
}

/**
 * Miniplots represent ordered bar plots for the values in the pie charts.
 */
- (void)setupMiniPlots
{
    // Mini plots are placed below the pie charts, so we need a separate plot space for each.
    CPTXYPlotSpace* barPlotSpace = [[CPTXYPlotSpace alloc] init];

    // Ranges are set later.
    [pieChartGraph addPlotSpace: barPlotSpace];
    CPTPlotRange* range = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0) length: CPTDecimalFromFloat(40)];
    barPlotSpace.globalXRange = range;
    barPlotSpace.xRange = range;
    
    // Small earnings bar plot.
    earningsMiniPlot = [[CPTBarPlot alloc] init];

    CPTMutableLineStyle* barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineWidth = 1.0;
    barLineStyle.lineColor = [CPTColor colorWithComponentRed: 0 / 255.0 green: 104 / 255.0 blue: 181 / 255.0 alpha: 0.3];
    earningsMiniPlot.lineStyle = barLineStyle;
    
    earningsMiniPlot.barsAreHorizontal = NO;
    earningsMiniPlot.barWidth = CPTDecimalFromDouble(1);
    earningsMiniPlot.barCornerRadius = 0;
    earningsMiniPlot.barWidthsAreInViewCoordinates = NO;
    earningsMiniPlot.alignsPointsToPixels = YES;

    CPTImage* image = [CPTImage imageForPNGFile: [[NSBundle mainBundle] pathForResource: @"hatch 1" ofType: @"png"]];
    image.scale = 4.3;
    image.tiled = YES;
    earningsMiniPlot.fill = [CPTFill fillWithImage: image];
    
    earningsMiniPlot.baseValue = CPTDecimalFromFloat(0.0f);
    earningsMiniPlot.dataSource = self;
    earningsMiniPlot.barOffset = CPTDecimalFromFloat(4);
    earningsMiniPlot.identifier = [NSNumber numberWithInt: EARNINGS_SMALL_PLOT_ID];
    [pieChartGraph addPlot: earningsMiniPlot toPlotSpace: barPlotSpace];

    // Spendings bar plot.
    barPlotSpace = [[CPTXYPlotSpace alloc] init];

    // Ranges are set later.
    [pieChartGraph addPlotSpace: barPlotSpace];
    barPlotSpace.globalXRange = range;
    barPlotSpace.xRange = range;
    
    // Small earnings bar plot.
    spendingsMiniPlot = [[CPTBarPlot alloc] init];

    spendingsMiniPlot.lineStyle = barLineStyle;
    
    spendingsMiniPlot.barsAreHorizontal = NO;
    spendingsMiniPlot.barWidth = CPTDecimalFromDouble(1);
    spendingsMiniPlot.barCornerRadius = 0;
    spendingsMiniPlot.barWidthsAreInViewCoordinates = NO;
    spendingsMiniPlot.alignsPointsToPixels = YES;

    spendingsMiniPlot.fill = [CPTFill fillWithImage: image];
    
    spendingsMiniPlot.baseValue = CPTDecimalFromFloat(0);
    spendingsMiniPlot.dataSource = self;
    spendingsMiniPlot.barOffset = CPTDecimalFromFloat(24);
    spendingsMiniPlot.identifier = [NSNumber numberWithInt: SPENDINGS_SMALL_PLOT_ID];
    [pieChartGraph addPlot: spendingsMiniPlot toPlotSpace: barPlotSpace];

    [self setupMiniPlotAxes];
}

/**
 * Initialize a pair of xy axes.
 */
- (void)setupMiniPlotAxisX: (CPTXYAxis*)x y: (CPTXYAxis*)y offset: (float)offset
{
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.labelTextStyle = nil;
    x.labelingPolicy = CPTAxisLabelingPolicyEqualDivisions;

    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor = [CPTColor colorWithComponentRed: 0 / 255.0 green: 104 / 255.0 blue: 181 / 255.0 alpha: 0.08];

    x.axisLineStyle = lineStyle;
    x.majorGridLineStyle = lineStyle;
    x.minorGridLineStyle = nil;

    y.labelTextStyle = nil;
    y.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    
    y.axisLineStyle = lineStyle;
    y.majorGridLineStyle = lineStyle;
    y.minorGridLineStyle = nil;

    // Finally the line caps.
    CPTLineCap* lineCap = [CPTLineCap sweptArrowPlotLineCap];
    lineCap.size = CGSizeMake(6, 14);

    CPTColor* capColor = [CPTColor colorWithComponentRed: 0 / 255.0 green: 104 / 255.0 blue: 181 / 255.0 alpha: 0.5];
    
    lineStyle.lineColor = capColor;
    lineCap.fill = [CPTFill fillWithColor: capColor];
    lineCap.lineStyle = lineStyle;
    x.axisLineCapMax = lineCap;
    y.axisLineCapMax = lineCap;
    
    x.preferredNumberOfMajorTicks = 22;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(offset);
    y.gridLinesRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(offset - 0.5)
                                                    length: CPTDecimalFromFloat(14.25)];
    x.visibleRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(offset)
                                                  length: CPTDecimalFromFloat(14)];
    x.visibleAxisRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(offset)
                                                      length: CPTDecimalFromFloat(14.75)];
}

- (void)setupMiniPlotAxes
{
    // For the mini plots we use own axes for each plot. This will also cause two separate grids
    // to be shown.
    CPTXYAxisSet* axisSet = (id)pieChartGraph.axisSet;

    // Re-use the predefined axis set for the earnings mini plot.
    CPTXYAxis* x1 = axisSet.xAxis;
    x1.plotSpace = earningsMiniPlot.plotSpace;
    
    // The x-axis title is used as graph title + we use an arrow image.
    CPTMutableTextStyle* titleStyle = [[CPTMutableTextStyle alloc] init];
    titleStyle.fontName = @"Zapfino";
    titleStyle.fontSize = 16;
    titleStyle.color = [CPTColor colorWithComponentRed: 0 / 255.0 green: 104 / 255.0 blue: 181 / 255.0 alpha: 0.5];
    CPTAxisTitle* title = [[CPTAxisTitle alloc] initWithText: NSLocalizedString(@"AP64", @"") textStyle: titleStyle];
    x1.axisTitle = title;
    x1.titleOffset = -180;
    x1.titleLocation = CPTDecimalFromFloat(15);
    //x1.titleRotation = -0.05;
    
    CPTImage* arrowImage = [CPTImage imageForPNGFile: [[NSBundle mainBundle] pathForResource: @"blue arrow" ofType: @"png"]];
    CPTLayer* imageLayer = [[CPTLayer alloc] init];
    imageLayer.contents = (id)[arrowImage image];

    CPTLayerAnnotation* arrow = [[CPTLayerAnnotation alloc] initWithAnchorLayer: title.contentLayer];
    arrow.rectAnchor = CPTRectAnchorTopLeft;
    arrow.displacement = CGPointMake(-15, -50);
    
    CPTBorderedLayer* layer = [[CPTBorderedLayer alloc] initWithFrame: CGRectMake(0, 0, 24, 27)];
    layer.fill = [CPTFill fillWithImage: arrowImage]; 
    
    arrow.contentLayer = layer;
    [earningsMiniPlot addAnnotation: arrow];
    
    CPTXYAxis* y1 = axisSet.yAxis;
    y1.plotSpace = earningsMiniPlot.plotSpace;

    [self setupMiniPlotAxisX: x1 y: y1 offset: 3.25];

    // Axes for the spendings mini plot are new created.
    CPTXYAxis* x2 = [[CPTXYAxis alloc] init];
    x2.coordinate = CPTCoordinateX;
    x2.plotSpace = spendingsMiniPlot.plotSpace;

    title = [[CPTAxisTitle alloc] initWithText: NSLocalizedString(@"AP65", @"") textStyle: titleStyle];
    x2.axisTitle = title;
    x2.titleOffset = -180;
    x2.titleLocation = CPTDecimalFromFloat(36);
    //x2.titleRotation = -0.01;

    arrow = [[CPTLayerAnnotation alloc] initWithAnchorLayer: title.contentLayer];
    arrow.rectAnchor = CPTRectAnchorTopLeft;
    arrow.displacement = CGPointMake(-15, -50);
    
    layer = [[CPTBorderedLayer alloc] initWithFrame: CGRectMake(0, 0, 24, 27)];
    layer.fill = [CPTFill fillWithImage: arrowImage]; 
    
    arrow.contentLayer = layer;
    [earningsMiniPlot addAnnotation: arrow];

    CPTXYAxis* y2 = [[CPTXYAxis alloc] init];
    y2.coordinate = CPTCoordinateY;
    y2.plotSpace = spendingsMiniPlot.plotSpace;

    [self setupMiniPlotAxisX: x2 y: y2 offset: 23.25];
    
    pieChartGraph.axisSet.axes = [NSArray arrayWithObjects: x1, y1, x2, y2, nil];
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot*)plot
{
    switch ([(NSNumber*)plot.identifier intValue])
    {
        case EARNINGS_PLOT_ID:
            if ([earningsCategories count] > 0) {
                return [earningsCategories count];
            } else {
                return 1; // A single dummy value to show an inactive pie chart.
            }
        case SPENDINGS_PLOT_ID:
            if ([spendingsCategories count] > 0) {
                return [spendingsCategories count];
            } else {
                return 1;
            }
        case EARNINGS_SMALL_PLOT_ID:
            return [sortedEarningValues count];
        case SPENDINGS_SMALL_PLOT_ID:
            return [sortedSpendingValues count];
        default:
            return 0;
    }
}

- (NSNumber*)numberForPlot: (CPTPlot*)plot field: (NSUInteger)fieldEnum recordIndex: (NSUInteger)index
{
    switch ([(NSNumber*)plot.identifier intValue])
    {
        case EARNINGS_PLOT_ID:
            if (fieldEnum == CPTPieChartFieldSliceWidth) {
                if ([earningsCategories count] > 0) {
                    return [[earningsCategories objectAtIndex: index] objectForKey: @"value"];
                }
                else {
                    return [NSNumber numberWithInt: 1];
                }
            }
            break;
        case SPENDINGS_PLOT_ID:
            if (fieldEnum == CPTPieChartFieldSliceWidth) {
                if ([spendingsCategories count] > 0) {
                    return [[spendingsCategories objectAtIndex: index] objectForKey: @"value"];
                }
                else {
                    return [NSNumber numberWithInt: 1];
                }
            }
            break;
        case EARNINGS_SMALL_PLOT_ID:
            if (fieldEnum == CPTBarPlotFieldBarLocation) {
                return [NSNumber numberWithInt: index];
            }
            if (fieldEnum == CPTBarPlotFieldBarTip) {
                return [sortedEarningValues objectAtIndex: index];
            }
            break;
        case SPENDINGS_SMALL_PLOT_ID:
            if (fieldEnum == CPTBarPlotFieldBarLocation) {
                return [NSNumber numberWithInt: index];
            }
            if (fieldEnum == CPTBarPlotFieldBarTip) {
                return [sortedSpendingValues objectAtIndex: index];
            }
            break;
    }

    return (id)[NSNull null];
}

- (CPTLayer*)dataLabelForPlot: (CPTPlot*)plot recordIndex: (NSUInteger)index
{
	static CPTMutableTextStyle* labelStyle = nil;

    if (!labelStyle) {
        labelStyle = [[CPTMutableTextStyle alloc] init];
        labelStyle.color = [CPTColor blackColor];
        labelStyle.fontName = @"LucidaGrande";
        labelStyle.fontSize = 10;
    }
    
    CPTTextLayer* newLayer = (id)[NSNull null];

    switch ([(NSNumber*)plot.identifier intValue])
    {
        case EARNINGS_PLOT_ID:
            if ([earningsCategories count] > 0) {
                newLayer = [[CPTTextLayer alloc] initWithText: [[earningsCategories objectAtIndex: index] objectForKey: @"name"] style: labelStyle];
            } else {
                newLayer = [[CPTTextLayer alloc] initWithText: @"" style: labelStyle];
            }
            break;
        case SPENDINGS_PLOT_ID:
            if ([spendingsCategories count] > 0) {
                newLayer = [[CPTTextLayer alloc] initWithText: [[spendingsCategories objectAtIndex: index] objectForKey: @"name"] style: labelStyle];
            } else {
                newLayer = [[CPTTextLayer alloc] initWithText: @"" style: labelStyle];
            }
            break;
        case EARNINGS_SMALL_PLOT_ID:
            // No labels for the mini plots.
            break;
        case SPENDINGS_SMALL_PLOT_ID:
            break;
    }

	return newLayer;
}
/*
-(CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex: (NSUInteger)index
{
    if (inMouseMoveHandling) {
        return 0;
    }
                        
    CGFloat result = 0.0;
    
    switch ([(NSNumber*)pieChart.identifier intValue])
    {
        case EARNINGS_PLOT_ID:
            if ((NSInteger)index == earningsExplosionIndex) {
                result = 10.0;
            }
            break;
        case SPENDINGS_PLOT_ID:
            if ((NSInteger)index == spendingsExplosionIndex) {
                result = 10.0;
            }
            break;
    }
    
    return result;
}
*/
- (CPTFill*)sliceFillForPieChart: (CPTPieChart*)pieChart recordIndex: (NSUInteger)index
{
    NSColor* color = nil;
    
    switch ([(NSNumber*)pieChart.identifier intValue])
    {
        case EARNINGS_PLOT_ID:
            if (index < [earningsCategories count]) {
                color = [[earningsCategories objectAtIndex: index] objectForKey: @"color"];
            } else {
                color = [NSColor colorWithCalibratedWhite: 0.8 alpha: 1];
            }
            break;
        case SPENDINGS_PLOT_ID:
            if (index < [spendingsCategories count]) {
                color = [[spendingsCategories objectAtIndex: index] objectForKey: @"color"];
            } else {
                color = [NSColor colorWithCalibratedWhite: 0.8 alpha: 1];
            }
            break;
    }
    
    if (color == nil) {
        return (id)[NSNull null];
    }

    CGColorRef highlightColor = CGColorCreateFromNSColor([color highlightWithLevel: 0.5]);
    CGColorRef endColor = CGColorCreateFromNSColor(color);
    CPTGradient* gradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: highlightColor]
                                                        endingColor: [CPTColor colorWithCGColor: endColor]
                             ];
    CGColorRelease(highlightColor);
    CGColorRelease(endColor);

    gradient.angle = -45.0;
    CPTFill* gradientFill = [CPTFill fillWithGradient: gradient];

    return gradientFill;
}

#pragma mark -
#pragma mark Controller logic

- (void)pieChart: (CPTPieChart*)plot sliceWasSelectedAtRecordIndex: (NSUInteger)index
{
    currentPlot = plot;

    CPTMutableShadow* shadow = [[CPTMutableShadow alloc] init];
    shadow.shadowColor = [CPTColor colorWithComponentRed: 0 green: 44 / 255.0 blue: 179 / 255.0 alpha: 0.75];
    shadow.shadowBlurRadius = 5.0;
    shadow.shadowOffset = CGSizeMake(2, -2);
    currentPlot.shadow = shadow;
}

/**
 * Handler method for notifications sent from the graph host windows if something in the graphs need
 * adjustment, mostly due to user input.
 */
- (void)mouseHit: (NSNotification*)notification
{
    BOOL needEarningsLabelAdjustment = NO;
    BOOL needSpendingsLabelAdjustment = NO;

    if ([[notification name] isEqualToString: PecuniaHitNotification]) {
        NSDictionary* parameters = [notification userInfo];
        NSString* type = [parameters objectForKey: @"type"];
        BOOL isMouseDown = [type isEqualToString: @"mouseDown"];
        NSNumber* x = [parameters objectForKey: @"x"];
        NSNumber* y = [parameters objectForKey: @"y"];
        
        CGRect bounds = earningsPlot.plotArea.bounds;
        NSPoint earningsPlotCenter = CGPointMake(bounds.origin.x + bounds.size.width * earningsPlot.centerAnchor.x,
                                                 bounds.origin.y + bounds.size.height * earningsPlot.centerAnchor.y);
        
        bounds = earningsPlot.plotArea.bounds;
        NSPoint spendingsPlotCenter = CGPointMake(bounds.origin.x + bounds.size.width * spendingsPlot.centerAnchor.x,
                                                  bounds.origin.y + bounds.size.height * spendingsPlot.centerAnchor.y);
        
        NSPoint center = currentPlot == spendingsPlot ? spendingsPlotCenter : earningsPlotCenter;
        
        if (isMouseDown) {
            lastMousePosition = NSMakePoint([x floatValue], [y floatValue]);
            lastAngle = atan2(lastMousePosition.y - center.y, lastMousePosition.x - center.x);
        } else {
            if ([type isEqualToString: @"mouseUp"]) {
                if (currentPlot != nil) {
                    CPTMutableShadow* shadow = [[CPTMutableShadow alloc] init];
                    shadow.shadowColor = [CPTColor colorWithComponentRed: 0 green: 0 blue: 0 alpha: 0.3];
                    shadow.shadowBlurRadius = 5.0;
                    shadow.shadowOffset = CGSizeMake(3, -3);
                    currentPlot.shadow = shadow;
                    
                    currentPlot = nil;
                }
                
                // Store current values.
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setFloat: earningsPlot.startAngle forKey: @"earningsRotation"];
                [userDefaults setFloat: spendingsPlot.startAngle forKey: @"spendingsRotation"];
                
            } else {
                if ([type isEqualToString: @"mouseDragged"]) {
                    lastMousePosition = NSMakePoint([x floatValue], [y floatValue]);
                    CGFloat newAngle = atan2(lastMousePosition.y - center.y, lastMousePosition.x - center.x);
                    currentPlot.startAngle += newAngle - lastAngle;
                    lastAngle = newAngle;
                } else {
                    if ([type isEqualToString: @"mouseMoved"]) {
                        inMouseMoveHandling = YES;
                        BOOL hideInfo = YES;

                        lastMousePosition = NSMakePoint([x floatValue], [y floatValue]);
                        CGFloat mouseDistance = sqrt(pow(lastMousePosition.x - earningsPlotCenter.x, 2) +
                                                     pow(lastMousePosition.y - earningsPlotCenter.y, 2));
                        CGFloat newAngle = atan2(lastMousePosition.y - earningsPlotCenter.y,
                                                 lastMousePosition.x - earningsPlotCenter.x);

                        // The message dataIndexFromInteractionPoint returns a slice for a given position however
                        // respects the radial offset of slices, leading so to quickly alternating values
                        // when the mouse is an area which is covered by a not-offset slice but not when this slice
                        // is radially offset. Hence we apply our own hit testing here.
                        NSInteger slice = [earningsPlot pieSliceIndexAtAngle: newAngle];
                        if (mouseDistance < earningsPlot.pieInnerRadius || mouseDistance > earningsPlot.pieRadius) {
                            slice = NSNotFound;
                        }
                        
                        BOOL needInfoUpdate = earningsExplosionIndex != slice;
                        if (needInfoUpdate && earningsExplosionIndex != NSNotFound) {
                            // Setting individual entries in the array doesn't trigger KVO, so
                            // we replace the array (which is very small) every time a new slice is hit.
                            NSMutableArray *content = earningsPlotRadialOffsets.content;
                            content[earningsExplosionIndex] = [NSNumber numberWithInt: 0];
                            earningsPlotRadialOffsets.content = content;
                            needEarningsLabelAdjustment = YES;
                        }
                        earningsExplosionIndex = slice;

                        // Explode the slice only if there are more than one entries.
                        if (needInfoUpdate && slice != NSNotFound && [earningsCategories count] > 1) {
                            NSMutableArray *content = earningsPlotRadialOffsets.content;
                            content[earningsExplosionIndex] = [NSNumber numberWithInt: 10];
                            earningsPlotRadialOffsets.content = content;
                            needEarningsLabelAdjustment = YES;
                        }
                        if (slice != NSNotFound) {
                            // The found slice can be the dummy slice, so check again.
                            if ([earningsCategories count] > 0) {
                                [self showInfoFor: [[earningsCategories objectAtIndex: slice] valueForKey: @"name"]];
                                hideInfo = NO;
                            }
                        } else {
                            mouseDistance = sqrt(pow(lastMousePosition.x - spendingsPlotCenter.x, 2) +
                                                 pow(lastMousePosition.y - spendingsPlotCenter.y, 2));
                            newAngle = atan2(lastMousePosition.y - spendingsPlotCenter.y,
                                             lastMousePosition.x - spendingsPlotCenter.x);

                            slice = [spendingsPlot pieSliceIndexAtAngle: newAngle];
                            if (mouseDistance < spendingsPlot.pieInnerRadius || mouseDistance > spendingsPlot.pieRadius) {
                                slice = NSNotFound;
                            }

                            needInfoUpdate |= spendingsExplosionIndex != slice;
                            if (needInfoUpdate && spendingsExplosionIndex != NSNotFound) {
                                NSMutableArray *content = spendingsPlotRadialOffsets.content;
                                content[spendingsExplosionIndex] = [NSNumber numberWithInt: 0];
                                spendingsPlotRadialOffsets.content = content;
                                needSpendingsLabelAdjustment = YES;
                            }
                            spendingsExplosionIndex = slice;

                            if (needInfoUpdate && slice != NSNotFound && [earningsCategories count] > 1) {
                                NSMutableArray *content = spendingsPlotRadialOffsets.content;
                                content[spendingsExplosionIndex] = [NSNumber numberWithInt: 10];
                                spendingsPlotRadialOffsets.content = content;
                                needSpendingsLabelAdjustment = YES;
                            }
                            if (slice != NSNotFound) {
                                if ([spendingsCategories count] > 0) {
                                    [self showInfoFor: [[spendingsCategories objectAtIndex: slice] valueForKey: @"name"]];
                                    hideInfo = NO;
                                }
                            }
                        }
                        inMouseMoveHandling = NO;
                        
                        if (needInfoUpdate) {
                            if (hideInfo) {
                                NSPoint parkPosition = infoLayer.position;
                                parkPosition.y = pieChartGraph.bounds.size.height - 2 * infoLayer.bounds.size.height;
                                [infoLayer slideTo: parkPosition inTime: 0.5];
                                [infoLayer fadeOut];
                            } else {
                                [infoLayer fadeIn]; // Does nothing if the layer is already visible.
                                [self updateInfoLayerPosition];
                            }
                        }
                    }
                }

            }
        }
    }

    if (needEarningsLabelAdjustment) {
        [earningsPlot repositionAllLabelAnnotations];
        [earningsPlot setNeedsLayout];
        [earningsPlot setNeedsDisplay];
    }
    if (needSpendingsLabelAdjustment) {
        [spendingsPlot repositionAllLabelAnnotations];
        [spendingsPlot setNeedsLayout];
        [spendingsPlot setNeedsDisplay];
    }
}

- (void)updateValues
{
    [self hideHelp];
    
    [spendingsCategories removeAllObjects];
    [earningsCategories removeAllObjects];
    [sortedSpendingValues removeAllObjects];
    [sortedEarningValues removeAllObjects];

    earningsPlotRadialOffsets.content = [NSMutableArray arrayWithCapacity: 10];
    spendingsPlotRadialOffsets.content = [NSMutableArray arrayWithCapacity: 10];

    if (currentCategory == nil) {
        return;
    }
    
    NSMutableSet* childs = [currentCategory mutableSetValueForKey: @"children"];
    NSDecimalNumber* totalEarnings = [NSDecimalNumber zero];
    NSDecimalNumber* totalSpendings = [NSDecimalNumber zero];
    
    if ([childs count] > 0) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL balance = [userDefaults boolForKey: @"balanceCategories"];
        
        NSEnumerator* enumerator = [childs objectEnumerator];
        NSDecimalNumber* zero = [NSDecimalNumber zero];
        Category* childCategory;

        while ((childCategory = [enumerator nextObject])) {
            NSDecimalNumber* spendings = [childCategory valuesOfType: cat_spendings from: fromDate to: toDate];
            NSDecimalNumber* earnings = [childCategory valuesOfType: cat_earnings from: fromDate to: toDate];
            
            if (balance) {
                NSDecimalNumber* value = [earnings decimalNumberByAdding: spendings];

                NSMutableDictionary* pieData = [NSMutableDictionary dictionaryWithCapacity: 4];
                [pieData setObject: [childCategory localName ] forKey: @"name"];
                [pieData setObject: value forKey: @"value"];
                [pieData setObject: currentCategory.currency forKey: @"currency"];
                [pieData setObject: childCategory.categoryColor forKey: @"color"];

                switch ([value compare: zero])
                {
                    case NSOrderedAscending:
                        [spendingsCategories addObject: pieData];
                        [sortedSpendingValues addObject: [value abs]];

                        totalSpendings = [totalSpendings decimalNumberByAdding: value];
                        break;
                    case NSOrderedSame: break; // don't list categories with value 0
                    case NSOrderedDescending:
                        [earningsCategories addObject: pieData];
                        [sortedEarningValues addObject: [value abs]];
                        
                        totalEarnings = [totalEarnings decimalNumberByAdding: value];
                        break;
                }
            } else {
                totalSpendings = [totalSpendings decimalNumberByAdding: spendings];
                totalEarnings = [totalEarnings decimalNumberByAdding: earnings];
                if ([spendings compare: zero] != NSOrderedSame) {
                    NSMutableDictionary* pieData = [NSMutableDictionary dictionaryWithCapacity: 4];
                    [pieData setObject: [childCategory localName ] forKey: @"name"];
                    [pieData setObject: spendings forKey: @"value"];
                    [pieData setObject: currentCategory.currency forKey: @"currency"];
                    [pieData setObject: childCategory.categoryColor forKey: @"color"];
                    
                    [spendingsCategories addObject: pieData];
                    [sortedSpendingValues addObject: [spendings abs]];
                }
                
                if ([earnings compare: zero] != NSOrderedSame) {
                    NSMutableDictionary* pieData = [NSMutableDictionary dictionaryWithCapacity: 4];
                    [pieData setObject: [childCategory localName ] forKey: @"name"];
                    [pieData setObject: earnings forKey: @"value"];
                    [pieData setObject: currentCategory.currency forKey: @"currency"];
                    [pieData setObject: childCategory.categoryColor forKey: @"color"];
                    
                    [earningsCategories addObject: pieData];
                    [sortedEarningValues addObject: [earnings abs]];
                }
            }
        }
        
        // The sorted arrays contain values for the mini plots.
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"floatValue" ascending: NO];
        [sortedEarningValues sortUsingDescriptors: [NSArray arrayWithObject: sortDescriptor]];
        [sortedSpendingValues sortUsingDescriptors: [NSArray arrayWithObject: sortDescriptor]];
    }

    for (NSUInteger i = 0; i < earningsCategories.count; i ++) {
        [earningsPlotRadialOffsets addObject: [NSNumber numberWithInt: 0]];
    }
    for (NSUInteger i = 0; i < spendingsCategories.count; i ++) {
        [spendingsPlotRadialOffsets addObject: [NSNumber numberWithInt: 0]];
    }

    [self updatePlotsEarnings: [totalEarnings floatValue] spendings: [totalSpendings floatValue]];
    [self updateMiniPlotAxes];
}

- (void)updatePlotsEarnings: (float)earnings spendings: (float)spendings
{
    // Adjust miniplot ranges depending on the sorted values.
    float tipValue = 1;
    if ([sortedEarningValues count] > 0) {
        tipValue = [[sortedEarningValues objectAtIndex: 0] floatValue];
    }
    CPTXYPlotSpace* barPlotSpace = (CPTXYPlotSpace*)earningsMiniPlot.plotSpace;
    
    // Make the range 5 times larger than the largest value in the array
    // to compress the plot to 20% of the total height of the graph.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                           length: CPTDecimalFromFloat(5 * tipValue)];
    barPlotSpace.globalYRange = plotRange;
    barPlotSpace.yRange = plotRange;

    tipValue = 1;
    if ([sortedSpendingValues count] > 0) {
        tipValue = [[sortedSpendingValues objectAtIndex: 0] floatValue];
    }
    barPlotSpace = (CPTXYPlotSpace*)spendingsMiniPlot.plotSpace;
    
    plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                             length: CPTDecimalFromFloat(5 * tipValue)];
    barPlotSpace.globalYRange = plotRange;
    barPlotSpace.yRange = plotRange;

    [pieChartGraph reloadData];

    // Compute the radii of the pie charts based on the total values they represent and
    // change them with an animation. Do this last so we have our new values in the charts then already.
    float sum = abs(spendings) + abs(earnings);
    float spendingsShare;
    float earningsShare;
    if (sum > 0) {
        spendingsShare = abs(spendings) / sum;
        earningsShare = abs(earnings) / sum;
    } else {
        spendingsShare = 0;
        earningsShare = 0;
    }

    // Scale the radii between sensible limits.
    [CPTAnimation animate: earningsPlot
                 property: @"pieRadius"
                     from: earningsPlot.pieRadius
                       to: 40 + earningsShare * 150
                 duration: 0.4
                withDelay: 0
           animationCurve: CPTAnimationCurveQuinticInOut
                 delegate: nil];

    [CPTAnimation animate: spendingsPlot
                 property: @"pieRadius"
                     from: spendingsPlot.pieRadius
                       to: 40 + spendingsShare * 150
                 duration: 0.4
                withDelay: 0.15
           animationCurve: CPTAnimationCurveQuinticInOut
                 delegate: nil];
}

- (void)updateMiniPlotAxes
{
    CPTAxisSet* axisSet = pieChartGraph.axisSet;
    
    float range;

    // Earnings plot axes.
    if ([sortedEarningValues count] > 0) {
        range = [[sortedEarningValues objectAtIndex: 0] floatValue];
    } else {
        CPTXYPlotSpace* barPlotSpace = (CPTXYPlotSpace*)earningsMiniPlot.plotSpace;
        range = barPlotSpace.yRange.lengthDouble / 5;
    }
    
    // The magic numbers are empirically determined ratios to restrict the
    // plots in the lower area of the graph and have a constant grid line interval.
    CPTXYAxis* x = [axisSet.axes objectAtIndex: 0];
    CPTXYAxis* y = [axisSet.axes objectAtIndex: 1];
    y.majorIntervalLength = CPTDecimalFromFloat(0.16 * range);
    x.gridLinesRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                    length: CPTDecimalFromFloat(1.18 * range)];
    y.visibleRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                  length: CPTDecimalFromFloat(1.18 * range)];
    y.visibleAxisRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                      length: CPTDecimalFromFloat(1.27 * range)];
    
    // Spendings plot axes.
    if ([sortedSpendingValues count] > 0) {
        range = [[sortedSpendingValues objectAtIndex: 0] floatValue];
    } else {
        CPTXYPlotSpace* barPlotSpace = (CPTXYPlotSpace*)spendingsMiniPlot.plotSpace;
        range = barPlotSpace.yRange.lengthDouble / 5;
    }
    
    x = [axisSet.axes objectAtIndex: 2];
    y = [axisSet.axes objectAtIndex: 3];
    y.majorIntervalLength = CPTDecimalFromFloat(0.16 * range);
    x.gridLinesRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                    length: CPTDecimalFromFloat(1.18 * range)];
    y.visibleRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                  length: CPTDecimalFromFloat(1.18 * range)];
    y.visibleAxisRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0)
                                                      length: CPTDecimalFromFloat(1.27 * range)];
    
}

- (void)releaseHelpWindow
{
    [[helpButton window] removeChildWindow: helpWindow];
    [helpWindow orderOut: self];
    helpWindow = nil;
}

- (void)hideHelp
{
    if (helpWindow != nil) {
        [helpWindow fadeOut];
        
        // We need to delay the release of the help window
        // otherwise it will just disappear instead to fade out.
        // With 10.7 and completion handlers it would be way more elegant.
        [NSTimer scheduledTimerWithTimeInterval: .25
                                         target: self 
                                       selector: @selector(releaseHelpWindow)
                                       userInfo: nil
                                        repeats: NO];
    }
}

#pragma mark -
#pragma mark Info field handling

/**
 * Updates the info annotation with the given values.
 */
- (void)updateInfoLayerForCategory: (NSString*)category
                          earnings: (NSDecimalNumber*)earnings
                earningsPercentage: (CGFloat)earningsPercentage
                         spendings: (NSDecimalNumber*)spendings
               spendingsPercentage: (CGFloat)spendingsPercentage
                             color: (NSColor*)color
{
    if (infoTextFormatter == nil)
    {
        NSString* currency = (currentCategory == nil) ? @"EUR" : [currentCategory currency];
        infoTextFormatter = [[NSNumberFormatter alloc] init];
        infoTextFormatter.usesSignificantDigits = NO;
        infoTextFormatter.minimumFractionDigits = 2;
        infoTextFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        infoTextFormatter.currencyCode = currency;
        infoTextFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", infoTextFormatter.currencySymbol];
    }
    
    // Prepare the info layer if not yet done.
    if (infoLayer == nil)
    {
        CGRect frame = CGRectMake(0.5, 0.5, 120, 50);
        infoLayer = [(ColumnLayoutCorePlotLayer*)[ColumnLayoutCorePlotLayer alloc] initWithFrame: frame];
        infoLayer.hidden = YES;

        infoLayer.paddingTop = 1;
        infoLayer.paddingBottom = 3;
        infoLayer.paddingLeft = 12;
        infoLayer.paddingRight = 12;
        infoLayer.spacing = 3;

        infoLayer.shadowColor = CGColorCreateGenericGray(0, 1);
        infoLayer.shadowRadius = 5.0;
        infoLayer.shadowOffset = CGSizeMake(2, -2);
        infoLayer.shadowOpacity = 0.75;

        CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
        lineStyle.lineWidth = 2;
        lineStyle.lineColor = [CPTColor whiteColor];
        CPTFill* fill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.75]];
        infoLayer.borderLineStyle = lineStyle;
        infoLayer.fill = fill;
        infoLayer.cornerRadius = 10;
        
        CPTMutableTextStyle* textStyle = [CPTMutableTextStyle textStyle];
        textStyle.fontName = @"LucidaGrande-Bold";
        textStyle.fontSize = 14;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentRight;
        
        spendingsInfoLayer = [[CPTTextLayer alloc] initWithText: @"" style: textStyle];
        [infoLayer addSublayer: spendingsInfoLayer];

        earningsInfoLayer = [[CPTTextLayer alloc] initWithText: @"" style: textStyle];
        [infoLayer addSublayer: earningsInfoLayer];

        textStyle = [CPTMutableTextStyle textStyle];
        textStyle.fontName = @"LucidaGrande";
        textStyle.fontSize = 14;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentCenter;
        
        categoryInfoLayer = [[CPTTextLayer alloc] initWithText: @"" style: textStyle];
        categoryInfoLayer.cornerRadius = 3;
        [infoLayer addSublayer: categoryInfoLayer];
        
        // We can also prepare the annotation which hosts the info layer but don't add it to the plot area yet.
        // When we switch the plots it won't show up otherwise unless we add it on demand.
        infoAnnotation = [[CPTAnnotation alloc] init];
        infoAnnotation.contentLayer = infoLayer;
    }
    if (![pieChartGraph.annotations containsObject: infoAnnotation])
        [pieChartGraph addAnnotation: infoAnnotation]; 

    if (earnings != nil) {
        earningsInfoLayer.text = [NSString stringWithFormat: @"+%@ | %d %%", [infoTextFormatter stringFromNumber: earnings], (int)round(100 * earningsPercentage)];
    } else {
        earningsInfoLayer.text = @"--";
    }

    if (spendings != nil) {
        spendingsInfoLayer.text = [NSString stringWithFormat: @"%@ | %d %%", [infoTextFormatter stringFromNumber: spendings], (int)round(100 * spendingsPercentage)];
    } else {
        spendingsInfoLayer.text = @"--";
    }

    categoryInfoLayer.text = [NSString stringWithFormat: @" %@ ", category];
    categoryInfoLayer.backgroundColor = [color asCGColor];
    
    [infoLayer sizeToFit];
}

- (void)updateInfoLayerPosition
{
    CGRect frame = pieChartGraph.frame;
    
    CGPoint infoLayerLocation;
    infoLayerLocation.x = frame.origin.x + frame.size.width / 2;
    infoLayerLocation.y = frame.size.height - infoLayer.bounds.size.height / 2 - 10;
    
    if (infoLayer.position.x != infoLayerLocation.x || infoLayer.position.y != infoLayerLocation.y)
        [infoLayer slideTo: infoLayerLocation inTime: 0.15];
}

/**
 * Collects earnings and spendings for the given category and computes its share of the total
 * spendings/earnings. This is then displayed in the info window.
 */
- (void)showInfoFor: (NSString*)category
{
    NSDecimalNumber* earnings = [NSDecimalNumber zero];
    NSDecimalNumber* totalEarnings = [NSDecimalNumber zero];
    NSColor* color = nil;
    for (NSDictionary* entry in earningsCategories) {
        if ([[entry valueForKey: @"name"] isEqualToString: category]) {
            earnings = [entry valueForKey: @"value"];
            color = [entry valueForKey: @"color"];
        }
        totalEarnings = [totalEarnings decimalNumberByAdding: [entry valueForKey: @"value"]];
    }
    CGFloat earningsShare = ([totalEarnings floatValue] != 0) ? [earnings floatValue] / [totalEarnings floatValue] : 0;
    
    NSDecimalNumber* spendings = [NSDecimalNumber zero];
    NSDecimalNumber* totalSpendings = [NSDecimalNumber zero];
    for (NSDictionary* entry in spendingsCategories) {
        if ([[entry valueForKey: @"name"] isEqualToString: category]) {
            spendings = [entry valueForKey: @"value"];
            color = [entry valueForKey: @"color"];
        }
        totalSpendings = [totalSpendings decimalNumberByAdding: [entry valueForKey: @"value"]];
    }
    CGFloat spendingsShare = ([totalSpendings floatValue] != 0) ? [spendings floatValue] / [totalSpendings floatValue] : 0;
    
    [self updateInfoLayerForCategory: category
                            earnings: earnings
                  earningsPercentage: earningsShare
                           spendings: spendings
                 spendingsPercentage: spendingsShare
                               color: color];
    
}

#pragma mark -
#pragma mark Interface Builder actions

- (IBAction)balancingRuleChanged: (id)sender
{
    [self updateValues];
}

- (IBAction)toggleHelp: (id)sender
{
    if (!helpWindow) {
        NSPoint buttonPoint = NSMakePoint(NSMidX([helpButton frame]),
                                          NSMidY([helpButton frame]));
        buttonPoint = [topView convertPoint: buttonPoint toView: nil];
        helpWindow = [[MAAttachedWindow alloc] initWithView: helpContentView 
                                            attachedToPoint: buttonPoint 
                                                   inWindow: [topView window] 
                                                     onSide: MAPositionTopLeft 
                                                 atDistance: 20];
        
        [helpWindow setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.2 alpha: 1]];
        [helpWindow setViewMargin: 10];
        [helpWindow setBorderWidth: 0];
        [helpWindow setCornerRadius: 10];
        [helpWindow setHasArrow: YES];
        [helpWindow setDrawsRoundCornerBesideArrow: YES];

        [helpWindow setAlphaValue: 0];
        [[helpButton window] addChildWindow: helpWindow ordered: NSWindowAbove];
        [helpWindow fadeIn];
     
    } else {
        [self hideHelp];
    }
}

#pragma mark -
#pragma mark Plot animation events

- (void)animationDidStart: (CPTAnimationOperation *)operation
{
    if (operation == earningsAngleAnimation) {
        earningsPlot.hidden = NO;
    }
    if (operation == spendingsAngleAnimation) {
        spendingsPlot.hidden = NO;
    }
}

- (void)animationDidFinish: (CPTAnimationOperation *)operation
{
    if (operation == earningsAngleAnimation) {
        earningsPlot.endAngle = NAN;
        earningsAngleAnimation = nil;
    }
    if (operation == spendingsAngleAnimation) {
        spendingsPlot.endAngle = NAN;
        spendingsAngleAnimation = nil;
    }
}

- (void)animationCancelled: (CPTAnimationOperation *)operation
{
    if (operation == earningsAngleAnimation) {
        earningsPlot.endAngle = NAN;
        earningsAngleAnimation = nil;
    }
    if (operation == spendingsAngleAnimation) {
        spendingsPlot.endAngle = NAN;
        spendingsAngleAnimation = nil;
    }
}

#pragma mark -
#pragma mark PecuniaSectionItem protocol

- (void)print
{
    NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSFitPagination];
    NSPrintOperation *printOp;

    printOp = [NSPrintOperation printOperationWithView: [topView printViewForLayerBackedView] printInfo: printInfo];

    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (NSView*)mainView
{
    return topView;
}

- (void)prepare
{
}

- (void)activate;
{
    [pieChartHost updateTrackingAreas];
}

- (void)deactivate
{
    [self hideHelp];
}

- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to
{
    fromDate = from;
    toDate = to;
    [self updateValues];

    earningsAngleAnimation = [CPTAnimation animate: earningsPlot
                                          property: @"endAngle"
                                              from: earningsPlot.startAngle + 2.0 * M_PI
                                                to: earningsPlot.startAngle
                                          duration: 0.5
                                         withDelay: 0
                                    animationCurve: CPTAnimationCurveQuadraticInOut
                                          delegate: self];

    spendingsAngleAnimation = [CPTAnimation animate: spendingsPlot
                                           property: @"endAngle"
                                               from: spendingsPlot.startAngle + 2.0 * M_PI
                                                 to: spendingsPlot.startAngle
                                           duration: 0.5
                                          withDelay: 0
                                     animationCurve: CPTAnimationCurveQuadraticInOut
                                           delegate: self];
}

- (void)setCategory: (Category*)newCategory
{
    currentCategory = newCategory;
    [self updateValues];
}

@end

