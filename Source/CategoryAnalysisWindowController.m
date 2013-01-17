/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#include <math.h>

#import "CategoryAnalysisWindowController.h"
#import "ShortDate.h"
#import "BankAccount.h"

#import "PecuniaPlotTimeFormatter.h"
#import "MCEMDecimalNumberAdditions.h"
#import "GraphicsAdditions.h"
#import "NSView+PecuniaAdditions.h"
#import "NS(Attributed)String+Geometrics.h"
#import "AnimationHelper.h"

#import "MAAttachedWindow.h"
#import "BWGradientBox.h"

static NSString* const PecuniaGraphLayoutChangeNotification = @"PecuniaGraphLayoutChange";
static NSString* const PecuniaGraphMouseExitedNotification = @"PecuniaGraphMouseExited";

//--------------------------------------------------------------------------------------------------

@implementation PecuinaGraphHost

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

-(void)scrollWheel: (NSEvent*)theEvent
{
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        [super scrollWheel: theEvent];
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    // This method is called for touch events and mouse wheel events, which we cannot directly
    // tell apart. The event's subtype is in both cases NSTablePointerEventSubtype (which it should not
    // for wheel events). So, to get this still working we use the x delta, which is 0 for wheel events.
    CGFloat distance = [theEvent deltaX];
    if ([theEvent deltaY] == 0) {
        // A trackpad gesture (usually two-finger swipe).
        parameters[@"type"] = @"plotMoveSwipe";

        NSNumber* location = @(plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / 100);
        parameters[@"plotXLocation"] = location;
        
        NSNumber* range = @(CPTDecimalDoubleValue(plotSpace.xRange.length));
        parameters[@"plotXRange"] = range;
    } else {
        // Real scroll wheel events always have a y delta != 0.
        parameters[@"type"] = @"plotScale";
        
        distance = [theEvent deltaY];
        
        // Range location and size.
        NSNumber* location = @(plotSpace.xRange.locationDouble);
        parameters[@"plotXLocation"] = location;

        NSNumber* range = @(plotSpace.xRange.lengthDouble * (1 + distance / 100));
        parameters[@"plotXRange"] = range;
    }
    
    // Current mouse position.
    if (distance != 0) {
        CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
        CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
        parameters[@"mousePosition"] = @(pointInHostedGraph.x);

        [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
    }
}

- (void)swipeWithEvent:(NSEvent *)event
{
    // Not reliable, depending on system settings.
}

/**
 * Allow zooming the graph with a pinch gesture on a trackpad.
 */
-(void)magnifyWithEvent: (NSEvent*)theEvent
{
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        [super magnifyWithEvent: theEvent];
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
   parameters[@"type"] = @"plotScale";

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    CGFloat relativeScale = [theEvent magnification];
    
    NSNumber* location = @(plotSpace.xRange.locationDouble);
    parameters[@"plotXLocation"] = location;

    NSNumber* range = @(plotSpace.xRange.lengthDouble * (1 - relativeScale));
    parameters[@"plotXRange"] = range;

    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    parameters[@"mousePosition"] = @(pointInHostedGraph.x);
    
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseMoved: (NSEvent*)theEvent
{
    [super mouseMoved: theEvent];
    
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[@"type"] = @"mouseMove";
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    parameters[@"location"] = @(pointInHostedGraph.x);
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseDragged: (NSEvent*)theEvent
{
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        [super mouseDragged: theEvent];
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    parameters[@"type"] = @"plotMoveDrag";
    
    CGFloat distance = [theEvent deltaX];
    
    NSNumber* location = @(plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / self.hostedGraph.bounds.size.width);
    parameters[@"plotXLocation"] = location;
    
    NSNumber* range = @(CPTDecimalDoubleValue(plotSpace.xRange.length));
    parameters[@"plotXRange"] = range;
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseExited: (NSEvent*)theEvent
{
    [super mouseExited: theEvent];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center postNotificationName: PecuniaGraphMouseExitedNotification object: nil userInfo: nil];
}

@end;

//--------------------------------------------------------------------------------------------------

@implementation PecuinaSelectionGraphHost

@synthesize selector;

-(void)scrollWheel: (NSEvent*)theEvent
{
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        [super scrollWheel: theEvent];
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    short subtype = [theEvent subtype];
    if (subtype == NSTabletPointEventSubtype)
    {
        // A trackpad gesture (usually two-finger swipe).
        parameters[@"type"] = @"plotMoveSwipe";

        CGFloat distance = [theEvent deltaX];

        NSNumber* location = @(selector.range.locationDouble + plotSpace.xRange.lengthDouble * distance / 100);
        parameters[@"plotXLocation"] = location;
        
        NSNumber* range = @(CPTDecimalDoubleValue(selector.range.length));
        parameters[@"plotXRange"] = range;
    }
    else 
    {
        parameters[@"type"] = @"plotScale";
        
        CGFloat distance = [theEvent deltaY];
        
        // Range location and size.
        NSNumber* location = @(selector.range.locationDouble);
        parameters[@"plotXLocation"] = location;

        NSNumber* range = @(selector.range.lengthDouble * (1 + distance / 100));
        parameters[@"plotXRange"] = range;
    }
    
    // Current mouse position.
    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    parameters[@"mousePosition"] = @(pointInHostedGraph.x);
    
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

/**
 * Zooming with pinch, very similar to the normal host handling.
 */
-(void)magnifyWithEvent: (NSEvent*)theEvent
{
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        [super magnifyWithEvent: theEvent];
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
   parameters[@"type"] = @"plotScale";

    CGFloat relativeScale = [theEvent magnification];
    
    NSNumber* location = @(selector.range.locationDouble);
    parameters[@"plotXLocation"] = location;

    NSNumber* range = @(selector.range.lengthDouble * (1 - relativeScale));
    parameters[@"plotXRange"] = range;

    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    parameters[@"mousePosition"] = @(pointInHostedGraph.x);
    
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseMoved: (NSEvent*)theEvent
{
}

- (void)sendPlotMoveNotification: (NSEvent*)theEvent
{
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        [super mouseDragged: theEvent];
        return;
    }
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    parameters[@"type"] = @"plotMoveCenter";
    
    NSNumber* range = @(selector.range.lengthDouble);
    parameters[@"plotXRange"] = range;

    // Current mouse position as new center.
    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    parameters[@"location"] = @(pointInHostedGraph.x);
    
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

/**
 * When the user clicks on the selection graph then we move the selection directly to the mouse
 * position, such that the center of the selection is where the mouse pointer is.
 */
- (void)mouseDown: (NSEvent*)theEvent
{
    [self sendPlotMoveNotification: theEvent];
}

- (void)mouseDragged: (NSEvent*)theEvent
{
    [self sendPlotMoveNotification: theEvent];
}

@end;

//--------------------------------------------------------------------------------------------------

/**
 * Private declarations for the controller.
 */
@interface CategoryAnalysisWindowController(Private)

- (void)sanitizeDates;

- (void)setupMainGraph;
- (void)setupTurnoversGraph;
- (void)setupSelectionGraph;

- (void)setupMainPlots;
- (void)setupTurnoversPlot;
- (void)setupSelectionPlot;

- (void)updateMainGraph;
- (void)updateTurnoversGraph;
- (void)updateSelectionGraph;
- (void)updateSelectionDisplay;

- (void)regenerateGraphs;

- (int)majorTickCount;
- (void)hideHelp;
- (NSUInteger)findIndexForTimePoint: (NSUInteger)timePoint;

@end

//--------------------------------------------------------------------------------------------------

@implementation CategoryAnalysisWindowController

@synthesize category = mainCategory;

@synthesize barWidth; // The width of all bars in either the main or the turnovers bar.
@synthesize groupingInterval;

-(id)init
{
    self = [super init];
    if (self != nil) {
        barWidth = 15;
        statistics = [NSMutableDictionary dictionaryWithCapacity: 10];
        mainInfoValues = [NSMutableDictionary dictionaryWithCapacity: 5];
    }
    return self;
}

-(void)dealloc 
{
    free(timePoints);
    free(totalBalances);
    free(negativeBalances);
    free(positiveBalances);
    free(balanceCounts);
    free(selectionBalances);
    free(movingAverage);
}

-(void)awakeFromNib
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* values = [userDefaults dictionaryForKey: @"categoryAnalysis"];
    if (values != nil) {
        groupingInterval = [values[@"grouping"] intValue];
        groupingSlider.intValue = groupingInterval;
    }
    
    [self setupMainGraph];
    [self setupSelectionGraph];
    [self setupTurnoversGraph];

    // Help text.
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* path = [mainBundle pathForResource: @"category-analysis-help" ofType: @"rtf"];
    NSAttributedString* text = [[NSAttributedString alloc] initWithPath: path documentAttributes: NULL];
    [helpText setAttributedStringValue: text];
    float height = [text heightForWidth: helpText.bounds.size.width];
    helpContentView.frame = NSMakeRect(0, 0, helpText.bounds.size.width, height);

    selectionBox.hasGradient = YES;
    selectionBox.fillStartingColor = [NSColor applicationColorForKey: @"Small Background Gradient (low)"];
    selectionBox.fillEndingColor = [NSColor applicationColorForKey: @"Small Background Gradient (high)"];
    selectionBox.cornerRadius = 5;
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.5];
    shadow.shadowOffset = NSMakeSize(1, -1);
    shadow.shadowBlurRadius = 3;
    selectionBox.shadow = shadow;

    // Notifications.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(graphLayoutChanged:)
                                                 name: PecuniaGraphLayoutChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(mouseLeftGraph:)
                                                 name: PecuniaGraphMouseExitedNotification
                                               object: nil];
}

#pragma mark -
#pragma mark Graph setup

- (void)setBarWidth: (CGFloat)value
{
    self.barWidth = value;
    
    for (CPTPlot* plot in mainGraph.allPlots) {
        if ([plot isKindOfClass: [CPTBarPlot class]]) {
            ((CPTBarPlot*)plot).barWidth = CPTDecimalFromFloat(value);
        }
    }
    for (CPTPlot* plot in turnoversGraph.allPlots) {
        if ([plot isKindOfClass: [CPTBarPlot class]]) {
            ((CPTBarPlot*)plot).barWidth = CPTDecimalFromFloat(value);
        }
    }
}

- (void)setupShadowForPlot: (CPTPlot*) plot
{
    plot.shadowColor = CGColorCreateGenericGray(0, 1);
    plot.shadowRadius = 3.0;
    plot.shadowOffset = CGSizeMake(2, -2);
    plot.shadowOpacity = 0.5;
     //    */
/*
    CPTMutableShadow *shadow = [CPTMutableShadow shadow];
    shadow.shadowColor = [CPTColor colorWithComponentRed: 0 green: 0 blue: 0 alpha: 0.75];
    shadow.shadowBlurRadius = 3.0;
    shadow.shadowOffset = CGSizeMake(2, -2);
    plot.shadow = shadow;
    // */
}

- (void)setupMainAxes
{
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.minorTicksPerInterval = 0;
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.preferredNumberOfMajorTicks = [self majorTickCount];
    
    CPTMutableTextStyle* textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor colorWithComponentRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 1];
    textStyle.fontName = @"LucidaGrande";
    textStyle.fontSize = 10.0;
    x.labelTextStyle = textStyle;
    
    CPTXYAxis* y = axisSet.yAxis;
    y.labelTextStyle = textStyle;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    y.separateLayers = NO;
    
    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 0.5;
    lineStyle.lineColor = [CPTColor blackColor];
    y.majorGridLineStyle = lineStyle;
    
    lineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.25];
    y.minorGridLineStyle = lineStyle;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = nil;
    
    // Graph title, use y axis label for this.
    textStyle.textAlignment = CPTTextAlignmentCenter;
    textStyle.fontSize = 14.0;
    y.titleTextStyle = textStyle;
    y.title = NSLocalizedString(@"AP136", @"");
    y.titleOffset = 60;
}

