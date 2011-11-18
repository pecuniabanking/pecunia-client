//
//  AccountRepWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "AccountRepWindowController.h"
#import "Category.h"
#import "MCEMOutlineViewLayout.h"
#import "ShortDate.h"
#import "TimeSliceManager.h"
#import "MOAssistant.h"
#import "ImageAndTextCell.h"
#import "BankAccount.h"

#import "NumberExtensions.h"

static NSTimeInterval oneDay = 24 * 60 * 60;

static NSString* const PecuniaGraphLayoutChangeNotification = @"PecuniaGraphLayoutChange";

@implementation PecuinaGraphHost

- (void)updateTrackingArea
{
    if (trackingArea != nil)
    {
        [self removeTrackingArea: trackingArea];
        [trackingArea release];
    }
    trackingArea = [[[NSTrackingArea alloc] initWithRect: [self bounds]
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
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    short subtype = [theEvent subtype];
    if (subtype == NSTabletPointEventSubtype)
    {
        // A trackpad gesture (usually two-finger swipe).
        [parameters setObject: @"plotMoveSwipe" forKey: @"type"];

        CGFloat distance = [theEvent deltaX];
        CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;

        NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / 100];
        [parameters setObject: location forKey: @"plotXLocation"];
        
        NSNumber* range = [NSNumber numberWithDouble: CPTDecimalDoubleValue(plotSpace.xRange.length)];
        [parameters setObject: range forKey: @"plotXRange"];
        [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
    }
    else 
    {
        [parameters setObject: @"plotScale" forKey: @"type"];
        
        CGFloat distance = [theEvent deltaY];
        CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
        
        // Range location and size.
        NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble];
        [parameters setObject: location forKey: @"plotXLocation"];

        NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble * (1 + distance / 100)];
        [parameters setObject: range forKey: @"plotXRange"];
        
        // Center of the scale operation (the mouse position).
        CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
        CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
        [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"scaleCenter"];

        [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
    }
}

/**
 * Allow zooming the graph with a pinch gesture on a trackpad.
 */
-(void)magnifyWithEvent: (NSEvent*)theEvent
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
   [parameters setObject: @"plotScale" forKey: @"type"];

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    CGFloat relativeScale = [theEvent magnification];
    
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    
    NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble];
    [parameters setObject: location forKey: @"plotXLocation"];

    NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble * (1 - relativeScale)];
    [parameters setObject: range forKey: @"plotXRange"];

    CGPoint mouseLocation = NSPointToCGPoint([self convertPoint: [theEvent locationInWindow] fromView: nil]);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"scaleCenter"];
    
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseMoved: (NSEvent*)theEvent
{
    [super mouseMoved: theEvent];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject: @"trackLineMove" forKey: @"type"];
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    
    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [parameters setObject: [NSNumber numberWithFloat: pointInHostedGraph.x] forKey: @"location"];
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    [parameters setObject: @"plotMoveDrag" forKey: @"type"];
    
    CGFloat distance = [theEvent deltaX];
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    
    NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / 1000];
    [parameters setObject: location forKey: @"plotXLocation"];
    
    NSNumber* range = [NSNumber numberWithDouble: CPTDecimalDoubleValue(plotSpace.xRange.length)];
    [parameters setObject: range forKey: @"plotXRange"];
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

@end;

//--------------------------------------------------------------------------------------------------

@implementation AccountRepWindowController

@synthesize firstDate;
@synthesize fromDate;
@synthesize toDate;

@synthesize barWidth; // The width of all bars in either the main or the turnovers bar.

-(id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    barWidth = 15;
    managedObjectContext = [[MOAssistant assistant] context];
    return self;
}

-(void)dealloc 
{
    [firstDate release], firstDate = nil;
    [fromDate release], fromDate = nil;
    [toDate release], toDate = nil;
    
    [mainGraph release];
    [dates release];
    [balances release];
    [balanceCounts release];
    
    [mainIndicatorLine release];
    [turnoversIndicatorLine release];
    
    [infoLayer release];
    [infoTextFormatter release];
    [lastInfoDate release];
    [infoAnnotation release];
    
    [super dealloc];
}

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

/**
 * Returns the first (earliest) date in the data, which serves as the reference date to which
 * all other dates are compared (to create a time distance in seconds).
 * If we have no data then the current date is used instead.
 */
-(ShortDate*)referenceDate
{
    if ([dates count] > 0)
        return [dates objectAtIndex: 0];
    return [ShortDate dateWithDate: [NSDate date]];
}

-(void)setupShadowForPlot: (CPTPlot*) plot
{
    plot.shadowColor = CGColorCreateGenericGray(0, 1);
    plot.shadowRadius = 2.0;
    plot.shadowOffset = CGSizeMake(1, -1);
    plot.shadowOpacity = 0.75;
}

-(void)awakeFromNib
{
    NSError *error;
    
    [accountsController fetchWithRequest: nil merge: NO error: &error];
    
    // sort descriptor for accounts view
    NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES] autorelease];
    NSArray	*sds = [NSArray arrayWithObject: sd];
    [accountsController setSortDescriptors: sds];
    
    [self performSelector: @selector(restoreAccountsView) withObject: nil afterDelay: 0.0];
    
    [self setupMainGraph];
    [self setupTurnoversGraph];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(graphLayoutChanged:)
                                                 name: PecuniaGraphLayoutChangeNotification
                                               object: nil];
}

