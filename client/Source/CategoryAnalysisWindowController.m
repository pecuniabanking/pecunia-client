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

#include <math.h>

#import "CategoryAnalysisWindowController.h"
#import "ShortDate.h"
#import "BankAccount.h"

#import "PecuniaPlotTimeFormatter.h"
#import "MCEMDecimalNumberAdditions.h"
#import "GraphicsAdditions.h"
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
        [trackingArea release];
    }

    trackingArea = [[[NSTrackingArea alloc] initWithRect: NSRectFromCGRect(self.hostedGraph.plotAreaFrame.frame)
                                                 options: NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp
                                                   owner: self
                                                userInfo: nil]
                    retain];
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
    [trackingArea release];
    [super dealloc];
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
    if (distance != 0)
    {
        // A trackpad gesture (usually two-finger swipe).
        [parameters setObject: @"plotMoveSwipe" forKey: @"type"];

        NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / 100];
        [parameters setObject: location forKey: @"plotXLocation"];
        
        NSNumber* range = [NSNumber numberWithDouble: CPTDecimalDoubleValue(plotSpace.xRange.length)];
        [parameters setObject: range forKey: @"plotXRange"];
    }
    else 
    {
        [parameters setObject: @"plotScale" forKey: @"type"];
        
        distance = [theEvent deltaY];
        
        // Range location and size.
        NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble];
        [parameters setObject: location forKey: @"plotXLocation"];

        NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble * (1 + distance / 100)];
        [parameters setObject: range forKey: @"plotXRange"];
    }
    
    // Current mouse position.
    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"mousePosition"];
    
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
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
   [parameters setObject: @"plotScale" forKey: @"type"];

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    CGFloat relativeScale = [theEvent magnification];
    
    NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble];
    [parameters setObject: location forKey: @"plotXLocation"];

    NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble * (1 - relativeScale)];
    [parameters setObject: range forKey: @"plotXRange"];

    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"mousePosition"];
    
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
    [parameters setObject: @"trackLineMove" forKey: @"type"];
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"location"];
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
    
    [parameters setObject: @"plotMoveDrag" forKey: @"type"];
    
    CGFloat distance = [theEvent deltaX];
    
    NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / 1000];
    [parameters setObject: location forKey: @"plotXLocation"];
    
    NSNumber* range = [NSNumber numberWithDouble: CPTDecimalDoubleValue(plotSpace.xRange.length)];
    [parameters setObject: range forKey: @"plotXRange"];
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
        [parameters setObject: @"plotMoveSwipe" forKey: @"type"];

        CGFloat distance = [theEvent deltaX];

        NSNumber* location = [NSNumber numberWithDouble: selector.range.locationDouble + plotSpace.xRange.lengthDouble * distance / 100];
        [parameters setObject: location forKey: @"plotXLocation"];
        
        NSNumber* range = [NSNumber numberWithDouble: CPTDecimalDoubleValue(selector.range.length)];
        [parameters setObject: range forKey: @"plotXRange"];
    }
    else 
    {
        [parameters setObject: @"plotScale" forKey: @"type"];
        
        CGFloat distance = [theEvent deltaY];
        
        // Range location and size.
        NSNumber* location = [NSNumber numberWithDouble: selector.range.locationDouble];
        [parameters setObject: location forKey: @"plotXLocation"];

        NSNumber* range = [NSNumber numberWithDouble: selector.range.lengthDouble * (1 + distance / 100)];
        [parameters setObject: range forKey: @"plotXRange"];
    }
    
    // Current mouse position.
    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"mousePosition"];
    
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
    
   [parameters setObject: @"plotScale" forKey: @"type"];

    CGFloat relativeScale = [theEvent magnification];
    
    NSNumber* location = [NSNumber numberWithDouble: selector.range.locationDouble];
    [parameters setObject: location forKey: @"plotXLocation"];

    NSNumber* range = [NSNumber numberWithDouble: selector.range.lengthDouble * (1 - relativeScale)];
    [parameters setObject: range forKey: @"plotXRange"];

    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"mousePosition"];
    
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
    
    [parameters setObject: @"plotMoveCenter" forKey: @"type"];
    
    NSNumber* range = [NSNumber numberWithDouble: selector.range.lengthDouble];
    [parameters setObject: range forKey: @"plotXRange"];

    // Current mouse position as new center.
    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"location"];
    
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

- (void)updateValues;
- (void)clearGraphs;

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