- (void)setupMainGraph
{
    mainGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(mainHostView.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [mainGraph applyTheme: theme];
    //mainGraph.zPosition = 100;
    mainHostView.hostedGraph = mainGraph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)mainGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    
    // Border style.
    CPTMutableLineStyle* frameStyle = [CPTMutableLineStyle lineStyle];
    frameStyle.lineWidth = 1;
    frameStyle.lineColor = [[CPTColor colorWithGenericGray: 0] colorWithAlphaComponent: 0.5];
    
    // Graph padding
    mainGraph.paddingLeft = 0;
    mainGraph.paddingTop = 0;
    mainGraph.paddingRight = 0;
    mainGraph.paddingBottom = 0;
    mainGraph.fill = nil;
    
    CPTPlotAreaFrame* frame = mainGraph.plotAreaFrame;
    frame.paddingLeft = 90;
    frame.paddingRight = 50;
    frame.paddingTop = 30;
    frame.paddingBottom = 30;
    
    frame.cornerRadius = 10;
    frame.borderLineStyle = frameStyle;
/*
    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 2.0;
    frame.shadowOffset = CGSizeMake(1, -1);
    frame.shadowOpacity = 0.25;
  */
    CPTFill* fill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 1 green: 1 blue: 1 alpha: 1]];
    frame.fill = fill;
    
    [self setupMainAxes];

    // The second y axis is used as the current location identifier.
    mainIndicatorLine = [[CPTXYAxis alloc] init];
    mainIndicatorLine.hidden = YES;
    mainIndicatorLine.coordinate = CPTCoordinateY;
    mainIndicatorLine.plotSpace = plotSpace;
    mainIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    mainIndicatorLine.labelingPolicy = CPTAxisLabelingPolicyNone;
    mainIndicatorLine.separateLayers = YES;
    mainIndicatorLine.preferredNumberOfMajorTicks = 6;
    mainIndicatorLine.minorTicksPerInterval = 0;

    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithGenericGray: 64 / 255.0];
    lineStyle.lineCap = kCGLineCapRound;
    lineStyle.dashPattern = lineStyle.dashPattern = @[@10.0f,
                                                     @5.0f];
    mainIndicatorLine.axisLineStyle = lineStyle;
    mainIndicatorLine.majorTickLineStyle = nil;
    
    // Add the mainIndicatorLine to the axis set.
    // It is essential to first assign the axes to be used in the arrayWithObject call
    // to local variables or all kind of weird things start showing up later (mostly with invalid coordinates).
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    CPTXYAxis* y = axisSet.yAxis;
    axisSet.axes = @[x, y, mainIndicatorLine];
}

- (void)setupTurnoversAxes
{
    CPTXYAxisSet* axisSet = (id)turnoversGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.labelTextStyle = nil;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.preferredNumberOfMajorTicks = [self majorTickCount];
    
    CPTMutableTextStyle* textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor colorWithComponentRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 1];
    textStyle.fontName = @"LucidaGrande";
    textStyle.fontSize = 10.0;
    
    CPTXYAxis* y = axisSet.yAxis;
    y.labelTextStyle = textStyle;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    
    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 0.25;
    lineStyle.lineColor = [CPTColor blackColor];
    y.majorGridLineStyle = lineStyle;
    
    lineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0];
    y.majorTickLineStyle = nil;
    
    lineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.25];
    y.minorGridLineStyle = lineStyle;
    y.axisLineStyle = lineStyle;
    y.minorTickLineStyle = nil;
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.usesSignificantDigits = YES;
    formatter.minimumFractionDigits = 0;
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.zeroSymbol = @"0";
    y.labelFormatter = formatter;
    
    // Graph title, use y axis label for this.
    textStyle.textAlignment = CPTTextAlignmentCenter;
    textStyle.fontSize = 12.0;
    y.titleTextStyle = textStyle;
    y.title = NSLocalizedString(@"transfers", @"");
    y.titleOffset = 60;
}

- (void)setupTurnoversGraph
{
    turnoversGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(turnoversHostView.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [turnoversGraph applyTheme: theme];
    //turnoversGraph.zPosition = -100;
    turnoversHostView.hostedGraph = turnoversGraph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)turnoversGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    
    // Frame setup (background, border).
    CPTMutableLineStyle* frameStyle = [CPTMutableLineStyle lineStyle];
    frameStyle.lineWidth = 1;
    frameStyle.lineColor = [[CPTColor colorWithGenericGray: 0] colorWithAlphaComponent: 0.5];
    
    // Graph properties.
    turnoversGraph.fill = nil;
    turnoversGraph.paddingLeft = 0;
    turnoversGraph.paddingTop = 0;
    turnoversGraph.paddingRight = 0;
    turnoversGraph.paddingBottom = 0;
    
    CPTPlotAreaFrame* frame = turnoversGraph.plotAreaFrame;
    frame.paddingLeft = 90;
    frame.paddingRight = 50;
    frame.paddingTop = 15;
    frame.paddingBottom = 15;
    
    frame.cornerRadius = 10;
    frame.borderLineStyle = frameStyle;
    /*
    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 2.0;
    frame.shadowOffset = CGSizeMake(1, -1);
    frame.shadowOpacity = 0.25;
    */
    [self setupTurnoversAxes];
    
    // The second y axis is used as the current location identifier.
    turnoversIndicatorLine = [[CPTXYAxis alloc] init];
    turnoversIndicatorLine.hidden = YES;
    turnoversIndicatorLine.coordinate = CPTCoordinateY;
    turnoversIndicatorLine.plotSpace = plotSpace;
    turnoversIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    turnoversIndicatorLine.labelingPolicy = CPTAxisLabelingPolicyNone;
    turnoversIndicatorLine.separateLayers = NO;
    turnoversIndicatorLine.preferredNumberOfMajorTicks = 6;
    turnoversIndicatorLine.minorTicksPerInterval = 0;

    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithGenericGray: 64 / 255.0];
    lineStyle.dashPattern = lineStyle.dashPattern = @[@10.0f,
                                                     @5.0f];
    turnoversIndicatorLine.axisLineStyle = lineStyle;
    turnoversIndicatorLine.majorTickLineStyle = nil;
    
    // Add the second y axis to the axis set.
    CPTXYAxisSet* axisSet = (id)turnoversGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    CPTXYAxis* y = axisSet.yAxis;
    axisSet.axes = @[x, y, turnoversIndicatorLine];
}

- (void)setupSelectionAxes
{
    CPTMutableLineStyle* lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent: 0.2];

    CPTXYAxisSet* axisSet = (id)selectionGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.minorTicksPerInterval = 0;
    x.labelingPolicy = CPTAxisLabelingPolicyEqualDivisions;
    x.preferredNumberOfMajorTicks = 60;

    x.majorGridLineStyle = lineStyle;
    x.labelTextStyle = nil;
    x.separateLayers = NO;
    x.minorGridLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.axisLineStyle = nil;

    CPTXYAxis* y = axisSet.yAxis;
    y.minorTicksPerInterval = 0;
    y.labelingPolicy = CPTAxisLabelingPolicyEqualDivisions;
    y.preferredNumberOfMajorTicks = 8;
    y.majorGridLineStyle = lineStyle;
    y.labelTextStyle = nil;
    y.separateLayers = NO;
    y.minorGridLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = nil;

    // Graph title, use y axis label for this.
    CPTMutableTextStyle* textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor whiteColor];
    textStyle.fontName = @"LucidaGrande";
    textStyle.fontSize = 10.0;
    textStyle.textAlignment = CPTTextAlignmentCenter;
    y.titleTextStyle = textStyle;
    y.title = NSLocalizedString(@"AP137", @"");
    y.titleOffset = 8;
}