-(void)setupMainGraph
{
    mainGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(mainHostView.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [mainGraph applyTheme: theme];
    mainHostView.hostedGraph = mainGraph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)mainGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    
    // Grid line styles
    CPTMutableLineStyle* frameStyle = [CPTMutableLineStyle lineStyle];
    frameStyle.lineWidth = 0.75;
    frameStyle.lineColor = [[CPTColor colorWithGenericGray: 0.2] colorWithAlphaComponent: 0.75];
    
    // Graph title
    mainGraph.title = @"Nichts ausgewählt";
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"LucidaGrande-Bold";
    textStyle.fontSize = 22.0;
    textStyle.textAlignment = CPTTextAlignmentRight;
    mainGraph.titleTextStyle = textStyle;
    mainGraph.titleDisplacement = CGPointMake(150.0, 15.0);
    mainGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
    // Graph padding
    mainGraph.paddingLeft = 10.0;
    mainGraph.paddingTop = 30.0;
    mainGraph.paddingRight = 10.0;
    mainGraph.paddingBottom = 10.0;
    
    CPTPlotAreaFrame* frame = mainGraph.plotAreaFrame;
    frame.paddingLeft = 60;
    frame.paddingRight = 30;
    frame.paddingTop = 20;
    frame.paddingBottom = 20;
    
    frame.cornerRadius = 10;
    frame.borderLineStyle = frameStyle;
    
    // Axes.
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromFloat(30 * oneDay);
    x.minorTicksPerInterval = 0;
    
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    CPTTimeFormatter* timeFormatter = [[[CPTTimeFormatter alloc] initWithDateFormatter: dateFormatter] autorelease];
    
    timeFormatter.referenceDate = [[self referenceDate] highDate];
    x.labelFormatter = timeFormatter;
    
    textStyle = [CPTMutableTextStyle textStyle];
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
    
    // The second y axis is used as the current location identifier.
    mainIndicatorLine = [[[CPTXYAxis alloc] init] autorelease];
    mainIndicatorLine.coordinate = CPTCoordinateY;
    mainIndicatorLine.plotSpace = plotSpace;
    mainIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    mainIndicatorLine.labelingPolicy = CPTAxisLabelingPolicyNone;
    mainIndicatorLine.separateLayers = NO;
    mainIndicatorLine.preferredNumberOfMajorTicks = 6;
    mainIndicatorLine.minorTicksPerInterval = 0;

    lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithGenericGray: 64 / 255.0];
    lineStyle.lineCap = kCGLineCapRound;
    lineStyle.dashPattern = lineStyle.dashPattern = [NSArray arrayWithObjects:
                                                     [NSNumber numberWithFloat: 10.0f],
                                                     [NSNumber numberWithFloat: 5.0f],
                                                     nil];
    mainIndicatorLine.axisLineStyle = lineStyle;
    mainIndicatorLine.majorTickLineStyle = nil;
    
    // Add the y2 axis to the axis set
    axisSet.axes = [NSArray arrayWithObjects: x, y, mainIndicatorLine, nil];

    [self setupMainPlots];
}

-(void)setupTurnoversGraph
{
    turnoversGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame: NSRectToCGRect(turnoversHostView.bounds)];
    CPTTheme *theme = [CPTTheme themeNamed: kCPTPlainWhiteTheme];
    [turnoversGraph applyTheme: theme];
    turnoversHostView.hostedGraph = turnoversGraph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)turnoversGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    
    // Grid line styles
    CPTMutableLineStyle* frameStyle = [CPTMutableLineStyle lineStyle];
    frameStyle.lineWidth = 0.75;
    frameStyle.lineColor = [[CPTColor colorWithGenericGray: 0.2] colorWithAlphaComponent: 0.75];
    
    // Graph title
    turnoversGraph.title = @"Anzahl Umsätze je Tag";
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"LucidaGrande-Bold";
    textStyle.fontSize = 16.0;
    textStyle.textAlignment = CPTTextAlignmentRight;
    turnoversGraph.titleTextStyle = textStyle;
    turnoversGraph.titleDisplacement = CGPointMake(0.0, 15.0);
    turnoversGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
    // Graph padding
    turnoversGraph.paddingLeft = 10.0;
    turnoversGraph.paddingTop = 20;
    turnoversGraph.paddingRight = 10.0;
    turnoversGraph.paddingBottom = 10;
    
    CPTPlotAreaFrame* frame = turnoversGraph.plotAreaFrame;
    frame.paddingLeft = 60;
    frame.paddingRight = 30;
    frame.paddingTop = 15;
    frame.paddingBottom = 15;
    
    frame.cornerRadius = 10;
    frame.borderLineStyle = frameStyle;
    
    // Axes.
    CPTXYAxisSet* axisSet = (id)turnoversGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.labelTextStyle = nil;
    
    textStyle = [CPTMutableTextStyle textStyle];
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
    //y.labelAlignment = CPTAlignmentBottom;
    
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
    
    // The second y axis is used as the current location identifier.
    turnoversIndicatorLine = [[[CPTXYAxis alloc] init] autorelease];
    turnoversIndicatorLine.coordinate = CPTCoordinateY;
    turnoversIndicatorLine.plotSpace = plotSpace;
    turnoversIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    turnoversIndicatorLine.labelingPolicy = CPTAxisLabelingPolicyNone;
    turnoversIndicatorLine.separateLayers = NO;
    turnoversIndicatorLine.preferredNumberOfMajorTicks = 6;
    turnoversIndicatorLine.minorTicksPerInterval = 0;

    lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithGenericGray: 64 / 255.0];
    lineStyle.dashPattern = lineStyle.dashPattern = [NSArray arrayWithObjects:
                                                     [NSNumber numberWithFloat: 10.0f],
                                                     [NSNumber numberWithFloat: 5.0f],
                                                     nil];
    turnoversIndicatorLine.axisLineStyle = lineStyle;
    turnoversIndicatorLine.majorTickLineStyle = nil;
    
    // Add the y2 axis to the axis set
    axisSet.axes = [NSArray arrayWithObjects: x, y, turnoversIndicatorLine, nil];

    [self setupTurnoversPlot];
}