- (void)updateGraphs;

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

    [fromDate release];
    [toDate release];
    [referenceDate release];
    
    [totalMaxValue release];
    [totalMinValue release];

    [mainGraph release];
    
    [mainIndicatorLine release];
    [turnoversIndicatorLine release];
    
    [infoLayer release];
    [dateInfoLayer release];
    [valueInfoLayer release];
    [infoTextFormatter release];
    [infoAnnotation release];
    [selectionBand release];
    
    [super dealloc];
}

-(void)awakeFromNib
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* values = [userDefaults objectForKey: @"categoryAnalysis"];
    if (values != nil) {
        groupingInterval = [[values objectForKey: @"grouping"] intValue];
        groupingSlider.intValue = groupingInterval;
    }
    
    [self setupMainGraph];
    [self setupTurnoversGraph];
    [self setupSelectionGraph];
    [self updateGraphs];
    
    // Help text.
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* path = [mainBundle pathForResource: @"category-analysis-help" ofType: @"rtf"];
    NSAttributedString* text = [[NSAttributedString alloc] initWithPath: path documentAttributes: NULL];
    [helpText setAttributedStringValue: text];
    float height = [text heightForWidth: helpText.bounds.size.width];
    helpContentView.frame = NSMakeRect(0, 0, helpText.bounds.size.width, height);
    [text release];

    selectionBox.hasGradient = YES;
    selectionBox.fillStartingColor = [NSColor applicationColorForKey: @"Small Background Gradient (low)"];
    selectionBox.fillEndingColor = [NSColor applicationColorForKey: @"Small Background Gradient (high)"];
    selectionBox.cornerRadius = 5;
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.5];
    shadow.shadowOffset = NSMakeSize(1, -1);
    shadow.shadowBlurRadius = 3;
    selectionBox.shadow = shadow;
    [shadow release];

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
    plot.shadowOpacity = 0.75;
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
    mainGraph.zPosition = 100;
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

    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 2.0;
    frame.shadowOffset = CGSizeMake(1, -1);
    frame.shadowOpacity = 0.25;
  
    CPTFill* fill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 1 green: 1 blue: 1 alpha: 1]];
    frame.fill = fill;
    
    [self setupMainAxes];

    // The second y axis is used as the current location identifier.
    mainIndicatorLine = [[[CPTXYAxis alloc] init] autorelease];
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
    lineStyle.dashPattern = lineStyle.dashPattern = [NSArray arrayWithObjects:
                                                     [NSNumber numberWithFloat: 10.0f],
                                                     [NSNumber numberWithFloat: 5.0f],
                                                     nil];
    mainIndicatorLine.axisLineStyle = lineStyle;
    mainIndicatorLine.majorTickLineStyle = nil;
    
    // Add the mainIndicatorLine to the axis set.
    // It is essential to first assign the axes to be used in the arrayWithObject call
    // to local variables or all kind of weird things start showing up later (mostly with invalid coordinates).
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    CPTXYAxis* y = axisSet.yAxis;
    axisSet.axes = [NSArray arrayWithObjects: x, y, mainIndicatorLine, nil];
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
    
    NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
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
    turnoversGraph.zPosition = -100;
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
    
    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 2.0;
    frame.shadowOffset = CGSizeMake(1, -1);
    frame.shadowOpacity = 0.25;
    
    [self setupTurnoversAxes];
    
    // The second y axis is used as the current location identifier.
    turnoversIndicatorLine = [[[CPTXYAxis alloc] init] autorelease];
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
    lineStyle.dashPattern = lineStyle.dashPattern = [NSArray arrayWithObjects:
                                                     [NSNumber numberWithFloat: 10.0f],
                                                     [NSNumber numberWithFloat: 5.0f],
                                                     nil];
    turnoversIndicatorLine.axisLineStyle = lineStyle;
    turnoversIndicatorLine.majorTickLineStyle = nil;
    
    // Add the second y axis to the axis set.
    CPTXYAxisSet* axisSet = (id)turnoversGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    CPTXYAxis* y = axisSet.yAxis;
    axisSet.axes = [NSArray arrayWithObjects: x, y, turnoversIndicatorLine, nil];
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
    selectionGraph.zPosition = -100;
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
    
    // Frame setup (background, border).
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
    
    frame.shadowColor = CGColorCreateGenericGray(0, 1);
    frame.shadowRadius = 3.0;
    frame.shadowOffset = CGSizeMake(2, -2);
    frame.shadowOpacity = 0.7;

    [self setupSelectionAxes];
}

