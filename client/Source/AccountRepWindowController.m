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

double sign(double x)
{
    if(x<0) return -1.0; else return 1.0;
}

@implementation PecuinaGraphHost

-(void)scrollWheel: (NSEvent*)theEvent
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    short subtype = [theEvent subtype];
    if (subtype == NSTabletPointEventSubtype)
    {
        // A trackpad gesture (usually two-finger swipe).
        CGFloat distance = [theEvent deltaX];
        
        CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
        NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble - plotSpace.xRange.lengthDouble * distance / 100];
        [parameters setObject: location forKey: @"plotXLocation"];
        NSNumber* range = [NSNumber numberWithDouble: CPTDecimalDoubleValue(plotSpace.xRange.length)];
        [parameters setObject: range forKey: @"plotXRange"];
        [parameters setObject: [NSNumber numberWithBool: NO] forKey: @"excludeSource"];
        [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
    }
    else 
    {
        CGFloat distance = [theEvent deltaY];
        
        CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
        NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble];
        [parameters setObject: location forKey: @"plotXLocation"];
        NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble * (1 + distance / 100)];
        [parameters setObject: range forKey: @"plotXRange"];
        [parameters setObject: [NSNumber numberWithBool: NO] forKey: @"excludeSource"];
        [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
    }
}

/**
 * Allow zooming the graph with a pinch gesture on a trackpad.
 */
-(void)magnifyWithEvent: (NSEvent*)event
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    CGFloat relativeScale = [event magnification];
    
    CPTXYPlotSpace* plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble];
    [parameters setObject: location forKey: @"plotXLocation"];
    NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble * (1 - relativeScale)];
    [parameters setObject: range forKey: @"plotXRange"];
    [parameters setObject: [NSNumber numberWithBool: NO] forKey: @"excludeSource"];
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
}

- (void)mouseMoved: (NSEvent *)theEvent
{
    [super mouseMoved: theEvent];
    
    NSPoint location = [theEvent locationInWindow];
    //mainIndicatorLine.axisConstraints = [CPTConstraints constraintWithLowerOffset: location.x];
}

@end;

@implementation AccountRepWindowController

@synthesize firstDate;
@synthesize fromDate;
@synthesize toDate;

/**
 * Returns the first (earliest) date in the data, which serves as the reference data to which
 * all other dates are compared (to create a time distance in seconds).
 * If we have no data then the current date is used instead.
 */
-(NSDate*)referenceDate
{
    if ([dates count] > 0)
        return [[dates objectAtIndex: 0] highDate];
    return [NSDate date];
}

-(void)setupShadowForPlot: (CPTPlot*) plot
{
    plot.shadowColor = CGColorCreateGenericGray(0, 1);
    plot.shadowRadius = 2.0;
    plot.shadowOffset = CGSizeMake(1, -1);
    plot.shadowOpacity = 0.75;
}

-(id)init
{
    self = [super init ];
    if(self == nil) return nil;
    
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
    
    [super dealloc];
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
    
    timeFormatter.referenceDate = [self referenceDate];
    x.labelFormatter = timeFormatter;
    
    textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor colorWithComponentRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 1];
    textStyle.fontName = @"LucidaGrande";
    textStyle.fontSize = 10.0;
    x.labelTextStyle = textStyle;
    
    CPTXYAxis* y = axisSet.yAxis;
    y.labelTextStyle = textStyle;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    
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
    mainIndicatorLine.labelingPolicy = CPTAxisLabelingPolicyEqualDivisions;
    mainIndicatorLine.separateLayers = NO;
    mainIndicatorLine.preferredNumberOfMajorTicks = 6;
    mainIndicatorLine.minorTicksPerInterval = 0;
    mainIndicatorLine.tickDirection = CPTSignPositive;
    mainIndicatorLine.axisLineStyle = lineStyle;
    mainIndicatorLine.majorTickLength = 6.0;
    mainIndicatorLine.majorTickLineStyle = lineStyle;
    
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
    
    [self setupTurnoversPlot];
}