-(CPTScatterPlot*)createScatterPlotWithFill: (CPTFill*)fill
{
    CPTScatterPlot* linePlot = [[[CPTScatterPlot alloc] init] autorelease];
    linePlot.cachePrecision = CPTPlotCachePrecisionDecimal;
    linePlot.alignsPointsToPixels = NO;
    linePlot.dataLineStyle = nil;
    linePlot.interpolation = CPTScatterPlotInterpolationStepped;
    linePlot.areaFill = fill;
    linePlot.areaBaseValue = CPTDecimalFromInt(0);
    
    linePlot.delegate = self;
    linePlot.dataSource = self;
    
    return linePlot;
}

-(CPTBarPlot*)createBarPlotWithFill: (CPTFill*)fill
{
    CPTBarPlot *barPlot = [[[CPTBarPlot alloc] init] autorelease];
    barPlot.barBasesVary = NO;
    barPlot.barWidthsAreInViewCoordinates = YES;
    barPlot.barWidth = CPTDecimalFromFloat(barWidth);
    barPlot.barCornerRadius = 3.0f;
    barPlot.barsAreHorizontal = NO;
    barPlot.baseValue = CPTDecimalFromInt(0);
    barPlot.alignsPointsToPixels = NO;
    barPlot.cachePrecision = CPTPlotCachePrecisionDouble;
    
    CPTMutableLineStyle* lineStyle = [[[CPTMutableLineStyle alloc] init] autorelease];
    lineStyle.lineColor = [CPTColor whiteColor];
    lineStyle.lineWidth = 1;
    barPlot.lineStyle = lineStyle;
    barPlot.fill = fill;
    
    barPlot.delegate = self;
    barPlot.dataSource = self;
    
    return barPlot;
}

-(void)setupMainPlots
{
    // The main graph contains two plots, one for the positive values (with a gray fill)
    // and the other one for negative values (with a red fill).
    // Depending on whether we view a bank account or a normal category either line or bar plots are used.
    Category* category = [self currentSelection];
    if (category == nil)
        return;
    
    CPTGradient* positiveGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithComponentRed: 100 / 255.0
                                                                                                       green: 100 / 255.0
                                                                                                        blue: 100 / 255.0
                                                                                                       alpha: 0.75]
                                                                endingColor: [CPTColor colorWithComponentRed: 60 / 255.0
                                                                                                       green: 60 / 255.0
                                                                                                        blue: 60 / 255.0
                                                                                                       alpha: 0.75]
                                     ];
    positiveGradient.angle = -90.0;
    CPTFill* positiveGradientFill = [CPTFill fillWithGradient: positiveGradient];
    CPTGradient* negativeGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithComponentRed: 255 / 255.0
                                                                                                       green: 50 / 255.0
                                                                                                        blue: 50 / 255.0
                                                                                                       alpha: 0.75]
                                                                endingColor: [CPTColor colorWithComponentRed: 255 / 255.0
                                                                                                       green: 50 / 255.0
                                                                                                        blue: 50 / 255.0
                                                                                                       alpha: 0.75]
                                     ];
    
    negativeGradient.angle = -90.0;
    CPTFill* negativeGradientFill = [CPTFill fillWithGradient: negativeGradient];
    
    CPTPlot* plot;
    if (category.isBankAccount)
    {
        plot = [self createScatterPlotWithFill: positiveGradientFill];
    }
    else
    {
        plot = [self createBarPlotWithFill: positiveGradientFill];
    }
    
    CPTMutableTextStyle* labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.color = [CPTColor blackColor];
    plot.labelTextStyle = labelTextStyle;
    
    plot.identifier = @"positivePlot";
    [self setupShadowForPlot: plot];
    
    [mainGraph addPlot: plot];
    
    // The negative plot.
    if (category.isBankAccount)
    {
        plot = [self createScatterPlotWithFill: negativeGradientFill];
    }
    else
    {
        plot = [self createBarPlotWithFill: negativeGradientFill];
    }
    
    plot.identifier = @"negativePlot";
    [self setupShadowForPlot: plot];
    
    [mainGraph addPlot: plot];
    
    [self updateMainGraph];
}