- (CPTScatterPlot*)createScatterPlotWithFill: (CPTFill*)fill
{
    CPTScatterPlot* linePlot = [[[CPTScatterPlot alloc] init] autorelease];
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
    CPTBarPlot *barPlot = [[[CPTBarPlot alloc] init] autorelease];
    barPlot.barBasesVary = NO;
    barPlot.barWidthsAreInViewCoordinates = YES;
    barPlot.barWidth = CPTDecimalFromFloat(barWidth);
    barPlot.barCornerRadius = 3.0f;
    barPlot.barsAreHorizontal = NO;
    barPlot.baseValue = CPTDecimalFromInt(0);
    barPlot.alignsPointsToPixels = YES;
    
    if (withBorder) {
        CPTMutableLineStyle* lineStyle = [[[CPTMutableLineStyle alloc] init] autorelease];
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

    // The main graph contains two plots, one for the positive values (with a gray fill)
    // and the other one for negative values (with a red fill).
    // Depending on whether we view a bank account or a normal category either line or bar plots are used.
    if (mainCategory != nil) {
        CPTGradient* positiveGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithComponentRed: 120 / 255.0
                                                                                                           green: 120 / 255.0
                                                                                                            blue: 120 / 255.0
                                                                                                           alpha: 0.75]
                                                                    endingColor: [CPTColor colorWithComponentRed: 60 / 255.0
                                                                                                           green: 60 / 255.0
                                                                                                            blue: 60 / 255.0
                                                                                                           alpha: 1]
                                         ];
        positiveGradient.angle = -90.0;
        CPTFill* positiveGradientFill = [CPTFill fillWithGradient: positiveGradient];
        CPTGradient* negativeGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithComponentRed: 194 / 255.0
                                                                                                           green: 69 / 255.0
                                                                                                            blue: 47 / 255.0
                                                                                                           alpha: 1]
                                                                    endingColor: [CPTColor colorWithComponentRed: 194 / 255.0
                                                                                                           green: 69 / 255.0
                                                                                                            blue: 47 / 255.0
                                                                                                           alpha: 0.9]
                                         ];
        
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
    }
    
    [self updateMainGraph];
}

-(void)setupTurnoversPlot
{
    [turnoversGraph removePlotWithIdentifier: @"turnoversPlot"];

    CPTGradient* areaGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithComponentRed: 23 / 255.0
                                                                                                   green: 124 / 255.0
                                                                                                    blue: 236 / 255.0
                                                                                                   alpha: 0.75]
                                                            endingColor: [CPTColor colorWithComponentRed: 18 / 255.0
                                                                                                   green: 97 / 255.0
                                                                                                    blue: 185 / 255.0
                                                                                                   alpha: 0.75]
                                 ];
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
        CPTGradient* gradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithComponentRed: 255 / 255.0
                                                                                                   green: 255 / 255.0
                                                                                                    blue: 255 / 255.0
                                                                                                   alpha: 0.80]
                                                            endingColor: [CPTColor colorWithComponentRed: 255 / 255.0
                                                                                                   green: 255 / 255.0
                                                                                                    blue: 255 / 255.0
                                                                                                   alpha: 0.9]
                                 ];
        gradient.angle = 90.0;
        CPTFill* gradientFill = [CPTFill fillWithGradient: gradient];
        
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
- (float)intervalFromRange: (NSDecimalNumber*) range
{
    int digitCount = [range numberOfDigits];
    NSDecimal value = [range decimalValue];
    NSDecimal hundred = [[NSNumber numberWithInt: 100] decimalValue];
    if (NSDecimalCompare(&value, &hundred) == NSOrderedDescending) {
        // The range is > 100 so scale it down so it falls into that range.
        NSDecimalMultiplyByPowerOf10(&value, &value, -digitCount + 2, NSRoundDown);
    }
    double convertedValue = [[NSDecimalNumber decimalNumberWithDecimal: value] doubleValue];
    if (convertedValue < 10) {
        return pow(10, digitCount - 1);
    }
    if (convertedValue == 10) {
        return 2 * pow(10, digitCount - 2);
    }
    if (convertedValue <= 15) {
        return 3 * pow(10, digitCount - 2);
    }
    if (convertedValue <= 45) {
        return 5 * pow(10, digitCount - 2);
    }

    return pow(10, digitCount - 1);
}