-(void)setupSelectionGraph
{
    selectionGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(selectionHostView.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [selectionGraph applyTheme: theme];
    //selectionGraph.zPosition = -100;
    selectionHostView.hostedGraph = selectionGraph;

    selectionGraph.fill = nil;
    selectionGraph.paddingLeft = 0;
    selectionGraph.paddingTop = 0;
    selectionGraph.paddingRight = 0;
    selectionGraph.paddingBottom = 0;

    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)selectionGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    
    // Frame setup (background, border, shadow).
    CPTPlotAreaFrame* frame = selectionGraph.plotAreaFrame;
    frame.paddingLeft = 30;
    frame.paddingRight = 10;
    frame.paddingTop = 10;
    frame.paddingBottom = 10;
    
    frame.cornerRadius = 5;
    frame.borderLineStyle = nil;
    
    CPTGradient* gradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithGenericGray: 80 / 255.0]
                                                        endingColor: [CPTColor colorWithGenericGray: 30 / 255.0]
                             ];
    gradient.angle = -87.0;
    CPTFill* gradientFill = [CPTFill fillWithGradient: gradient];
    frame.fill = gradientFill;

    CPTMutableShadow *shadow = [CPTMutableShadow shadow];
    shadow.shadowColor = [CPTColor yellowColor];
    shadow.shadowBlurRadius = 3.0;
    shadow.shadowOffset = CGSizeMake(2, -2);
    frame.shadow = shadow;

    [self setupSelectionAxes];
}

- (CPTScatterPlot*)createScatterPlotWithFill: (CPTFill*)fill
{
    CPTScatterPlot* linePlot = [[CPTScatterPlot alloc] init];
    linePlot.alignsPointsToPixels = YES;
    
    linePlot.dataLineStyle = nil;
    linePlot.interpolation = CPTScatterPlotInterpolationStepped;

    linePlot.areaFill = fill;
    linePlot.areaBaseValue = CPTDecimalFromInt(0);
    
    linePlot.delegate = self;
    linePlot.dataSource = self;
    
    return linePlot;
}

- (CPTBarPlot*)createBarPlotWithFill: (CPTFill*)fill withBorder: (BOOL)withBorder
{
    CPTBarPlot *barPlot = [[CPTBarPlot alloc] init];
    barPlot.barBasesVary = NO;
    barPlot.barWidthsAreInViewCoordinates = YES;
    barPlot.barWidth = CPTDecimalFromFloat(barWidth);
    barPlot.barCornerRadius = 3.0f;
    barPlot.barsAreHorizontal = NO;
    barPlot.baseValue = CPTDecimalFromInt(0);
    barPlot.alignsPointsToPixels = YES;
    
    if (withBorder) {
        CPTMutableLineStyle* lineStyle = [[CPTMutableLineStyle alloc] init];
        lineStyle.lineColor = [CPTColor whiteColor];
        lineStyle.lineWidth = 1;
        barPlot.lineStyle = lineStyle;
    } else {
        barPlot.lineStyle = nil;
    }
    barPlot.fill = fill;
    
    barPlot.delegate = self;
    barPlot.dataSource = self;
    
    return barPlot;
}

-(void)setupMainPlots
{
    [mainGraph removePlotWithIdentifier: @"positivePlot"];
    [mainGraph removePlotWithIdentifier: @"negativePlot"];
    [mainGraph removePlotWithIdentifier: @"averagePlot"];

    // The main graph contains two plots, one for the positive values (with a gray fill)
    // and the other one for negative values (with a red fill).
    // Depending on whether we view a bank account or a normal category either line or bar plots are used.
    if (mainCategory != nil) {
        CGColorRef gradientHighColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Positive Plot Gradient (high)"] colorWithAlphaComponent: 0.75]);
        CGColorRef gradientLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Positive Plot Gradient (low)"] colorWithAlphaComponent: 1]);
        CPTGradient* positiveGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                                    endingColor: [CPTColor colorWithCGColor: gradientLowColor]
                                         ];
        CGColorRelease(gradientHighColor);
        CGColorRelease(gradientLowColor);

        positiveGradient.angle = -90.0;
        CPTFill* positiveGradientFill = [CPTFill fillWithGradient: positiveGradient];

        gradientHighColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Negative Plot Gradient (high)"] colorWithAlphaComponent: 1]);
        gradientLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Negative Plot Gradient (low)"] colorWithAlphaComponent: 0.9]);
        CPTGradient* negativeGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                                    endingColor: [CPTColor colorWithCGColor: gradientLowColor]
                                         ];
        CGColorRelease(gradientHighColor);
        CGColorRelease(gradientLowColor);
        
        negativeGradient.angle = -90.0;
        CPTFill* negativeGradientFill = [CPTFill fillWithGradient: negativeGradient];
        
        CPTPlot* plot;
        if (mainCategory.isBankAccount) {
            plot = [self createScatterPlotWithFill: positiveGradientFill];
        } else {
            plot = [self createBarPlotWithFill: positiveGradientFill withBorder: YES];
        }
        
        CPTMutableTextStyle* labelTextStyle = [CPTMutableTextStyle textStyle];
        labelTextStyle.color = [CPTColor blackColor];
        plot.labelTextStyle = labelTextStyle;
        
        plot.identifier = @"positivePlot";
        [self setupShadowForPlot: plot];
        
        [mainGraph addPlot: plot];
        
        // The negative plot.
        if (mainCategory.isBankAccount) {
            plot = [self createScatterPlotWithFill: negativeGradientFill];
        } else {
            plot = [self createBarPlotWithFill: negativeGradientFill withBorder: YES];
        }
        
        plot.identifier = @"negativePlot";
        [self setupShadowForPlot: plot];
        
        [mainGraph addPlot: plot];

        // Moving average plot.
        CPTScatterPlot* averagePlot = [self createScatterPlotWithFill: nil];
        averagePlot.interpolation = CPTScatterPlotInterpolationCurved;
        averagePlot.identifier = @"averagePlot";

        CPTMutableLineStyle* lineStyle = [[CPTMutableLineStyle alloc] init];
        CGColorRef lineColor;
        if (mainCategory.isBankAccount) {
            lineColor = CGColorCreateFromNSColor([NSColor applicationColorForKey: @"Bank Account Average Line"]);
        } else {
            lineColor = CGColorCreateFromNSColor([NSColor applicationColorForKey: @"Category Average Line"]);
        }
        lineStyle.lineColor = [CPTColor colorWithCGColor: lineColor];
        CGColorRelease(lineColor);

        lineStyle.lineWidth = 1;
        lineStyle.dashPattern = @[@8.0f, @2.5f];
        averagePlot.dataLineStyle = lineStyle;

        // Line "border".
        CPTMutableShadow *shadow = [CPTMutableShadow shadow];
        if (mainCategory.isBankAccount) {
            shadow.shadowColor = [CPTColor colorWithComponentRed: 0 green: 0 blue: 0 alpha: 0.75];
            shadow.shadowBlurRadius = 2.0;
        } else {
            shadow.shadowColor = [CPTColor colorWithComponentRed: 1 green: 1 blue: 1 alpha: 1];
            shadow.shadowBlurRadius = 5.0;
        }
        shadow.shadowOffset = CGSizeMake(0, 0);
        averagePlot.shadow = shadow;

        [mainGraph addPlot: averagePlot];
    }
    
    [self updateMainGraph];
}

-(void)setupTurnoversPlot
{
    [turnoversGraph removePlotWithIdentifier: @"turnoversPlot"];

    CGColorRef gradientHighColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Turnovers Plot Gradient (high)"] colorWithAlphaComponent: 0.75]);
    CGColorRef gradientLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Turnovers Plot Gradient (low)"] colorWithAlphaComponent: 0.75]);
    CPTGradient* areaGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                            endingColor: [CPTColor colorWithCGColor: gradientLowColor]
                                 ];
    CGColorRelease(gradientHighColor);
    CGColorRelease(gradientLowColor);

    areaGradient.angle = -90.0;
    CPTFill* areaGradientFill = [CPTFill fillWithGradient: areaGradient];
    CPTBarPlot* barPlot = [self createBarPlotWithFill: areaGradientFill withBorder: YES];
    
    barPlot.identifier = @"turnoversPlot";
    [self setupShadowForPlot: barPlot];
    
    [turnoversGraph addPlot: barPlot];
    
    [self updateTurnoversGraph];
}

-(void)setupSelectionPlot
{
    [selectionGraph removePlotWithIdentifier: @"selectionPlot"];

    // The selection plot always contains the full range of values as it is used to select a subrange
    // for main and turnovers graphs.
    if (mainCategory != nil) {
        CGColorRef gradientHighColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Selection Plot Gradient (high)"] colorWithAlphaComponent: 0.8]);
        CGColorRef gradientLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Selection Plot Gradient (low)"] colorWithAlphaComponent: 0.9]);
        CPTGradient* areaGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                                endingColor: [CPTColor colorWithCGColor: gradientLowColor]
                                     ];
        CGColorRelease(gradientHighColor);
        CGColorRelease(gradientLowColor);

        areaGradient.angle = 90.0;
        CPTFill* gradientFill = [CPTFill fillWithGradient: areaGradient];
        
        CPTPlot* plot = [self createScatterPlotWithFill: gradientFill];
        
        plot.identifier = @"selectionPlot";
        [self setupShadowForPlot: plot];
        
        [selectionGraph addPlot: plot];
    }        
    [self updateSelectionGraph];
}