-(void)setupTurnoversPlot
{
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
    CPTBarPlot* barPlot = [self createBarPlotWithFill: areaGradientFill];
    
    barPlot.identifier = @"turnoversPlot";
    [self setupShadowForPlot: barPlot];
    
    [turnoversGraph addPlot: barPlot];
    
    [self updateTurnoversGraph];
}

-(void)updateMainGraph
{
    Category* category = [self currentSelection];
    if (category == nil)
        mainGraph.title = @"";
    else
        mainGraph.title = [category.localName stringByAppendingString: @" - Entwicklung"];
    
    NSUInteger count = [dates count];
    
    NSDecimalNumber* maxValue = [NSDecimalNumber zero];
    NSDecimalNumber* minValue = [NSDecimalNumber zero];
    
    for (NSUInteger i = 0; i < count; i++)
    {
        id y = [balances objectAtIndex: i];
        
        if ([y compare: maxValue] == NSOrderedDescending)
            maxValue = y;
        if ([y compare: minValue] == NSOrderedAscending)
            minValue = y;
    }
    
    // Time intervals are specified in number of seconds on the x axis.
    ShortDate* startDate = [self referenceDate];
    int totalDays = (count > 0) ? [startDate daysToDate: [dates lastObject]] : 0;
    if (totalDays < 14)
        totalDays = 14;
    
    // Set the available plot space depending on the min, max and day values we found. Extend both range by a few precent for more appeal.
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
    
    // Horizontal range.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(oneDay * totalDays)];
    plotSpace.globalXRange = plotRange;
    plotSpace.xRange = plotRange;
    
    CPTXYAxisSet* axisSet = (id)mainGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalDivide(plotRange.length, CPTDecimalFromInt(15));
    CPTTimeFormatter* formatter = (id)x.labelFormatter;
    formatter.referenceDate = [[self referenceDate] highDate];
    
    // Vertical range.
    minValue = [minValue roundToUpperOuter];
    maxValue = [maxValue roundToUpperOuter];
    
    plotRange = [CPTPlotRange plotRangeWithLocation: [minValue decimalValue]
                                             length: [[maxValue decimalNumberBySubtracting: minValue] decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
    
    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;
    y.visibleRange = plotRange;
    
    // Let the large are (negative or positive) determine the size of the major tick range.
    NSDecimalNumber* minAbsolute = [minValue abs];
    if ([minAbsolute compare: maxValue] == NSOrderedDescending) {
        y.majorIntervalLength = [[minAbsolute decimalNumberByDividingBy: [NSDecimalNumber decimalNumberWithString: @"4"]] decimalValue];
    } else {
        y.majorIntervalLength = [[maxValue decimalNumberByDividingBy: [NSDecimalNumber decimalNumberWithString: @"4"]] decimalValue];
    }
    
    NSString* currency = (category == nil) ? @"EUR" : [category currency];
    NSNumberFormatter* currencyFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    currencyFormatter.usesSignificantDigits = YES;
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.currencyCode = currency;
    currencyFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", currencyFormatter.currencySymbol];
    y.labelFormatter = currencyFormatter;
    
    [mainGraph reloadData];
}

-(void)updateTurnoversGraph
{
    NSUInteger count = [dates count];
    
    CGFloat maxValue = 0;
    
    // Time intervals are specified in number of seconds on the x axis.
    for (NSUInteger i = 0; i < count; i++)
    {
        id y = [balanceCounts objectAtIndex: i];
        
        if ([y floatValue] > maxValue)
            maxValue = [y floatValue];
    }
    
    ShortDate* startDate = [self referenceDate];
    int totalDays = (count > 0) ? [startDate daysToDate: [dates lastObject]] : 0;
    if (totalDays < 14)
        totalDays = 14;
    
    // Set the available plot space depending on the min, max and day values we found.
    CPTXYPlotSpace* plotSpace = (id)turnoversGraph.defaultPlotSpace;
    
    // Horizontal range.
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(oneDay * totalDays)];
    plotSpace.globalXRange = plotRange;
    plotSpace.xRange = plotRange;
    
    CPTXYAxisSet* axisSet = (id)turnoversGraph.axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalDivide(plotRange.length, CPTDecimalFromInt(15));
    
    // Vertical range.
    NSDecimalNumber* roundedMax = [[NSDecimalNumber decimalNumberWithDecimal: CPTDecimalFromFloat(maxValue)] roundToUpperOuter];
    plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0) length: [roundedMax decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
    
    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis* y = axisSet.yAxis;
    y.visibleRange = plotRange;
    
    maxValue = [roundedMax doubleValue];
    if (maxValue <= 5) {
        y.majorIntervalLength = [roundedMax decimalValue];
        y.minorTicksPerInterval = maxValue - 1;
    }
    else {
        // Ensure the value is dividable by 2.
        if (fmod(maxValue, 2) != 0) {
            maxValue++;
        }
        y.majorIntervalLength = CPTDecimalDivide([roundedMax decimalValue], CPTDecimalFromFloat(2));
        y.minorTicksPerInterval = 2;
    }
    
    [turnoversGraph reloadData];
}

- (void)applyRangeLocationToPlotSpace: (CPTXYPlotSpace*)space location: (NSNumber*)location range: (NSNumber*)range
{
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble([location doubleValue])
                                                           length: CPTDecimalFromDouble([range doubleValue])];
    space.xRange = plotRange;
    CPTXYAxisSet* axisSet = (id)[space graph].axisSet;
    CPTXYAxis* x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalDivide(space.xRange.length, CPTDecimalFromInt(15));
}