/**
 * Determines a good number of subticks depending on the size of the interval. The returned value
 * should be so that it is easy to sum up subinterval steps to find a value from the graph easily.
 */
- (float)minorTicksFromInterval: (float)interval
{
    NSDecimal value = CPTDecimalFromFloat(interval);
    int digitCount = [[NSDecimalNumber decimalNumberWithDecimal: value] numberOfDigits];
    NSDecimal hundred = [[NSNumber numberWithInt: 100] decimalValue];
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
    double min = 0;
    double max = 0;
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;

    if (rawCount > 0) {
        
        NSUInteger units = round(plotSpace.xRange.locationDouble);
        NSUInteger startIndex = [self findIndexForTimePoint: units];
        if (![mainCategory isBankAccount] && timePoints[startIndex] < units) {
            // The search routine for an index is left affine, that is, the lower indices are prefered
            // when a time point is between two time indices.
            // For scatterplots this is ok, but we need to correct it for bar plots to only consider
            // what is visible.
            ++startIndex;
        }
        units = round(plotSpace.xRange.endDouble);
        NSUInteger endIndex = [self findIndexForTimePoint: units] + 1;
        
        if (startIndex >= endIndex) {
            // Don't change the plot range if we are in a time range that doesn't contain values.
            return;
        }
        
        for (NSUInteger i = startIndex; i < endIndex; i++) {
            if (totalBalances[i] < min) {
                min = totalBalances[i];
            }
            if (totalBalances[i] > max) {
                max = totalBalances[i];
            }
        }
    } else {
        max = [totalMaxValue doubleValue];
    }
    
    NSDecimalNumber* minValue = [NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromDouble(min)];
    NSDecimalNumber* maxValue = [NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromDouble(max)];
    NSDecimalNumber* roundedMinValue = [minValue roundToUpperOuter];
    NSDecimalNumber* roundedMaxValue = [maxValue roundToUpperOuter];
    
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    
    float animationDuration = 0.3;
    if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) != 0) {
		animationDuration = 3;
	}

    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;

    // Let the larger area (negative or positive) determine the size of the major tick range.
    NSDecimalNumber* minAbsolute = [roundedMinValue abs];
    NSDecimalNumber* maxAbsolute = [roundedMaxValue abs];
    float interval;
    if ([minAbsolute compare: maxAbsolute] == NSOrderedDescending) {
        interval = [self intervalFromRange: minAbsolute];
    } else {
        interval = [self intervalFromRange: maxAbsolute];
    }
    
    // Apply new interval length and minor ticks now only if they lead to equal or less labels.
    // Otherwise do it after the animation.
    // This is necessary to avoid a potentially large intermittent number of labels during animation.
    NSDecimal newInterval = CPTDecimalFromFloat(interval);
    NSDecimal oldInterval = y.majorIntervalLength;
    if (NSDecimalCompare(&oldInterval, &newInterval) == NSOrderedAscending) {
        y.majorIntervalLength = newInterval;
        y.minorTicksPerInterval = [self minorTicksFromInterval: interval];
    }

    CorePlotXYRangeAnimation* animation = [[CorePlotXYRangeAnimation alloc] initWithDuration: animationDuration
                                                                              animationCurve: NSAnimationEaseInOut
                                                                                   plotSpace: plotSpace
                                                                                        axis: axisSet.yAxis
                                                                                   forXRange: NO];
    animation.animationBlockingMode = NSAnimationBlocking;
    animation.targetPosition = [roundedMinValue doubleValue];
    animation.targetLength = [[roundedMaxValue decimalNumberBySubtracting: roundedMinValue] doubleValue];
    [animation startAnimation];
    [animation release];

    y.majorIntervalLength = newInterval;
    y.minorTicksPerInterval = [self minorTicksFromInterval: interval];

    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: [roundedMinValue decimalValue]
                                                           length: [[roundedMaxValue decimalNumberBySubtracting: roundedMinValue] decimalValue]];
    
    plotSpace.globalYRange = plotRange;

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
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
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
    PecuniaPlotTimeFormatter* timeFormatter = [[[PecuniaPlotTimeFormatter alloc] initWithDateFormatter: dateFormatter
                                                                                          calendarUnit: calendarUnit] autorelease];
    
    timeFormatter.referenceDate = [referenceDate lowDate];
    x.labelFormatter = timeFormatter;

    // The currency of the main category can change so update the y axis label formatter as well.
    NSString* currency = (mainCategory == nil) ? @"EUR" : [mainCategory currency];
    NSNumberFormatter* currencyFormatter = [[[NSNumberFormatter alloc] init] autorelease];
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
    
    // Vertical range.
    double maxTurnoversCount = 0;
    
    for (NSUInteger i = 0; i < rawCount; i++) {
        if (balanceCounts[i] > maxTurnoversCount)
            maxTurnoversCount = balanceCounts[i];
    }
    
    // Ensure we have a value >= 1 to have a pleasant plot, even without values.
    if (maxTurnoversCount < 1) {
        maxTurnoversCount = 1;
    }
    
    NSDecimalNumber* roundedMax = [[NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromDouble(maxTurnoversCount)] roundToUpperOuter];
    plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromInt(0) length: [roundedMax decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
    
    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;
    y.visibleRange = plotRange;
    
    float interval = [self intervalFromRange: roundedMax];
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
    
    // Set the available plot space depending on the min, max and day values we found. Extend both range by a few precent for more appeal.
    CPTXYPlotSpace* plotSpace = (id)selectionGraph.defaultPlotSpace;
    
    // Horizontal range.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromInt(0)
                                                           length: CPTDecimalFromInt(totalUnits)];
    plotSpace.globalXRange = plotRange;
    plotSpace.xRange = plotRange;
    
    CPTXYAxisSet* axisSet = (id)selectionGraph.axisSet;

    // Vertical range.
    NSDecimalNumber* roundedMinValue = [totalMinValue roundToUpperOuter];
    NSDecimalNumber* roundedMaxValue = [totalMaxValue roundToUpperOuter];
    
    plotRange = [CPTPlotRange plotRangeWithLocation: [roundedMinValue decimalValue]
                                             length: [[roundedMaxValue decimalNumberBySubtracting: roundedMinValue] decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
    
    // Set the y axis lines depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;
    y.visibleRange = plotRange;
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
 * Updates the info annotation with the given values.
 */
- (void)updateMainInfo: (NSDictionary*)values
{
    ShortDate *date = [values objectForKey: @"date"];
    id balance = [values objectForKey: @"balance"];
    int turnovers = [[values objectForKey: @"turnovers"] intValue];
    
    
    if (infoTextFormatter == nil)
    {
        NSString* currency = (mainCategory == nil) ? @"EUR" : [mainCategory currency];
        infoTextFormatter = [[[NSNumberFormatter alloc] init] retain];
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
        infoLayer = [[(ColumnLayoutCorePlotLayer*)[ColumnLayoutCorePlotLayer alloc] initWithFrame: frame] autorelease];
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
        
        dateInfoLayer = [[[CPTTextLayer alloc] initWithText: @"" style: textStyle] autorelease];
        [infoLayer addSublayer: dateInfoLayer];
        
        textStyle = [CPTMutableTextStyle textStyle];
        textStyle.fontName = @"LucidaGrande-Bold";
        textStyle.fontSize = 16;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentCenter;
        
        valueInfoLayer = [[[CPTTextLayer alloc] initWithText: @"" style: textStyle] autorelease];
        [infoLayer addSublayer: valueInfoLayer];

        // We can also prepare the annotation which hosts the info layer but don't add it to the plot area yet.
        // When we switch the plots it won't show up otherwise unless we add it on demand.
        infoAnnotation = [[[CPTAnnotation alloc] init] retain];
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
    
    // Resize the info layer so that it fits its contents.
    CGRect infoBounds = infoLayer.bounds;
    infoBounds.size = [dateInfoLayer sizeThatFits];
    CGSize size = valueInfoLayer.hidden ? CGSizeMake(0, 0) : [valueInfoLayer sizeThatFits];
    if (size.width > infoBounds.size.width)
        infoBounds.size.width = size.width;
    infoBounds.size.width += infoLayer.paddingLeft + infoLayer.paddingRight + infoLayer.borderLineStyle.lineWidth;
    infoBounds.size.height += infoLayer.paddingTop + infoLayer.paddingBottom + infoLayer.spacing + size.height + infoLayer.borderLineStyle.lineWidth;
    infoLayer.bounds = infoBounds;
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
        [infoLayer fadeOut];
        [mainIndicatorLine fadeOut];
        [turnoversIndicatorLine fadeOut];
        return;
    } else {
        [infoLayer fadeIn];
        [mainIndicatorLine fadeIn];
        [turnoversIndicatorLine fadeIn];
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
        if (abs(targetPoint.x - actualLocation) <= barWidth) {
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
    
    if (!dateHit && (timePoint == timePointAtIndex)) {
        dateHit = YES;
    }

    // If there wasn't a date hit (i.e. the current position is at an actual value) then
    // use the date left to the position (not rounded), so we show the unit properly til
    // the next unit tick.
    if (!dateHit) {
        index = [self findIndexForTimePoint: floor(CPTDecimalFloatValue(dataPoint[0]))];
    }

    if (lastInfoTimePoint == 0 || (timePoint != lastInfoTimePoint) || dateHit)
    {
        lastInfoTimePoint = timePoint;

        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        [values setObject: [self dateByAddingUnits: referenceDate count: timePoint] forKey: @"date"];
        id balance;
        int turnovers = 0;
        if (dateHit) {
            balance = [NSNumber numberWithDouble: totalBalances[index]];
            turnovers = balanceCounts[index];
        } else {
            balance = [mainCategory isBankAccount] ? [NSNumber numberWithDouble: totalBalances[index]] : (id)[NSNull null];
        }
        [values setObject: balance forKey: @"balance"];
        [values setObject: [NSNumber numberWithInt: turnovers] forKey: @"turnovers"];

        // Update the info layer content, but after a short delay. This will be canceled if new
        // update request arrive in the meantime (circumventing so too many updates that slow down the display).
        [self performSelector: @selector(updateMainInfo:) withObject: values afterDelay: 0.1];
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
    [selectionBand release];
    CPTFill* bandFill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 134 / 255.0
                                                                          green: 153 / 255.0
                                                                           blue: 67 / 255.0
                                                                          alpha: 1]];
    
    NSDecimal fromPoint = [self distanceAsDecimalFromDate: referenceDate toDate: fromDate];
    selectionBand = [[CPTLimitBand limitBandWithRange:
                      [CPTPlotRange plotRangeWithLocation: fromPoint
                                                   length: CPTDecimalSubtract([self distanceAsDecimalFromDate: referenceDate toDate: toDate], fromPoint)]
                                                 fill: bandFill] retain];
    [x addBackgroundLimitBand: selectionBand];
    selectionHostView.selector = selectionBand;
}

- (void)updateTimeRangeVariables
{
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
    
    NSDecimal fromPoint = plotSpace.xRange.location;
    [fromDate release];
    fromDate = [[self dateByAddingUnits: referenceDate count: CPTDecimalIntValue(fromPoint)] retain];
    
    NSDecimal toPoint = plotSpace.xRange.end;
    [toDate release];
    toDate = [[self dateByAddingUnits: referenceDate count: CPTDecimalIntValue(toPoint)] retain];
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
        
        [NSObject cancelPreviousPerformRequestsWithTarget: self];
        
        NSDictionary* parameters = [notification userInfo];
        NSString* type = [parameters objectForKey: @"type"];
        
        CPTXYPlotSpace* sourcePlotSpace = notification.object;
        BOOL fromSelectionGraph = (sourcePlotSpace == selectionGraph.defaultPlotSpace);
        BOOL isDragMove = [type isEqualToString: @"plotMoveDrag"];
        BOOL isScale = [type isEqualToString: @"plotScale"];
        BOOL keepInfoLayerHidden = NO;
        if ([type isEqualToString: @"plotMoveSwipe"] || isDragMove || isScale) {
            if (isDragMove || isScale) {
                keepInfoLayerHidden = YES;
                if (!infoLayer.hidden) {
                    [infoLayer fadeOut];
                }
            }
            
            NSNumber* location = [parameters objectForKey: @"plotXLocation"];
            NSNumber* range = [parameters objectForKey: @"plotXRange"];
            NSNumber* lowRange = [NSNumber numberWithInt: [self majorTickCount]];
            if ([range compare: lowRange] == NSOrderedAscending)
                range = lowRange;
            
            NSNumber* center = [parameters objectForKey: @"mousePosition"];

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
                location = [NSNumber numberWithFloat: [location  floatValue] + offset];
            }
            
            [self applyRangeLocationToPlotSpace: (id)mainGraph.defaultPlotSpace location: location range: range];
            [self applyRangeLocationToPlotSpace: (id)turnoversGraph.defaultPlotSpace location: location range: range];

            // Adjust the time range display in the selection graph.
            [self updateTimeRangeVariables];
            [self updateSelectionDisplay];

            // Adjust vertical graph ranges after a short delay.
            [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.1];

            if (!keepInfoLayerHidden && !fromSelectionGraph) {
                [self updateTrackLinesAndInfoAnnotation: center];
            }
        } else {
            if ([type isEqualToString: @"trackLineMove"]) {
                NSNumber* location = [parameters objectForKey: @"location"];
                [self updateTrackLinesAndInfoAnnotation: location];
            } else {
                if ([type isEqualToString: @"plotMoveCenter"]) {
                    NSNumber* location = [parameters objectForKey: @"location"];
                    NSNumber* range = [parameters objectForKey: @"plotXRange"];

                    CGPoint point = CGPointMake([location floatValue], 0);
                    
                    NSDecimal dataPoint[2];
                    [sourcePlotSpace plotPoint: dataPoint forPlotAreaViewPoint: point];
                    double timePoint = CPTDecimalDoubleValue(dataPoint[0]);
                    location = [NSNumber numberWithDouble: timePoint - [range doubleValue] / 2];

                    [self applyRangeLocationToPlotSpace: (id)mainGraph.defaultPlotSpace location: location range: range];
                    [self applyRangeLocationToPlotSpace: (id)turnoversGraph.defaultPlotSpace location: location range: range];
                    
                    // Adjust the time range display in the selection graph.
                    [self updateTimeRangeVariables];
                    [self updateSelectionDisplay];
                    
                    [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.1];
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
    [infoLayer fadeOut];
    [mainIndicatorLine fadeOut];
    [turnoversIndicatorLine fadeOut];
}

#pragma mark -
#pragma mark Plot Delegate Methods

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot*)plot
{
    if ([plot graph] == selectionGraph && selectionBalances != nil) {
        return selectionSampleCount;
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
            return &negativeBalances[indexRange.location];
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

- (void)updateValues
{
    if (rawCount > 0) {
        double minDoubleValue = 0;
        double maxDoubleValue = 0;
        for (NSUInteger i = 0; i < rawCount; i++) {
            if (totalBalances[i] > maxDoubleValue) {
                maxDoubleValue = totalBalances[i];
            }
            if (totalBalances[i] < minDoubleValue) {
                minDoubleValue = totalBalances[i];
            }
        }
        
        [totalMinValue release];
        totalMinValue = [[NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromDouble(minDoubleValue)] retain];
        [totalMaxValue release];
        totalMaxValue = [[NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromDouble(maxDoubleValue)] retain];
    } else {
        // totalMinValue is already set to zero in clearGraphs.
        [totalMaxValue release];
        totalMaxValue = [[NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromInt(100)] retain];
    }
    
    // Update the selected range so that its length corresponds to the minimum length
    // and it doesn't start before the first date in the date array. It might go beyond the
    // available data, which is handled elsewhere.

    // First check the selection length.
    int units = [self distanceFromDate: fromDate toDate: toDate];
    if (units < [self majorTickCount]) {
        [toDate release];
        toDate = [[self dateByAddingUnits: fromDate count: [self majorTickCount]] retain];
    }

    // Now see if the new toDate goes beyond the available data. Try fixing it (if so)
    // by moving the selected range closer to the beginning.
    ShortDate* date = [self dateByAddingUnits: referenceDate count: (rawCount > 0) ? timePoints[rawCount - 1] : 0];
    if (toDate == nil || [date compare: toDate] == NSOrderedAscending) {
        units = [self distanceFromDate: toDate toDate: date];
        [toDate release];
        toDate = [date retain];
        
        date = [self dateByAddingUnits: fromDate count: units];
        [fromDate release];
        fromDate = [date retain];
    }

    // Finaly ensure we do not begin before our first data entry. Move the selection range
    // accordingly, accepting that this might move the end point beyond the last data entry.
    date = referenceDate;
    if (fromDate == nil || [date compare: fromDate] == NSOrderedDescending) {
        units = [self distanceFromDate: fromDate toDate: date];
        [fromDate release];
        fromDate = [date retain];

        date = [self dateByAddingUnits: toDate count: units];
        [toDate release];
        toDate = [date retain];
    }
}

- (void)clearGraphs
{
    NSArray* plots = mainGraph.allPlots;
    for (CPTPlot* plot in plots) {
        [mainGraph removePlot: plot];
    }
    plots = turnoversGraph.allPlots;
    for (CPTPlot* plot in plots) {
        [turnoversGraph removePlot: plot];
    }
    plots = selectionGraph.allPlots;
    for (CPTPlot* plot in plots) {
        [selectionGraph removePlot: plot];
    }
    
    mainGraph.defaultPlotSpace.allowsUserInteraction = NO;
    turnoversGraph.defaultPlotSpace.allowsUserInteraction = NO;
    selectionGraph.defaultPlotSpace.allowsUserInteraction = NO;

    [totalMaxValue release];
    totalMaxValue = [[NSDecimalNumber zero] retain];
    [totalMinValue release];
    totalMinValue = [[NSDecimalNumber zero] retain];
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
    
    [referenceDate release];
    referenceDate = [[ShortDate currentDate] retain];
    
    if (mainCategory == nil)
        return;
    
    NSArray *dates = nil;
    NSArray *balances = nil;
    NSArray *turnovers = nil;
    if (mainCategory.isBankAccount) {
        [mainCategory balanceHistoryToDates: &dates
                                   balances: &balances
                              balanceCounts: &turnovers
                               withGrouping: groupingInterval];
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
        rawCount = [dates count] + 1;
        
        // Convert the dates to distance units from a reference date.
        timePoints = malloc(rawCount * sizeof(double));
        [referenceDate release];
        referenceDate = [[dates objectAtIndex: 0] retain];
        int index = 0;
        for (ShortDate *date in dates) {
            timePoints[index++] = [self distanceFromDate: referenceDate toDate: date];
        }
        timePoints[index] = timePoints[index - 1] + 1000; // A date far in the future.
        
        // Convert all NSDecimalNumbers to double for better performance.
        totalBalances = malloc(rawCount * sizeof(double));
        positiveBalances = malloc(rawCount * sizeof(double));
        negativeBalances = malloc(rawCount * sizeof(double));
        
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
        totalBalances[index] = 0;
        positiveBalances[index] = 0;
        negativeBalances[index] = 0;
        balanceCounts[index] = 0;
        
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
    
    [self updateValues];

    [mainGraph reloadData];
    [turnoversGraph reloadData];
    [selectionGraph reloadData];
}

- (void)updateGraphs
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
        
    [self clearGraphs];
    [self reloadData];
    
    if (rawCount > 0) {
        mainGraph.defaultPlotSpace.allowsUserInteraction = YES;
        turnoversGraph.defaultPlotSpace.allowsUserInteraction = YES;
        selectionGraph.defaultPlotSpace.allowsUserInteraction = YES;
    };

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
    [helpWindow release];
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

#pragma mark -
#pragma mark Interface Builder Actions

- (IBAction)setGrouping: (id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];

    groupingInterval = [sender intValue];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* values = [userDefaults objectForKey: @"categoryAnalysis"];
    if (values == nil) {
        values = [NSMutableDictionary dictionaryWithCapacity: 1];
        [userDefaults setObject: values forKey: @"categoryAnalysis"];
    }
    [values setValue: [NSNumber numberWithInt: groupingInterval] forKey: @"grouping"];

    [self reloadData];
    
    if (rawCount == 0) {
        [self clearGraphs];
        [totalMaxValue release];
        totalMaxValue = [[NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromInt(100)] retain];
    } else {
        mainGraph.defaultPlotSpace.allowsUserInteraction = YES;
        turnoversGraph.defaultPlotSpace.allowsUserInteraction = YES;
        selectionGraph.defaultPlotSpace.allowsUserInteraction = YES;
    }
    
    [self updateMainGraph];
    [self updateTurnoversGraph];
    [self updateSelectionGraph];
    [self updateSelectionDisplay];
    
    [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.3];
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

    printOp = [NSPrintOperation printOperationWithView: [topView getPrintViewForLayerBackedView] printInfo: printInfo];

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
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
        
    [fromDate release];
    fromDate = [from retain];
    
    [toDate release];
    toDate = [to retain];

    [self updateValues];

    [self updateMainGraph];
    [self updateTurnoversGraph];
    [self updateSelectionGraph];
    [self updateSelectionDisplay];
    
    [self performSelector: @selector(updateVerticalMainGraphRange) withObject: nil afterDelay: 0.1];
}

- (void)setCategory:(Category *)newCategory
{
    if (mainCategory != newCategory) {
        mainCategory = newCategory;
        [self updateGraphs];
    }
}

@end