/**
 * Determines the optimal length of a major interval length for a plot depending on the
 * overall size of the range. This is a bit tricky as we want sharp and easy intervals
 * for optimal perceptibility. The given range is already rounded up to two most significant digits.
 */
- (float)intervalFromRange: (NSDecimalNumber*) range forTurnovers: (BOOL)lesserValues
{
    int digitCount = [range numberOfDigits];

    NSDecimal value = [range decimalValue];
    NSDecimal hundred = [@100 decimalValue];
    if (NSDecimalCompare(&value, &hundred) == NSOrderedDescending) {
        // The range is > 100 so scale it down so it falls into that range.
        NSDecimalMultiplyByPowerOf10(&value, &value, -digitCount + 2, NSRoundDown);
    }
    double convertedValue = [[NSDecimalNumber decimalNumberWithDecimal: value] doubleValue];
    if (digitCount < 2) {
        return convertedValue <= 5 ? 1 : 2;
    }

    double base = lesserValues ? 20 : 10;
    if (convertedValue < 10) {
        return pow(base, digitCount - 1);
    }
    if (convertedValue == 10) {
        return 2 * pow(base, digitCount - 2);
    }
    if (convertedValue <= 15) {
        return 3 * pow(base, digitCount - 2);
    }
    if (convertedValue <= 45) {
        return 5 * pow(base, digitCount - 2);
    }

    return pow(base, digitCount - 1);
}

/**
 * Determines a good number of subticks depending on the size of the interval. The returned value
 * should be so that it is easy to sum up subinterval steps to find a value from the graph easily.
 */
- (float)minorTicksFromInterval: (float)interval
{
    NSDecimal value = CPTDecimalFromFloat(interval);
    int digitCount = [[NSDecimalNumber decimalNumberWithDecimal: value] numberOfDigits];
    NSDecimal hundred = [@100 decimalValue];
    if (NSDecimalCompare(&value, &hundred) == NSOrderedDescending) {
        // The range is > 100 so scale it down so it falls into that range.
        NSDecimalMultiplyByPowerOf10(&value, &value, -digitCount + 2, NSRoundDown);
    }
    double convertedValue = [[NSDecimalNumber decimalNumberWithDecimal: value] doubleValue];
    if (convertedValue < 10) {
        return 0;
    }
    if (convertedValue == 10) {
        return 4;
    }
    if (convertedValue <= 15) {
        return 4;
    }
    if (convertedValue <= 45) {
        return convertedValue / 5 - 1;
    }

    return 4;
}

/**
 * Determines the amount of major ticks, depending on the grouping interval.
 */
- (int)majorTickCount
{
    switch (groupingInterval)
    {
        case GroupByWeeks:
            return 10;
            break;
        case GroupByMonths:
            return 12;
            break;
        case GroupByQuarters:
            return 8;
            break;
        case GroupByYears:
            return 4;
            break;
        default:
            return 11;
            
    }
}

/**
 * Determines the number of units between two dates, depending on the grouping interval.
 */
- (int)distanceFromDate: (ShortDate*)from toDate: (ShortDate*)to
{
    switch (groupingInterval)
    {
        case GroupByWeeks:
            return [from unitsToDate: to byUnit: NSWeekCalendarUnit];
            break;
        case GroupByMonths:
            return [from unitsToDate: to byUnit: NSMonthCalendarUnit];
            break;
        case GroupByQuarters:
            return [from unitsToDate: to byUnit: NSQuarterCalendarUnit];
            break;
        case GroupByYears:
            return [from unitsToDate: to byUnit: NSYearCalendarUnit];
            break;
        default:
            return [from unitsToDate: to byUnit: NSDayCalendarUnit];
            
    }
}

- (NSDecimal)distanceAsDecimalFromDate: (ShortDate*)from toDate: (ShortDate*)to
{
    return CPTDecimalFromInt([self distanceFromDate: from toDate: to]);
}

/**
 * Determines the number of units between two dates, depending on the grouping interval.
 */
- (ShortDate*)dateByAddingUnits: (ShortDate*)from count: (int)units
{
    switch (groupingInterval)
    {
        case GroupByWeeks:
            return [from dateByAddingUnits: units byUnit: NSWeekCalendarUnit];
            break;
        case GroupByMonths:
            return [from dateByAddingUnits: units byUnit: NSMonthCalendarUnit];
            break;
        case GroupByQuarters:
            return [from dateByAddingUnits: units byUnit: NSQuarterCalendarUnit];
            break;
        case GroupByYears:
            return [from dateByAddingUnits: units byUnit: NSYearCalendarUnit];
            break;
        default:
            return [from dateByAddingUnits: units byUnit: NSDayCalendarUnit];
            
    }
}

/**
 * Updates the vertical plotrange of the main graph and must only be called with data loaded.
 */
- (void)updateVerticalMainGraphRange
{
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;

    NSUInteger startIndex = 0;
    NSUInteger endIndex = 0;

    if (rawCount > 0) {
        NSUInteger units = floor(plotSpace.xRange.locationDouble);

        // Scatter plots go over a (horizontal) range, so even if the actual time point is out of view
        // parts of the area representing the value can still be visible so we round down the position value.
        // Bar plots however appear around a time point (+-10%).
        if (![mainCategory isBankAccount] ) {
            double fraction = plotSpace.xRange.locationDouble - (double)units;
            if (fraction > 0.1) {
                units++;
            }
        }
        startIndex = [self findIndexForTimePoint: units];

        units = floor(plotSpace.xRange.endDouble);
        if (![mainCategory isBankAccount]) {
            double fraction = (double)units - plotSpace.xRange.endDouble;
            if (fraction < 0.1) {
                units++;
            }
        }
        endIndex = [self findIndexForTimePoint: units];
    }

    [self computeLocalStatisticsFrom: startIndex to: endIndex];

    if (startIndex >= endIndex) {
        // Don't change the plot range if we are in a time range that doesn't contain values.
        return;
    }

    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    
    float animationDuration = 0.3;
    if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) != 0) {
		animationDuration = 3;
	}

    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;

    // Let the larger area (negative or positive) determine the size of the major tick range.
    NSDecimalNumber* minAbsolute = [roundedLocalMinValue abs];
    NSDecimalNumber* maxAbsolute = [roundedLocalMaxValue abs];
    float interval;
    if ([minAbsolute compare: maxAbsolute] == NSOrderedDescending) {
        interval = [self intervalFromRange: minAbsolute forTurnovers: NO];
    } else {
        interval = [self intervalFromRange: maxAbsolute forTurnovers: NO];
    }
    
    // Apply new interval length and minor ticks now only if they lead to equal or less labels.
    // Otherwise do it after the animation.
    // This is necessary to avoid a potentially large intermittent number of labels during animation.
    NSDecimal newInterval = CPTDecimalFromFloat(interval);
    NSDecimal oldInterval = y.majorIntervalLength;
    if (NSDecimalCompare(&oldInterval, &newInterval) == NSOrderedAscending) {
        y.majorIntervalLength = newInterval;
        y.minorTicksPerInterval = [self minorTicksFromInterval: interval];
        newMainYInterval = -1;
    } else {
        newMainYInterval = interval; // Keep this temporarily in this ivar. It is applied at the end of the animation.
    }

    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: roundedLocalMinValue.decimalValue
                                                           length: [[roundedLocalMaxValue decimalNumberBySubtracting: roundedLocalMinValue] decimalValue]];

    [CPTAnimation animate: plotSpace
                 property: @"yRange"
            fromPlotRange: plotSpace.yRange
              toPlotRange: plotRange
                 duration: animationDuration
                withDelay: 0
           animationCurve: CPTAnimationCurveCubicInOut
                 delegate: self];
}

- (void)updateMainGraph
{
    int tickCount = [self majorTickCount];
    int totalUnits = (rawCount > 1) ? timePoints[rawCount - 2] + 1 : 0;
    if (totalUnits < tickCount) {
        totalUnits = tickCount;
    }
    
    // Set the available plot space depending on the min, max and day values we found.
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
    
    // Horizontal range.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(totalUnits)];
    plotSpace.globalXRange = plotRange;
    
    NSDecimal fromPoint = [self distanceAsDecimalFromDate: referenceDate toDate: fromDate];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation: fromPoint
                                                    length: CPTDecimalSubtract([self distanceAsDecimalFromDate: referenceDate toDate: toDate], fromPoint)];
    
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.preferredNumberOfMajorTicks = tickCount;

    // Recreate the time formatter to apply the new reference date. Just setting the date on the existing
    // formatter is not enough.
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    
    int calendarUnit;
    switch (groupingInterval) {
        case GroupByWeeks:
            calendarUnit = NSWeekCalendarUnit;
            break;
        case GroupByMonths:
            calendarUnit = NSMonthCalendarUnit;
            break;
        case GroupByQuarters:
            calendarUnit = NSQuarterCalendarUnit;
            break;
        case GroupByYears:
            calendarUnit = NSYearCalendarUnit;
            break;
        default:
            calendarUnit = NSDayCalendarUnit;
            break;
    }
    PecuniaPlotTimeFormatter* timeFormatter = [[PecuniaPlotTimeFormatter alloc] initWithDateFormatter: dateFormatter
                                                                                          calendarUnit: calendarUnit];
    
    timeFormatter.referenceDate = [referenceDate lowDate];
    x.labelFormatter = timeFormatter;

    // The currency of the main category can change so update the y axis label formatter as well.
    NSString* currency = (mainCategory == nil) ? @"EUR" : [mainCategory currency];
    NSNumberFormatter* currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.usesSignificantDigits = YES;
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.currencyCode = currency;
    currencyFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", currencyFormatter.currencySymbol];
    axisSet.yAxis.labelFormatter = currencyFormatter;
}