-(CPTScatterPlot*)createScatterPlotWithFill: (CPTFill*)fill
{
    CPTScatterPlot* linePlot = [[[CPTScatterPlot alloc] init] autorelease];
    linePlot.cachePrecision = CPTPlotCachePrecisionDecimal;
    linePlot.alignsPointsToPixels = YES;
    linePlot.dataLineStyle = nil;
    linePlot.interpolation = CPTScatterPlotInterpolationHistogram;
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
    barPlot.barWidth = CPTDecimalFromFloat(15);
    barPlot.barCornerRadius = 3.0f;
    barPlot.barsAreHorizontal = NO;
    barPlot.baseValue = CPTDecimalFromInt(0);
    barPlot.alignsPointsToPixels = YES;
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
    ShortDate* startDate = [ShortDate dateWithDate: [self referenceDate]];
    int totalDays = (count > 0) ? [startDate daysToDate: [dates lastObject]] : 0;
    
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
    formatter.referenceDate = [self referenceDate];
    
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
    
    ShortDate* startDate = [ShortDate dateWithDate: [self referenceDate]];
    int totalDays = (count > 0) ? [startDate daysToDate: [dates lastObject]] : 0;
    
    // Set the available plot space depending on the min, max and day values we found. Extend both range by a few precent for more appeal.
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
        if (fmod(maxValue, 2) != 0) {
            maxValue++; //
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

- (void)graphLayoutChanged: (NSNotification*)notification
{
    if ([[notification name] isEqualToString: PecuniaGraphLayoutChangeNotification])
    {
        NSDictionary* parameters = [notification userInfo];
        NSNumber* location = [parameters objectForKey: @"plotXLocation"];
        NSNumber* range = [parameters objectForKey: @"plotXRange"];
        NSNumber* lowRange = [NSNumber numberWithDouble: oneDay * 15];
        if ([range compare: lowRange] == NSOrderedAscending)
            range = lowRange;
        BOOL excludeSource = [[parameters objectForKey: @"excludeSource"] boolValue];
        
        // Apply new plot location and range to all relevant graphs.
        CPTXYPlotSpace* sourcePlotSpace = [notification object];
        
        CPTXYPlotSpace* plotSpace = (id)mainGraph.defaultPlotSpace;
        if (!excludeSource || plotSpace != sourcePlotSpace)
            [self applyRangeLocationToPlotSpace: plotSpace location: location range: range];
        
        plotSpace = (id)turnoversGraph.defaultPlotSpace;
        if (!excludeSource || plotSpace != sourcePlotSpace)
            [self applyRangeLocationToPlotSpace: plotSpace location: location range: range];
    }
}

#pragma mark -
#pragma mark Plot Delegate Methods

-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)proposedDisplacementVector
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    CPTXYPlotSpace* plotSpace = (id)space;
    NSNumber* location = [NSNumber numberWithDouble: plotSpace.xRange.locationDouble + proposedDisplacementVector.x];
    [parameters setObject: location forKey: @"plotXLocation"];
    NSNumber* range = [NSNumber numberWithDouble: plotSpace.xRange.lengthDouble];
    [parameters setObject: range forKey: @"plotXRange"];
    [parameters setObject: [NSNumber numberWithBool: YES] forKey: @"excludeSource"];
    [center postNotificationName: PecuniaGraphLayoutChangeNotification object: plotSpace userInfo: parameters];
    
    return proposedDisplacementVector;
}

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
        ShortDate* startDate = [ShortDate dateWithDate: [self referenceDate]];
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
    
    NSDecimalNumber *zero = [NSDecimalNumber zero ];
    //	[balanceColor release ];
    if([balance compare: zero ] == NSOrderedAscending) [self setValue: [NSColor redColor ] forKey: @"balanceColor" ]; 
    else [self setValue: [NSColor colorWithCalibratedRed:0.0 green:0.78 blue:0.0 alpha:1.0 ] forKey: @"balanceColor" ];
    
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

-(void)terminate
{
    [accountsView saveLayout ];
}

@end