/**
 * Updates the info annotation with the given values.
 */
- (void)updateMainInfoForDate: (ShortDate*)date balance: (NSDecimalNumber*)balance turnovers: (int)turnovers
{
    if (infoTextFormatter == nil)
    {
        Category* category = [self currentSelection];
        
        NSString* currency = (category == nil) ? @"EUR" : [category currency];
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
        textStyle.fontName = @"Lucida Grande";
        textStyle.fontSize = 12;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentCenter;
        
        valueInfoLayer = [[[CPTTextLayer alloc] initWithText: @"" style: textStyle] autorelease];
        [infoLayer addSublayer: valueInfoLayer];

        textStyle = [CPTMutableTextStyle textStyle];
        textStyle.fontName = @"Lucida Grande Bold";
        textStyle.fontSize = 14;
        textStyle.color = [CPTColor whiteColor];
        textStyle.textAlignment = CPTTextAlignmentCenter;
        
        dateInfoLayer = [[[CPTTextLayer alloc] initWithText: @"" style: textStyle] autorelease];
        [infoLayer addSublayer: dateInfoLayer];
        
        // We can also prepare the annotation which hosts the info layer but don't add it to the plot area yet.
        // When we switch the plots it won't show up otherwise unless we add it on demand.
        infoAnnotation = [[[CPTAnnotation alloc] init] retain];
        infoAnnotation.contentLayer = infoLayer;
    }
    if (![mainGraph.plotAreaFrame.plotArea.annotations containsObject: infoAnnotation])
        [mainGraph.plotAreaFrame.plotArea addAnnotation: infoAnnotation]; 

    dateInfoLayer.text = date.description;
    
    NSString* infoText = @"";
    if (balance != nil) {
        infoText = [infoTextFormatter stringFromNumber: balance];
    }
    if (turnovers == 1) {
        infoText = [NSString stringWithFormat: @"%@\n%@", infoText, NSLocalizedString(@"AP132", @"1 turnover")];
    } else {
        infoText = [NSString stringWithFormat: @"%@\n%@", infoText, [NSString stringWithFormat: NSLocalizedString(@"AP133", @"%u turnovers"), turnovers]];
    }
    valueInfoLayer.text = infoText;
    
    // Resize the info layer so that it fits its contents.
    CGRect infoBounds;
    infoBounds.size = [dateInfoLayer sizeThatFits];
    CGSize size = [valueInfoLayer sizeThatFits];
    if (size.width > infoBounds.size.width)
        infoBounds.size.width = size.width;
    infoBounds.size.width += infoLayer.paddingLeft + infoLayer.paddingRight + infoLayer.borderLineStyle.lineWidth;
    infoBounds.size.height += infoLayer.paddingTop + infoLayer.paddingBottom + infoLayer.spacing + size.height;
    infoLayer.bounds = infoBounds;
}

- (void)animatedMoveOfLayer: (CPTLayer*)layer toPosition: (CGPoint)newPosition
{
    if (layer.hidden) {
        return;
    }
    
    NSArray* keys = layer.animationKeys;
    for (NSString* key in keys)
        if ([key isEqualToString: @"animatePosition"]) {
            return;
        }
    
    CGMutablePathRef animationPath = CGPathCreateMutable();
    CGPathMoveToPoint(animationPath, NULL, layer.position.x, layer.position.y);
    CGPathAddLineToPoint(animationPath, NULL, newPosition.x, newPosition.y);
    
    layer.position = newPosition;
    
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath: @"position"];
    animation.path = animationPath;
    animation.duration = 0.5;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    
    [layer addAnimation: animation forKey: @"animatePosition"];
}

- (void)animatedShowOfLayer: (CPTLayer*)layer
{
    if (layer.hidden || layer.opacity < 1) {
        layer.hidden = NO;
        layer.opacity = 1;
        
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath: @"opacity"];
        animation.fromValue = [NSNumber numberWithFloat: 0];
        animation.toValue = [NSNumber numberWithFloat: 1];
        animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
        animation.delegate = self;
        
        [layer addAnimation: animation forKey: @"animateOpacity"];
    }
}

- (void)animatedHideOfLayer: (CPTLayer*)layer
{
    if (layer.opacity > 0) {
        layer.opacity = 0;
        
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath: @"opacity"];
        animation.fromValue = [NSNumber numberWithFloat: 1];
        animation.toValue = [NSNumber numberWithFloat: 0];
        animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
        animation.delegate = self;
        
        [layer addAnimation: animation forKey: @"animateOpacity"];
    }
}