- (void)updateTurnoversGraph
{
    int totalUnits = (rawCount > 1) ? timePoints[rawCount - 2] + 1 : 0;
    if (totalUnits < [self majorTickCount]) {
        totalUnits = [self majorTickCount];
    };
    
    // Set the available plot space depending on the min, max and day values we found.
    CPTXYPlotSpace* plotSpace = (id)turnoversGraph.defaultPlotSpace;
    
    // Horizontal range.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(totalUnits)];
    plotSpace.globalXRange = plotRange;
    
    NSDecimal fromPoint = [self distanceAsDecimalFromDate: referenceDate toDate: fromDate];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation: fromPoint
                                                    length: CPTDecimalSubtract([self distanceAsDecimalFromDate: referenceDate toDate: toDate], fromPoint)];
    
    CPTXYAxisSet* axisSet = (id)turnoversGraph.axisSet;
    
    plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromInt(0) length: [roundedMaxTurnovers decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
    
    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;
    y.visibleRange = plotRange;
    
    float interval = [self intervalFromRange: roundedMaxTurnovers forTurnovers: YES];
    y.majorIntervalLength = CPTDecimalFromFloat(interval);
    y.minorTicksPerInterval = 0;
}

-(void)updateSelectionGraph
{
    int totalUnits;
    if (selectionTimePoints != nil) {
        totalUnits = selectionTimePoints[selectionSampleCount - 1];
    } else {
       totalUnits = (rawCount > 1) ? timePoints[rawCount - 2] + 1 : 0;
    }

    if (totalUnits < [self majorTickCount]) {
        totalUnits = [self majorTickCount];
    };
    
    CPTXYPlotSpace* plotSpace = (id)selectionGraph.defaultPlotSpace;
    
    // Horizontal range.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromInt(0)
                                                           length: CPTDecimalFromInt(totalUnits)];
    plotSpace.globalXRange = plotRange;
    plotSpace.xRange = plotRange;
    
    CPTXYAxisSet* axisSet = (id)selectionGraph.axisSet;

    // Vertical range.
    plotRange = [CPTPlotRange plotRangeWithLocation: roundedTotalMinValue.decimalValue
                                             length: [[roundedTotalMaxValue decimalNumberBySubtracting: roundedTotalMinValue] decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
    
    // Set the y axis lines depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;
    y.visibleRange = plotRange;
}

#pragma mark -
#pragma mark Statistics

int double_compare(const void *value1, const void *value2)
{
    double v1 = *(double*)value1;
    double v2 = *(double*)value2;
    if (v1 < v2) {
        return -1;
    }
    if (v1 > v2) {
        return 1;
    }
    return 0;
}

#define MOVING_AVERAGE_WIDTH 9

- (void)computeTotalStatistics
{
    double min = 1e100;
    double max = -1e100;
    double maxTurnovers = 0;
    double sum = 0;
    double squareSum = 0;
    double median = 0;

    int count = 0;
    if (rawCount > 0) {
        // The total count value includes a dummy value at the end. We don't want this to weight our results.
        count = rawCount;
        if (mainCategory.isBankAccount) {
            count--;
        }

        double *sortedBalances = malloc(count * sizeof(double));
        memcpy(sortedBalances, totalBalances, count * sizeof(double));
        qsort(sortedBalances, count, sizeof(double), double_compare);
        if ((count & 1) != 0) { // Odd/even handling is slightly different.
            median = sortedBalances[count / 2];
        } else {
            median = (sortedBalances[count / 2] + sortedBalances[count / 2 - 1]) / 2.0;
        }
        free(sortedBalances);
        
        for (int i = 0; i < count; i++) {
            if (totalBalances[i] > max) {
                max = totalBalances[i];
            }
            if (totalBalances[i] < min) {
                min = totalBalances[i];
            }
            sum += totalBalances[i];
            squareSum += totalBalances[i] * totalBalances[i];
            if (balanceCounts[i] > maxTurnovers) {
                maxTurnovers = balanceCounts[i];
            }
        }

        statistics[@"totalMinValue"] = @(min);
        statistics[@"totalMaxValue"] = @(max);
        statistics[@"totalMeanValue"] = @(sum / count);
        statistics[@"totalMedian"] = @(median);
        
        if (!mainCategory.isBankAccount) {
            statistics[@"totalSum"] = @(sum);
        } else {
            [statistics removeObjectForKey: @"totalSum"];
        }
    } else {
        [statistics removeObjectForKey: @"totalMinValue"];
        [statistics removeObjectForKey: @"totalMaxValue"];
        [statistics removeObjectForKey: @"totalMeanValue"];
        [statistics removeObjectForKey: @"totalMedian"];
        [statistics removeObjectForKey: @"totalSum"];
    }

    if (count > 1) {
        double deviationFactor = (squareSum - sum * sum / count) / (count - 1);
        if (deviationFactor < 0) {
            deviationFactor = 0; // Can become < 0 because of rounding errors.
        }
        statistics[@"totalStandardDeviation"] = @(sqrt(deviationFactor));
    } else {
        [statistics removeObjectForKey: @"totalStandardDeviation"];
    }

    // Moving average values with linear weighting.
    double weightFactor = 2.0 / MOVING_AVERAGE_WIDTH / (MOVING_AVERAGE_WIDTH + 1);
    for (int t = 0; t < (int)rawCount; t++) {
        double average = 0;
        for (int i = 0; i < MOVING_AVERAGE_WIDTH; i++) {
            int sourceIndex = t - MOVING_AVERAGE_WIDTH + i;
            if (sourceIndex < 0) {
                sourceIndex = 0;
            } else {
                if (sourceIndex >= count) {
                    sourceIndex = count - 1;
                }
            }
            average += (i + 1) * totalBalances[sourceIndex];
        }
        movingAverage[t] = weightFactor * average;
    }

    // Compute some special values for the graphs which directly depend on global stats.
    // Make sure we always show the base line in a graph.
    if (min > 0) {
        min = 0;
    }
    if (max < 0) {
        max = 0;
    }
    if (max - min < 10) {
        max = min + 10; // Ensure a minimum range for the graphs.
    }
    NSDecimal decimalMinValue = CPTDecimalFromDouble(min);
    NSDecimal decimalMaxValue = CPTDecimalFromDouble(max);
    roundedTotalMinValue = [[NSDecimalNumber decimalNumberWithDecimal: decimalMinValue] roundToUpperOuter];
    roundedTotalMaxValue = [[NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue] roundToUpperOuter];

    if (maxTurnovers < 5) {
        maxTurnovers = 5;
    }
    NSDecimal decimalTurnoversValue = CPTDecimalFromDouble(maxTurnovers);
    roundedMaxTurnovers = [[NSDecimalNumber decimalNumberWithDecimal: decimalTurnoversValue] roundToUpperOuter];
}

- (void)computeLocalStatisticsFrom: (NSUInteger)fromIndex to: (NSUInteger)toIndex
{
    double min = 1e100;
    double max = -1e100;
    double sum = 0;
    double squareSum = 0;
    double median = 0;

    NSUInteger count = toIndex - fromIndex + 1;
    if (toIndex > fromIndex) {
        double *sortedBalances = malloc(count * sizeof(double));
        memcpy(sortedBalances, &totalBalances[fromIndex], count * sizeof(double));
        qsort(sortedBalances, count, sizeof(double), double_compare);
        if ((count & 1) != 0) { // Odd/even handling is slightly different.
            median = sortedBalances[count / 2];
        } else {
            median = (sortedBalances[count / 2] + sortedBalances[count / 2 - 1]) / 2.0;
        }
        free(sortedBalances);

        for (NSUInteger i = fromIndex; i <= toIndex; i++) {
            if (totalBalances[i] > max) {
                max = totalBalances[i];
            }
            if (totalBalances[i] < min) {
                min = totalBalances[i];
            }
            sum += totalBalances[i];
            squareSum += totalBalances[i] * totalBalances[i];
        }

        statistics[@"localMinValue"] = @(min);
        statistics[@"localMaxValue"] = @(max);
        statistics[@"localMeanValue"] = @(sum / count);
        statistics[@"localMedian"] = @(median);

        if (!mainCategory.isBankAccount) {
            statistics[@"localSum"] = @(sum);
        } else {
            [statistics removeObjectForKey: @"localSum"];
        }
    } else {
        [statistics removeObjectForKey: @"localMinValue"];
        [statistics removeObjectForKey: @"localMaxValue"];
        [statistics removeObjectForKey: @"localMeanValue"];
        [statistics removeObjectForKey: @"localMedian"];
        [statistics removeObjectForKey: @"localSum"];
    }

    if (count > 1) {
        double deviationFactor = (squareSum - sum * sum / count) / (count - 1);
        if (deviationFactor < 0) {
            deviationFactor = 0; // Can become < 0 because of rounding errors.
        }
        statistics[@"localStandardDeviation"] = @(sqrt(deviationFactor));
    } else {
        [statistics removeObjectForKey: @"localStandardDeviation"];
    }

    if (min > 0) {
        min = 0;
    }
    if (max < 0) {
        max = 0;
    }
    if (max - min < 10) {
        max = min + 10; // Ensure a minimum range for the graphs.
    }
    NSDecimal decimalMinValue = CPTDecimalFromDouble(min);
    NSDecimal decimalMaxValue = CPTDecimalFromDouble(max);
    roundedLocalMinValue = [[NSDecimalNumber decimalNumberWithDecimal: decimalMinValue] roundToUpperOuter];
    roundedLocalMaxValue = [[NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue] roundToUpperOuter];
}

#pragma mark -
#pragma mark Event handling

/**
 * Allows to trigger tracking area updates of the graph views from outside of the controller.
 */
- (void)updateTrackingAreas
{
    [mainHostView updateTrackingAreas];
    [turnoversHostView updateTrackingAreas];
    [selectionHostView updateTrackingAreas];

}

#pragma mark -
#pragma mark User interaction

- (void)applyRangeLocationToPlotSpace: (CPTXYPlotSpace*)space location: (NSNumber*)location range: (NSNumber*)range
{
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble([location doubleValue])
                                                           length: CPTDecimalFromDouble([range doubleValue])];
    space.xRange = plotRange;
}

/**
 * Updates the info annotation with the current main info values.
 */
- (void)updateMainInfo
{
    ShortDate *date = mainInfoValues[@"date"];
    id balance = mainInfoValues[@"balance"];
    int turnovers = [mainInfoValues[@"turnovers"] intValue];
    
    
    if (infoTextFormatter == nil)
    {
        NSString* currency = (mainCategory == nil) ? @"EUR" : [mainCategory currency];
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

        infoLayer.paddingTop = 10;
        infoLayer.paddingBottom = 10;
        infoLayer.paddingLeft = 15;
        infoLayer.paddingRight = 15;
        infoLayer.spacing = 5;

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
        textStyle.fontName = @"LucidaGrande";
        textStyle.fontSize = 12;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentCenter;
        
        dateInfoLayer = [[CPTTextLayer alloc] initWithText: @"" style: textStyle];
        [infoLayer addSublayer: dateInfoLayer];
        
        textStyle = [CPTMutableTextStyle textStyle];
        textStyle.fontName = @"LucidaGrande-Bold";
        textStyle.fontSize = 16;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentCenter;
        
        valueInfoLayer = [[CPTTextLayer alloc] initWithText: @"" style: textStyle];
        [infoLayer addSublayer: valueInfoLayer];

        // We can also prepare the annotation which hosts the info layer but don't add it to the plot area yet.
        // When we switch the plots it won't show up otherwise unless we add it on demand.
        infoAnnotation = [[CPTAnnotation alloc] init];
        infoAnnotation.contentLayer = infoLayer;
    }
    if (![mainGraph.plotAreaFrame.plotArea.annotations containsObject: infoAnnotation])
        [mainGraph.plotAreaFrame.plotArea addAnnotation: infoAnnotation]; 

    if ([balance isKindOfClass: [NSNumber class]]) {
        valueInfoLayer.text = [infoTextFormatter stringFromNumber: (NSNumber*)balance];
    } else {
        valueInfoLayer.text = @"--";
    }
    
    NSString* infoText;
    NSString* dateDescription;

    switch (groupingInterval) {
        case GroupByWeeks:
            dateDescription = [date weekYearDescription];
            break;
        case GroupByMonths:
            dateDescription = [date monthYearDescription];
            break;
        case GroupByQuarters:
            dateDescription = [date quarterYearDescription];
            break;
        case GroupByYears:
            dateDescription = [date yearDescription];
            break;
        default:
            dateDescription = date.description;
            break;
    }
    
    if (turnovers == 1) {
        infoText = [NSString stringWithFormat: @"%@\n%@", dateDescription, NSLocalizedString(@"AP132", @"")];
    } else {
        infoText = [NSString stringWithFormat: @"%@\n%@", dateDescription, [NSString stringWithFormat: NSLocalizedString(@"AP133", @""), turnovers]];
    }
    dateInfoLayer.text = infoText;
    [infoLayer sizeToFit];
}

- (void)updateInfoLayerPosition
{
    // Place the info layer so in the graph that it doesn't get "in the way" but is still close enough
    // to the focus center (which is usually the mouse pointer). This is done by dividing
    // the graph into 4 rectangles (top-left, top-right, bottom-left, bottom-rigth). Use the same horizontal
    // quadrant in which is also the mouse but the opposite vertical one.
    CGRect frame = mainGraph.plotAreaFrame.plotArea.frame;
    CGFloat horizontalCenter = frame.size.width / 2;
    CGFloat verticalCenter = frame.size.height / 2;
    
    NSPoint mousePosition = [mainHostView.window convertScreenToBase: [NSEvent mouseLocation]];
    mousePosition = [mainHostView convertPoint: mousePosition fromView: nil];
    
    CPTPlot* plot = [mainGraph plotAtIndex: 0];
    CGPoint mouseLocation = NSPointToCGPoint(mousePosition);
    CGPoint pointInHostedGraph = [mainHostView.layer convertPoint: mouseLocation toLayer: [plot plotArea]];
    
    CGPoint infoLayerLocation;
    if (pointInHostedGraph.x > horizontalCenter) {
        // Position in right half.
        infoLayerLocation.x = frame.origin.x + horizontalCenter + (horizontalCenter - infoLayer.bounds.size.width) / 2;
    } else {
        // Position in left half.
        infoLayerLocation.x = frame.origin.x + (horizontalCenter - infoLayer.bounds.size.width) / 2;
    }
    if (pointInHostedGraph.y < verticalCenter) {
        // Position in top half.
        infoLayerLocation.y = frame.origin.y + verticalCenter + (verticalCenter - infoLayer.bounds.size.height) / 2;
    } else {
        // Position in bottom half.
        infoLayerLocation.y = frame.origin.y + (verticalCenter - infoLayer.bounds.size.height) / 2;
    }
    
    if (infoLayer.position.x != infoLayerLocation.x || infoLayer.position.y != infoLayerLocation.y)
        [infoLayer slideTo: infoLayerLocation inTime: 0.15];
}

/**
 * Searches the time point array for the closest value to the given point.
 * The search is left-affine, that is, if the time point to search is between two existing points the 
 * lower point will always be returned.
 */
- (NSUInteger)findIndexForTimePoint: (NSUInteger)timePoint
{
    if (rawCount == 0)
        return -1;
    
    int low = 0;
    int high = rawCount - 1;
    while (low <= high)
    {
        int mid = (low + high) / 2;
        double midPoint = timePoints[mid];
        if (midPoint == timePoint) {
            return mid;
        }
        if (midPoint < timePoint) {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    };

    return low - 1;
}

/**
 * Called when the users moved the mouse over either the main or the turnovers graph.
 * Move the indicator lines in both graphs to the current mouse position and update the info annotation.
 *
 * The location is given in plot area coordinates.
 */
- (void)updateTrackLinesAndInfoAnnotation: (NSNumber*)location
{
    BOOL snap = YES;
    CGFloat actualLocation = [location floatValue];
    
    // Determine the content for the info layer.
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
    CGPoint point = CGPointMake(actualLocation, 0);
    
    NSDecimal dataPoint[2];
    [plotSpace plotPoint: dataPoint forPlotAreaViewPoint: point];
    double timePoint = CPTDecimalDoubleValue(dataPoint[0]);
    
    // Check if the time point is within the visible range.
    if (rawCount == 0 || timePoint < plotSpace.xRange.minLimitDouble ||
        timePoint > plotSpace.xRange.maxLimitDouble) {
        [self hideInfoComponents];
        return;
    } else {
        [self showInfoComponents];
    }

    // Find closest point in our time points that is before the computed time value.
    int units = round(timePoint);
    NSUInteger index = [self findIndexForTimePoint: units];
    double timePointAtIndex = timePoints[index];
    BOOL dateHit = NO;
    
    // The found index might not be one matching exactly the current date. In order to ease
    // usage we snap the indicator to the closest existing data point if it is within bar width distance.
    if (snap) {
        NSDecimal snapPoint[2] = {0, 0};
        snapPoint[0] = CPTDecimalFromDouble(timePointAtIndex);
        CGPoint targetPoint = [plotSpace plotAreaViewPointForPlotPoint: snapPoint];
        if (abs(targetPoint.x - actualLocation) <= barWidth / 2) {
            actualLocation = targetPoint.x;
            timePoint = timePointAtIndex;
            dateHit = YES;
        } else {
            // The found index is not close enough. Try the next date point if there is one.
            if (index < rawCount - 1) {
                timePointAtIndex = timePoints[index + 1];
                snapPoint[0] = CPTDecimalFromDouble(timePointAtIndex);
                targetPoint = [plotSpace plotAreaViewPointForPlotPoint: snapPoint];
                if (abs(targetPoint.x - actualLocation) <= barWidth) {
                    actualLocation = targetPoint.x;
                    timePoint = timePointAtIndex;
                    dateHit = YES;
                    index++;
                }
            }
        }
    }

    // If there wasn't a date hit (i.e. the current position is at an actual value) then
    // use the date left to the position (not rounded), so we show the unit properly til
    // the next unit tick.
    if (!dateHit) {
        index = [self findIndexForTimePoint: floor(CPTDecimalFloatValue(dataPoint[0]))];
    }

    if (lastInfoTimePoint == 0 || (timePoint != lastInfoTimePoint) || dateHit)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(updateMainInfo) object: nil];
        lastInfoTimePoint = timePoint;

        mainInfoValues[@"date"] = [self dateByAddingUnits: referenceDate count: timePoint];
        id balance;
        int turnovers = 0;
        if (dateHit) {
            balance = @(totalBalances[index]);
            turnovers = balanceCounts[index];
        } else {
            balance = [mainCategory isBankAccount] ? @(totalBalances[index]) : (id)[NSNull null];
        }
        mainInfoValues[@"balance"] = balance;
        mainInfoValues[@"turnovers"] = @(turnovers);

        // Update the info layer content, but after a short delay. This will be canceled if new
        // update request arrive in the meantime (circumventing so too many updates that slow down the display).
        [self performSelector: @selector(updateMainInfo) withObject: nil afterDelay: 0.1];
    }

    // Position the indicator line to the given location in main and turnovers graphs.
    mainIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: actualLocation];
    turnoversIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: actualLocation];
    
    [self updateInfoLayerPosition];
}