- (void)animationDidStop: (CAAnimation*)anim finished: (BOOL)flag
{
    if (flag) {
        CABasicAnimation* animation = (CABasicAnimation*)anim;
        
        if ([animation.keyPath isEqualToString: @"opacity"]) {
            if (infoLayer.opacity < 1) {
                infoLayer.hidden = YES;
            }
        } 
    }
}

- (void)updateInfoLayerPosition
{
    // Place the info layer so in the graph that it doesn't get "in the way". This is done by dividing
    // the graph into 4 rectangles (top-left, top-right, bottom-left, bottom-rigth). The used quadrant
    // is that, which is farthest away from the mouse.
    CGRect frame = mainGraph.plotAreaFrame.plotArea.frame;
    CGFloat horizontalCenter = frame.size.width / 2;
    CGFloat verticalCenter = frame.size.height / 2;
    
    NSPoint mousePosition = [mainHostView.window convertScreenToBase: [NSEvent mouseLocation]];
    mousePosition = [mainHostView convertPoint: mousePosition fromView: nil];
    
    CPTPlot* plot = [mainGraph plotAtIndex: 0];
    CGPoint mouseLocation = NSPointToCGPoint(mousePosition);
    CGPoint pointInHostedGraph = [mainHostView.layer convertPoint: mouseLocation toLayer: [plot plotArea]];
    
    CGPoint infoLayerLocation;
    if (pointInHostedGraph.x <= horizontalCenter) {
        // Position in right half.
        infoLayerLocation.x = frame.origin.x + horizontalCenter + (horizontalCenter - infoLayer.bounds.size.width) / 2;
    } else {
        // Position in left half.
        infoLayerLocation.x = frame.origin.x + (horizontalCenter - infoLayer.bounds.size.width) / 2;
    }
    if (pointInHostedGraph.y <= verticalCenter) {
        // Position in top half.
        infoLayerLocation.y = frame.origin.y + verticalCenter + (verticalCenter - infoLayer.bounds.size.height) / 2;
    } else {
        // Position in bottom half.
        infoLayerLocation.y = frame.origin.y + (verticalCenter - infoLayer.bounds.size.height) / 2;
    }
    
    if (infoLayer.position.x != infoLayerLocation.x || infoLayer.position.y != infoLayerLocation.y)
        [self animatedMoveOfLayer: infoLayer toPosition: infoLayerLocation];
}

/**
 * Searches the date array for the closest value to the given date.
 * The search is left-affine, that is, if the date to search is between two existing dates the 
 * lower date will always be returned.
 */
- (int)findDateIndexForDate: (ShortDate*)dateToSearch
{
    if ([dates count] == 0)
        return -1;
    
    int low = 0;
    int high = [dates count] - 1;
    while (low <= high)
    {
        int mid = (low + high) / 2;
        ShortDate* date = [dates objectAtIndex: mid];
        switch ([date compare: dateToSearch])
        {
            case NSOrderedSame:
                return mid;
            case NSOrderedAscending:
                low = mid + 1;
                break;
            case NSOrderedDescending:
                high = mid - 1;
                break;
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
    CGFloat actualLocation = [location floatValue];
    
    // Determine the content for the info layer.
    CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
    CGPoint point = CGPointMake(actualLocation, 0);
    
    NSDecimal dataPoint[2];
    [plotSpace plotPoint: dataPoint forPlotAreaViewPoint: point];
    double timePoint = CPTDecimalDoubleValue(dataPoint[0]);
    
    // Check if the time point is within the visible range.
    if (timePoint < plotSpace.xRange.minLimitDouble ||
        timePoint > plotSpace.xRange.maxLimitDouble) {
        if (!infoLayer.hidden)
            [self animatedHideOfLayer: infoLayer];
        return;
    } else {
        if (infoLayer.hidden)
            [self animatedShowOfLayer: infoLayer];
    }

    // Find closest date in our date points that is before the computed date value.
    int days = floor(CPTDecimalFloatValue(dataPoint[0]) / oneDay);
    ShortDate* date = [[dates objectAtIndex: 0] dateByAddingDays: days];
    int index = [self findDateIndexForDate: date];
    ShortDate* dateAtIndex = [dates objectAtIndex: index];
    BOOL dateHit = NO;
    
    // The found index might not be one matching exactly the current date. In order to ease
    // usage we snap the indicator to the closest existing data point if it is within bar width distance.
    dataPoint[0] = CPTDecimalFromFloat(oneDay * [[self referenceDate] daysToDate: dateAtIndex]);
    CGPoint targetPoint = [plotSpace plotAreaViewPointForPlotPoint: dataPoint];
    if (abs(targetPoint.x - actualLocation) <= barWidth) {
        actualLocation = targetPoint.x;
        date = dateAtIndex;
        dateHit = YES;
    } else {
        // The found index is not close enough. Try the next date point if there is one.
        if (index < [dates count] - 1) {
            dateAtIndex = [dates objectAtIndex: ++index];
            dataPoint[0] = CPTDecimalFromFloat(oneDay * [[self referenceDate] daysToDate: dateAtIndex]);
            targetPoint = [plotSpace plotAreaViewPointForPlotPoint: dataPoint];
            if (abs(targetPoint.x - actualLocation) <= barWidth) {
                actualLocation = targetPoint.x;
                date = dateAtIndex;
                dateHit = YES;
            }
        }
    }

    if (lastInfoDate == nil || [date compare: lastInfoDate] != NSOrderedSame)
    {
        [lastInfoDate release];
        lastInfoDate = [date retain];
        
        if (dateHit) {
            [self updateMainInfoForDate: date
                                balance: [balances objectAtIndex: index]
                              turnovers: [[balanceCounts objectAtIndex: index] intValue]];
        } else {
            [self updateMainInfoForDate: date
                                balance: [[self currentSelection] isBankAccount] ? [balances objectAtIndex: index] : nil
                              turnovers: 0];
        }
    }

    // Position the indicator line to the given location in main and turnovers graphs.
    mainIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: actualLocation];
    turnoversIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: actualLocation];
    
    [self updateInfoLayerPosition];
}