/**
 * Updates the limit band size and position depending on the currently selected time frame.
 */
- (void)updateSelectionDisplay
{
    CPTXYAxisSet* axisSet = (id)selectionGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    
    [x removeBackgroundLimitBand: selectionBand];
    if (rawCount > 0) {
        CGColorRef bandColor = CGColorCreateFromNSColor([NSColor applicationColorForKey: @"Selection Band"]);
        CPTFill* bandFill = [CPTFill fillWithColor: [CPTColor colorWithCGColor: bandColor]];
        CGColorRelease(bandColor);

        // The select band is an exact equivalent of the main range.
        CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
        selectionBand = [CPTLimitBand limitBandWithRange: plotSpace.xRange
                                                    fill: bandFill];
        [x addBackgroundLimitBand: selectionBand];
        selectionHostView.selector = selectionBand;
    }
}

- (void)updateTimeRangeVariables
{
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
    
    NSDecimal fromPoint = plotSpace.xRange.location;
    fromDate = [self dateByAddingUnits: referenceDate count: CPTDecimalIntValue(fromPoint)];
    
    NSDecimal toPoint = plotSpace.xRange.end;
    toDate = [self dateByAddingUnits: referenceDate count: CPTDecimalIntValue(toPoint)];
}

/**
 * Handler method for notifications sent from the graph host windows if something in the graphs need
 * adjustment, mostly due to user input.
 */
- (void)graphLayoutChanged: (NSNotification*)notification
{
    if ([[notification name] isEqualToString: PecuniaGraphLayoutChangeNotification] && !doingGraphUpdates)
    {
        doingGraphUpdates = YES;
        
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(updateVerticalMainGraphRange) object: nil];
        
        NSDictionary* parameters = [notification userInfo];
        NSString* type = parameters[@"type"];
        
        CPTXYPlotSpace* sourcePlotSpace = notification.object;
        BOOL fromSelectionGraph = (sourcePlotSpace == selectionGraph.defaultPlotSpace);
        BOOL isDragMove = [type isEqualToString: @"plotMoveDrag"];
        BOOL isScale = [type isEqualToString: @"plotScale"];
        if ([type isEqualToString: @"plotMoveSwipe"] || isDragMove || isScale) {
            if (!infoLayer.hidden) {
                [self hideInfoComponents];
            }

            NSNumber* location = parameters[@"plotXLocation"];
            NSNumber* range = parameters[@"plotXRange"];
            NSNumber* lowRange = @([self majorTickCount]);
            if ([range compare: lowRange] == NSOrderedAscending)
                range = lowRange;
            
            NSNumber* center = parameters[@"mousePosition"];

            // Apply new plot location and range to all relevant graphs.
            // If this is a scale event then adjust the location so that the center is at the mouse
            // location.
            if (isScale) {
                // If this event is from the selection graph then we don't use the actual mouse
                // position, but the center of the selection band.
                double timePoint;
                if (fromSelectionGraph) {
                    timePoint = selectionBand.range.locationDouble + selectionBand.range.lengthDouble / 2;
                } else {
                    // Convert scale center (given in device coordinates).
                    CGPoint point = CGPointMake([center floatValue], 0);
                    
                    NSDecimal dataPoint[2];
                    [sourcePlotSpace plotPoint: dataPoint forPlotAreaViewPoint: point];
                    timePoint = CPTDecimalDoubleValue(dataPoint[0]);
                }
                
                CGFloat oldRange = fromSelectionGraph ? selectionBand.range.lengthDouble : sourcePlotSpace.xRange.lengthDouble;
                CGFloat newRange = [range floatValue];
                CGFloat offset = (oldRange - newRange) * (timePoint - [location floatValue]) / oldRange;
                location = @([location  floatValue] + offset);
            }
            
            [self applyRangeLocationToPlotSpace: (id)mainGraph.defaultPlotSpace location: location range: range];
            [self applyRangeLocationToPlotSpace: (id)turnoversGraph.defaultPlotSpace location: location range: range];

            // Adjust the time range display in the selection graph.
            [self updateTimeRangeVariables];
            [self updateSelectionDisplay];

            // Adjust vertical graph ranges after a short delay.
            [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.3];
        } else {
            if ([type isEqualToString: @"mouseMove"]) {
                NSNumber* location = parameters[@"location"];
                [self updateTrackLinesAndInfoAnnotation: location];
            } else {
                if ([type isEqualToString: @"plotMoveCenter"]) {
                    NSNumber* location = parameters[@"location"];
                    NSNumber* range = parameters[@"plotXRange"];

                    CGPoint point = CGPointMake([location floatValue], 0);
                    
                    NSDecimal dataPoint[2];
                    [sourcePlotSpace plotPoint: dataPoint forPlotAreaViewPoint: point];
                    double timePoint = CPTDecimalDoubleValue(dataPoint[0]);
                    location = @(timePoint - [range doubleValue] / 2);

                    [self applyRangeLocationToPlotSpace: (id)mainGraph.defaultPlotSpace location: location range: range];
                    [self applyRangeLocationToPlotSpace: (id)turnoversGraph.defaultPlotSpace location: location range: range];
                    
                    // Adjust the time range display in the selection graph.
                    [self updateTimeRangeVariables];
                    [self updateSelectionDisplay];
                    
                    [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.3];
                }
            }

        }
        doingGraphUpdates = NO;
    }
}

/**
 * Handler method for notifications sent from the graph host windows if the mouse pointer
 * exited from the window's tracking area.
 */
- (void)mouseLeftGraph: (NSNotification*)notification
{
    [self hideInfoComponents];
}

#pragma mark -
#pragma mark Coreplot delegate methods

- (void)animationDidFinish: (CPTAnimationOperation *)operation
{
    if (operation.boundObject == mainGraph.defaultPlotSpace) {
        // Animation of the main graph vertical plot space.
        // We can now set the final interval length and tick count.
        if (newMainYInterval > 0) {
            CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
            CPTXYAxis* y = axisSet.yAxis;

            y.majorIntervalLength = CPTDecimalFromFloat(newMainYInterval);
            y.minorTicksPerInterval = [self minorTicksFromInterval: newMainYInterval];
            newMainYInterval = 0;
        }
    }
}

- (void)animationCancelled: (CPTAnimationOperation *)operation
{
    if (operation.boundObject == mainGraph.defaultPlotSpace) {
        // Animation of the main graph vertical plot space.
        // We can now set the final interval length and tick count.
        if (newMainYInterval > 0) {
            CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
            CPTXYAxis* y = axisSet.yAxis;

            y.majorIntervalLength = CPTDecimalFromFloat(newMainYInterval);
            y.minorTicksPerInterval = [self minorTicksFromInterval: newMainYInterval];
            newMainYInterval = 0;
        }
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot*)plot
{
    if ([plot graph] == selectionGraph && selectionBalances != nil) {
        return selectionSampleCount;
    }

    NSString* identifier = (id)plot.identifier;
    if ([identifier isEqualToString: @"averagePlot"] && rawCount > 0) {
        return rawCount;
    }
    return rawCount;
}

- (double *)doublesForPlot: (CPTPlot*)plot field: (NSUInteger)fieldEnum recordIndexRange: (NSRange)indexRange
{
    if (fieldEnum == CPTBarPlotFieldBarLocation || fieldEnum == CPTScatterPlotFieldX) {
        if ([plot graph] == selectionGraph && selectionTimePoints != nil) {
            return selectionTimePoints;
        }
        return &timePoints[indexRange.location];
    }
    
    if ([plot graph] == turnoversGraph) {
        if (fieldEnum == CPTBarPlotFieldBarTip)
            return &balanceCounts[indexRange.location];
        
        return nil;
    }
    
    if ([plot graph] == mainGraph) {
        NSString* identifier = (id)plot.identifier;
        if ([identifier isEqualToString: @"positivePlot"]) {
            return &positiveBalances[indexRange.location];
        } else {
            if ([identifier isEqualToString: @"negativePlot"]) {
                return &negativeBalances[indexRange.location];
            } else {
                return &movingAverage[indexRange.location];
            }
        }
    }
    
    if ([plot graph] == selectionGraph) {
        if (selectionBalances != nil) {
            return &selectionBalances[indexRange.location];
        }
        return &totalBalances[indexRange.location];
    }
    
    return nil;
}

- (CPTLayer *)dataLabelForPlot: (CPTPlot*)plot recordIndex: (NSUInteger)index 
{
    return (id)[NSNull null]; // Don't show any data label.
}

#pragma mark -
#pragma mark General graph routines

- (void)sanitizeDates
{
    // Update the selected range so that its length corresponds to the minimum length
    // and it doesn't start before the first date in the date array. It might go beyond the
    // available data, which is handled elsewhere.

    // First check the selection length.
    int units = [self distanceFromDate: fromDate toDate: toDate];
    if (units < [self majorTickCount]) {
        toDate = [self dateByAddingUnits: fromDate count: [self majorTickCount]];
    }

    // Now see if the new toDate goes beyond the available data. Try fixing it (if so)
    // by moving the selected range closer to the beginning.
    ShortDate* date = [self dateByAddingUnits: referenceDate count: (rawCount > 0) ? timePoints[rawCount - 1] : 0];
    if (toDate == nil || [date compare: toDate] == NSOrderedAscending) {
        units = [self distanceFromDate: toDate toDate: date];
        toDate = date;
        
        date = [self dateByAddingUnits: fromDate count: units];
        fromDate = date;
    }

    // Finally ensure we do not begin before our first data entry. Move the selection range
    // accordingly, accepting that this might move the end point beyond the last data entry.
    date = referenceDate;
    if (fromDate == nil || [date compare: fromDate] == NSOrderedDescending) {
        units = [self distanceFromDate: fromDate toDate: date];
        fromDate = date;

        date = [self dateByAddingUnits: toDate count: units];
        toDate = date;
    }
}

- (void)reloadData
{
    [self hideHelp];
    
    rawCount = 0;
    free(timePoints);
    timePoints = nil;
    
    free(totalBalances);
    totalBalances = nil;
    
    free(negativeBalances);
    negativeBalances = nil;
    
    free(positiveBalances);
    positiveBalances = nil;
    
    free(balanceCounts);
    balanceCounts = nil;

    if (selectionBalances != nil) {
        free(selectionBalances);
        selectionBalances = nil;

        free(selectionTimePoints);
        selectionTimePoints = nil;
    }

    free(movingAverage);
    movingAverage = nil;

    NSArray* plots = [mainGraph.allPlots copy];
    for (CPTPlot* plot in plots) {
        [mainGraph removePlot: plot];
    }
    plots = [turnoversGraph.allPlots copy];
    for (CPTPlot* plot in plots) {
        [turnoversGraph removePlot: plot];
    }
    plots = [selectionGraph.allPlots copy];
    for (CPTPlot* plot in plots) {
        [selectionGraph removePlot: plot];
    }

    referenceDate = [ShortDate currentDate];
    
    if (mainCategory != nil) {
        NSArray *dates = nil;
        NSArray *balances = nil;
        NSArray *turnovers = nil;
        BOOL extraEntry = NO;
        if (mainCategory.isBankAccount) {
            [mainCategory balanceHistoryToDates: &dates
                                       balances: &balances
                                  balanceCounts: &turnovers
                                   withGrouping: groupingInterval];
            extraEntry = YES;
        } else {
            [mainCategory categoryHistoryToDates: &dates
                                        balances: &balances
                                   balanceCounts: &turnovers
                                    withGrouping: groupingInterval];
        }

        if (dates != nil)
        {
            // Convert the data to the internal representations.
            // We add one to the total number as we need it (mostly) in scatter plots to
            // make it appear, due to the way coreplot works. Otherwise it is just cut off by the plot area.
            rawCount = [dates count] + (extraEntry ? 1 : 0);

            // Convert the dates to distance units from a reference date.
            timePoints = malloc(rawCount * sizeof(double));
            referenceDate = dates[0];
            int index = 0;
            for (ShortDate *date in dates) {
                timePoints[index++] = [self distanceFromDate: referenceDate toDate: date];
            }
            if (extraEntry) {
                timePoints[index] = timePoints[index - 1] + 5;
            }

            // Convert all NSDecimalNumbers to double for better performance.
            totalBalances = malloc(rawCount * sizeof(double));
            positiveBalances = malloc(rawCount * sizeof(double));
            negativeBalances = malloc(rawCount * sizeof(double));
            movingAverage = malloc(rawCount * sizeof(double));

            index = 0;
            for (NSDecimalNumber *value in balances) {
                double doubleValue = [value doubleValue];
                totalBalances[index] = doubleValue;
                if (doubleValue < 0) {
                    positiveBalances[index] = 0;
                    negativeBalances[index] = doubleValue;
                } else {
                    positiveBalances[index] = doubleValue;
                    negativeBalances[index] = 0;
                }
                index++;
            }

            // Now the turnovers.
            balanceCounts = malloc(rawCount * sizeof(double));
            index = 0;
            for (NSDecimalNumber *value in turnovers) {
                balanceCounts[index++] = [value doubleValue];
            }

            // The value in the extra field is never used, but serves only as additional data point.
            if (extraEntry) {
                totalBalances[index] = 0;
                positiveBalances[index] = 0;
                negativeBalances[index] = 0;
                balanceCounts[index] = 0;
            }

            // Sample data for the selection plot. Use only as many values as needed to fill the window.
            CPTPlotAreaFrame *frame = selectionGraph.plotAreaFrame;
            selectionSampleCount = frame.bounds.size.width - frame.paddingLeft - frame.paddingRight;
            int datapointsPerSample = rawCount / selectionSampleCount; // Count only discrete values.

            // Don't sample the data if there aren't at least twice as many values as needed to show.
            if (datapointsPerSample > 1) {
                // The computed sample count leaves us with some missing values (discrete math).
                // The systematic error is rawCount - trunc(rawCount / windowSize) * windowSize and the
                // maximum systematic error being almost windowSize.
                // To minimize this error we compute the maximum number of samples that fit into the
                // full range leaving us with a systematic error of
                //   rawCount - (rawCount / trunc(rawCount / windowSize)) * windowSize
                // which is at most the sample size.
                selectionSampleCount = rawCount / datapointsPerSample;

                selectionBalances = malloc(selectionSampleCount * sizeof(double));
                selectionTimePoints = malloc(selectionSampleCount * sizeof(double));

                // Pick the largest value in the sample window as sampled representation.
                for (NSUInteger i = 0; i < rawCount; i++) {
                    NSUInteger sampleIndex = i / datapointsPerSample;
                    if (i % datapointsPerSample == 0) {
                        selectionBalances[sampleIndex] = totalBalances[i];
                        selectionTimePoints[sampleIndex] = timePoints[i];
                    } else {
                        if (totalBalances[i] > selectionBalances[sampleIndex]) {
                            selectionBalances[sampleIndex] = totalBalances[i];
                            selectionTimePoints[sampleIndex] = timePoints[i];
                        }
                    }
                }
            }
        }
    }
    
    [self sanitizeDates];
    [self computeTotalStatistics];

    [mainGraph reloadData];
    [turnoversGraph reloadData];
    [selectionGraph reloadData];
}

- (void)regenerateGraphs
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(updateVerticalMainGraphRange) object: nil];
        
    [self reloadData];
    
    mainGraph.defaultPlotSpace.allowsUserInteraction = rawCount > 0;
    turnoversGraph.defaultPlotSpace.allowsUserInteraction = rawCount > 0;
    selectionGraph.defaultPlotSpace.allowsUserInteraction = rawCount > 0;

    [self setupMainPlots];
    [self setupTurnoversPlot];
    [self setupSelectionPlot];
    [self updateSelectionDisplay];
    
    [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.3];
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
        [NSTimer scheduledTimerWithTimeInterval: .5
                                         target: self 
                                       selector: @selector(releaseHelpWindow)
                                       userInfo: nil
                                        repeats: NO];
    }
}

- (void)showInfoComponents
{
    [infoLayer fadeIn];
    [mainIndicatorLine fadeIn];
    [turnoversIndicatorLine fadeIn];
}

- (void)hideInfoComponents
{
    [infoLayer fadeOut];
    [mainIndicatorLine fadeOut];
    [turnoversIndicatorLine fadeOut];
}

#pragma mark -
#pragma mark Interface Builder Actions

- (IBAction)setGrouping: (id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];

    groupingInterval = [sender intValue];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* values = [userDefaults dictionaryForKey: @"categoryAnalysis"];
    NSMutableDictionary *mutableValues;
    if (values == nil) {
        mutableValues = [NSMutableDictionary dictionaryWithCapacity: 1];
    } else {
        mutableValues = [values mutableCopy];
    }
    [mutableValues setValue: @((int)groupingInterval) forKey: @"grouping"];
    [userDefaults setObject: mutableValues forKey: @"categoryAnalysis"];

    [self regenerateGraphs];
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

-(NSView*)mainView
{
    return topView;
}

- (void)prepare
{
}

- (void)activate;
{
}

- (void)deactivate
{
    [self hideHelp];
}

/**
 * Sets a new time interval for display. The given interval is checked against our minimum intervals
 * (depending on the current grouping mode) and adjusted to match them.
 */
- (void)setTimeRangeFrom: (ShortDate*)from to: (ShortDate*)to
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(updateVerticalMainGraphRange) object: nil];
        
    fromDate = from;
    toDate = to;

    [self sanitizeDates];

    // Reset the temporary values.
    NSDecimal one = CPTDecimalFromDouble(1);
    if (roundedTotalMinValue == nil) {
        roundedTotalMinValue = [NSDecimalNumber decimalNumberWithDecimal: one];
    }
    if (roundedTotalMaxValue == nil) {
        roundedTotalMaxValue = [NSDecimalNumber decimalNumberWithDecimal: one];
    }
    if (roundedLocalMinValue == nil) {
        roundedLocalMinValue = [NSDecimalNumber decimalNumberWithDecimal: one];
    }
    if (roundedLocalMaxValue == nil) {
        roundedLocalMaxValue = [NSDecimalNumber decimalNumberWithDecimal: one];
    }
    if (roundedMaxTurnovers == nil) {
        roundedMaxTurnovers = [NSDecimalNumber decimalNumberWithDecimal: one];
    }

    [self updateMainGraph];
    [self updateTurnoversGraph];
    [self updateSelectionGraph];
    [self updateSelectionDisplay];
    
    [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.3];
}

- (void)setCategory: (Category *)newCategory
{
    if (mainCategory != newCategory) {
        mainCategory = newCategory;
        [self regenerateGraphs];
    }
}

@end