/**
 * Handler method for notifications sent from the graph host windows if something in the graphs need
 * adjustment, mostly due to user input.
 */
- (void)graphLayoutChanged: (NSNotification*)notification
{
    if ([[notification name] isEqualToString: PecuniaGraphLayoutChangeNotification])
    {
        NSDictionary* parameters = [notification userInfo];
        NSString* type = [parameters objectForKey: @"type"];
        
        BOOL isDragMove = [type isEqualToString: @"plotMoveDrag"];
        BOOL isScale = [type isEqualToString: @"plotScale"];
        if ([type isEqualToString: @"plotMoveSwipe"] || isDragMove || isScale) {
            if (isDragMove && !infoLayer.hidden) {
                [self animatedHideOfLayer: infoLayer];
            }
            
            NSNumber* location = [parameters objectForKey: @"plotXLocation"];
            NSNumber* range = [parameters objectForKey: @"plotXRange"];
            NSNumber* lowRange = [NSNumber numberWithDouble: oneDay * 15]; // Corresponds to the number of major ticks for the x-axis.
            if ([range compare: lowRange] == NSOrderedAscending)
                range = lowRange;
            
            CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;

            // Apply new plot location and range to all relevant graphs.
            // If this is a scale event the adjust the location so that the center is at the mouse
            // location or in the middle of the pinch gesture.
            if (isScale) {
                // Convert scale center (given in device coordinates).
                NSNumber* center = [parameters objectForKey: @"scaleCenter"];
                CGPoint point = CGPointMake([center floatValue], 0);
                
                NSDecimal dataPoint[2];
                [plotSpace plotPoint: dataPoint forPlotAreaViewPoint: point];
                double timePoint = CPTDecimalDoubleValue(dataPoint[0]);
                
                CPTXYPlotSpace* sourcePlotSpace = [notification object];
                CGFloat oldRange = sourcePlotSpace.xRange.lengthDouble;
                CGFloat newRange = [range floatValue];
                CGFloat offset = (oldRange - newRange) * (timePoint - [location floatValue]) / oldRange;
                location = [NSNumber numberWithFloat: [location  floatValue] + offset];
            }
            
            [self applyRangeLocationToPlotSpace: plotSpace location: location range: range];
            
            plotSpace = (id)turnoversGraph.defaultPlotSpace;
            [self applyRangeLocationToPlotSpace: plotSpace location: location range: range];
        } else {
            if ([type isEqualToString: @"trackLineMove"]) {
                NSNumber* location = [parameters objectForKey: @"location"];
                [self updateTrackLinesAndInfoAnnotation: location];
            }
        }
    }
}

#pragma mark -
#pragma mark Plot Delegate Methods

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot: (CPTPlot *)plot
{
    if ([plot graph] == mainGraph)
        return [dates count];
    if ([plot graph] == turnoversGraph)
        return [balanceCounts count];
    
    return 0;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    if (fieldEnum == CPTBarPlotFieldBarLocation || fieldEnum == CPTScatterPlotFieldX)
    {
        ShortDate* date = [dates objectAtIndex: index];
        ShortDate* startDate = [self referenceDate];
        int days = [startDate daysToDate: date];
        
        return [NSDecimalNumber numberWithDouble: oneDay * days];
    }
    
    if ([plot graph] == turnoversGraph)
    {
        if (fieldEnum == CPTBarPlotFieldBarTip)
            return [NSDecimalNumber numberWithDouble: [[balanceCounts objectAtIndex: index] doubleValue]];
        
        return [NSDecimalNumber numberWithInt: 0];
    }
    
    if ([plot graph] == mainGraph)
    {
        NSString* identifier = (id)plot.identifier;
        if ([identifier isEqualToString: @"positivePlot"])
        {
            // Only return positive values for this plot. Negative values are displayed as 0.
            double value = [[balances objectAtIndex: index] doubleValue];
            if (value < 0)
                return [NSDecimalNumber numberWithDouble: 0];
            else
                return [NSDecimalNumber numberWithDouble: value];
        }
        else
        {
            // Similar as for the positive plot, but for negative values.
            double value = [[balances objectAtIndex: index] doubleValue];
            if (value > 0)
                return [NSDecimalNumber numberWithDouble: 0];
            else
                return [NSDecimalNumber numberWithDouble: value];
        }
    }
    
    return nil;
}
/*
 -(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
 {
 return nil;
 }
 */
-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index 
{
    return (id)[NSNull null]; // Don't show any label
}


#pragma mark -
#pragma mark Old chart code

-(void)prepare
{
}

-(void)print
{
    NSPrintInfo	*printInfo = [NSPrintInfo sharedPrintInfo ];
    [printInfo setTopMargin:45 ];
    [printInfo setBottomMargin:45 ];
    [printInfo setHorizontalPagination:NSFitPagination ];
    [printInfo setVerticalPagination:NSFitPagination ];
    NSPrintOperation *printOp;
    printOp = [NSPrintOperation printOperationWithView:printView printInfo: printInfo ];
    [printOp setShowsPrintPanel:YES ];
    [printOp runOperation ];
}

-(NSView*)mainView
{
    return mainView;
}

// workaround for strange outlineView collapsing...
-(void)restoreAccountsView
{
    [accountsView restoreAll];
}

-(void)clearGraphs
{
    [dates release];
    dates = nil;
    [balances release];
    balances = nil;
    [balanceCounts release];
    balanceCounts = nil;
    
    NSArray* plots = mainGraph.allPlots;
    for (CPTPlot* plot in plots)
        [mainGraph removePlot: plot];
    plots = turnoversGraph.allPlots;
    for (CPTPlot* plot in plots)
        [turnoversGraph removePlot: plot];
}

-(Category*)currentSelection
{
    NSArray* sel = [accountsController selectedObjects ];
    if(sel == nil || [sel count ] != 1) return nil;
    return [sel objectAtIndex: 0 ];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    [self clearGraphs];
    
    Category* category = [self currentSelection];
    if (category == nil)
        return;
    
    if (category.isBankAccount)
    {
        if ([category balanceHistoryToDates: &dates balances: &balances perDayCounts: &balanceCounts] == 0)
            return;
    }
    else
    {
        if ([category categoryHistoryToDates: &dates balances: &balances perDayCounts: &balanceCounts] == 0)
            return;
    }
    
    [dates retain];
    [balances retain];
    [balanceCounts retain];
    
    [self setupMainGraph];
    [self setupTurnoversGraph];
    
    // Set Date restrictions.
    [tsManager setMinDate: [dates objectAtIndex: 0]];
    [tsManager setMaxDate: [ShortDate dateWithDate: [NSDate date]]];
    
    [self updateValues];
    
    [[mainHostView window] makeFirstResponder: mainHostView];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(ImageAndTextCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    Category *cat = [item representedObject];
    if(cat == nil)
        return;
    
    //	NSImage *catImage		= [NSImage imageNamed:@"catdef4_18.png"];
    NSImage *moneyImage		= [NSImage imageNamed:@"money_18.png"];
    NSImage *moneySyncImage	= [NSImage imageNamed:@"money_sync_18.png"];
    NSImage *folderImage	= [NSImage imageNamed:@"folder_18.png"];
    
    if ([cat isBankAccount] && cat.accountNumber == nil)
        [cell setImage: folderImage];
    if ([cat isBankAccount] && cat.accountNumber != nil)
    {
        BankAccount *account = (BankAccount*)cat;
        if ([account.isManual boolValue] || [account.noAutomaticQuery boolValue])
            [cell setImage: moneyImage];
        else
            [cell setImage: moneySyncImage];
    }
    
    BOOL itemIsSelected = NO;
    if ([outlineView itemAtRow:[outlineView selectedRow]] == item)	 itemIsSelected = TRUE;
    
    BOOL itemIsRoot = [cat isRoot];
    if (itemIsRoot) {
        [cell setImage: nil];
    }
    
    [cell setValues: [cat catSum] currency: cat.currency unread: 0 selected: itemIsSelected root:itemIsRoot ];
}


-(void)updateValues
{
    Category *cat = [self currentSelection ];
    
    NSDecimalNumber	*expenses = [cat valuesOfType: cat_spendings from: self.fromDate to: self.toDate ];
    NSDecimalNumber *incomes = [cat valuesOfType: cat_earnings from: self.fromDate to: self.toDate ];
    NSDecimalNumber *balance = [incomes decimalNumberByAdding: expenses ];
    
    [self setValue: expenses forKey: @"sexpense" ];
    [self setValue: incomes forKey: @"sincome" ];
    [self setValue: balance forKey: @"sbalance" ];
}

-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm
{
    return @"AccRepTimeSlice";
}

-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to
{
    self.fromDate = from;
    self.toDate = to;
    [self updateValues];
}


- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item 
{
    return [outlineView persistentObjectForItem: item ];
}

-(id)outlineView: (NSOutlineView *)outlineView itemForPersistentObject: (id)object
{
    return nil;
}

-(void)terminate
{
    [accountsView saveLayout ];
}

@end

