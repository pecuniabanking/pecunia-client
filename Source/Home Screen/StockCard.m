/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import <CorePlot/CorePlot.h>

#import "StockCard.h"
#import "YahooStockData.h"
#import "PreferenceController.h"
#import "GraphicsAdditions.h"
#import "PecuniaPlotTimeFormatter.h"

typedef enum {
    StocksIntervalIntraday,
    StocksIntervalOneWeek,
    StocksIntervalOneMonth,
    StocksIntervalOneQuarter,
    StocksIntervalOneYear,
    StocksIntervalThreeYears,
    StocksIntervalAllTime
} StocksTimeInterval;

@interface StockGraph : CPTGraphHostingView  <CPTPlotDataSource>
{
@private
    CPTXYGraph *graph;

    NSString *name;
    CGFloat price;
    CGFloat change;
    CGFloat changePercent;
    NSString *currency;
    NSString *exchange; // The place where this value is traded.
    CGFloat high;
    CGFloat low;
    CGFloat open;
    NSString *marketCap; // Preformatted value.

    time_t timeOffset;
    time_t marketCloseTime;
    time_t marketOpenTime;

    NSUInteger count;
    double *timePoints;
    double *stockValues;

    NSTimer *queryTimer;
    CPTTextLayer *priceTextLayer;
    NSImageView *closedView;
    NSProgressIndicator *progressIndicator;

    NSUInteger noChangeCounter;
    BOOL firstTimeUpdate;
    BOOL marketIsOpen;

    BOOL forceUpdate;
    BOOL updatePending;
}

@property (nonatomic, assign) StocksTimeInterval interval;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, strong) NSColor *color;

@end

@implementation StockGraph

@synthesize interval;
@synthesize color;
@synthesize symbol;

- (id)initWithFrame: (NSRect)frame
             symbol: (NSString *)aSymbol
    initialInterval: (StocksTimeInterval)iInterval
              color: (NSColor *)graphColor
{
    self = [super initWithFrame: frame];
    if (self) {
        currency = @"EUR";
        firstTimeUpdate = YES;
        marketIsOpen = YES; // Assume open markets. Will be updated on first data arrival.
        color = graphColor;
        symbol = aSymbol;
        interval = iInterval;

        progressIndicator = [[NSProgressIndicator alloc] initWithFrame: NSMakeRect(-5, 10, 16, 16)];
        [progressIndicator setControlSize: NSSmallControlSize];
        progressIndicator.usesThreadedAnimation = NO;
        progressIndicator.style = NSProgressIndicatorSpinningStyle;
        [progressIndicator setHidden: YES];
        [self addSubview: progressIndicator];

        [self setupGraph];
        [self updateTimer];
    }

    return self;
}

- (void)dealloc
{
    [queryTimer invalidate];
    free(timePoints);
    free(stockValues);
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setupGraph
{
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame : NSRectToCGRect(self.bounds)];
    graph.geometryFlipped = YES;
    graph.opacity = 0;
    self.hostedGraph = graph;

    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;

    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(35)];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;

    // Graph padding
    graph.paddingLeft = 10;
    graph.paddingTop = 5;
    graph.paddingRight = 0;
    graph.paddingBottom = 0;
    graph.fill = nil;

    CPTPlotAreaFrame *frame = graph.plotAreaFrame;
    frame.paddingLeft = 35;
    frame.paddingRight = 10;
    frame.paddingTop = 30;
    frame.paddingBottom = 15.5;

    // Initially show no grid/axes.
    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.majorGridLineStyle = nil;
    x.axisLineStyle = nil;
    x.labelTextStyle = nil;

    CPTXYAxis *y = axisSet.yAxis;
    y.labelTextStyle = nil;
    y.minorTicksPerInterval = 0;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;

    y.majorGridLineStyle = nil;
    y.minorGridLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = nil;

    [self updatePlot];

}

- (void)updatePlot
{
    [graph removePlotWithIdentifier: @"stockPlot"];
    
    CGColorRef  gradientHighColor = CGColorCreateFromNSColor([color colorWithAlphaComponent: 0.2]);
    CGColorRef  gradientLowColor = CGColorCreateFromNSColor([color colorWithAlphaComponent: 0.3]);
    CPTGradient *gradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                        endingColor: [CPTColor colorWithCGColor: gradientLowColor]
                             ];
    CGColorRelease(gradientHighColor);
    CGColorRelease(gradientLowColor);

    gradient.angle = -90.0;
    CPTFill *positiveGradientFill = [CPTFill fillWithGradient: gradient];

    CPTScatterPlot *linePlot = [[CPTScatterPlot alloc] init];
    linePlot.alignsPointsToPixels = YES;

    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor = [CPTColor colorWithComponentRed: color.redComponent
                                                    green: color.greenComponent
                                                     blue: color.blueComponent
                                                    alpha: color.alphaComponent * 0.6];
    linePlot.dataLineStyle = lineStyle;
    linePlot.interpolation = CPTScatterPlotInterpolationLinear;

    linePlot.areaFill = positiveGradientFill;
    linePlot.areaBaseValue = CPTDecimalFromInt(0);

    linePlot.delegate = self;
    linePlot.dataSource = self;

    CPTMutableTextStyle *labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.color = [CPTColor blackColor];
    linePlot.labelTextStyle = labelTextStyle;

    linePlot.identifier = @"stockPlot";

    [graph addPlot: linePlot];
}

/**
 * Creating the graph's title is a bit complicated due to various formats. So it's moved to an own
 * function.
 */
- (void)updateGraphTitle
{
    NSDictionary *attributes;
    NSAttributedString *temp;

    if (firstTimeUpdate) {
        attributes = @{NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.388 green: 0.382 blue: 0.363 alpha: 1.000],
                       NSFontAttributeName: [NSFont fontWithName: @"HelveticaNeue-Bold" size: 14]};

        NSAttributedString *title = [[NSAttributedString alloc] initWithString: name attributes: attributes];

        graph.attributedTitle = title;
        graph.titlePlotAreaFrameAnchor = CPTRectAnchorTopLeft;
        graph.titleDisplacement = CGPointMake(5, 0);
    }

    // For the right aligned text we need a separate annotation.
    NSMutableAttributedString *annotationString = [[NSMutableAttributedString alloc] init];
    NSColor *textColor = [NSColor colorWithCalibratedRed: 0.582 green: 0.572 blue: 0.544 alpha: 1.000];
    if (change < 0) {
        textColor = [NSColor applicationColorForKey: @"Negative Cash"];
    }
    attributes = @{NSForegroundColorAttributeName: textColor,
                   NSFontAttributeName: [NSFont fontWithName: @"HelveticaNeue-Bold" size: 10]};
    temp = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%.2f (%.2f%%)   ", change, changePercent] attributes: attributes];
    [annotationString appendAttributedString: temp];

    attributes = @{NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.388 green: 0.382 blue: 0.363 alpha: 1.000],
                   NSFontAttributeName: [NSFont fontWithName: @"HelveticaNeue-Bold" size: 14]};
    temp = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%.2f ", price] attributes: attributes];

    [annotationString appendAttributedString: temp];

    attributes = @{NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.582 green: 0.572 blue: 0.544 alpha: 1.000],
                   NSFontAttributeName: [NSFont fontWithName: @"HelveticaNeue-Bold" size: 10]};
    temp = [[NSAttributedString alloc] initWithString: currency attributes: attributes];
    [annotationString appendAttributedString: temp];

    if (priceTextLayer == nil) {
        CPTLayerAnnotation *newTitleAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer: graph.plotAreaFrame];
        priceTextLayer = [[CPTTextLayer alloc] init];
        newTitleAnnotation.contentLayer = priceTextLayer;
        newTitleAnnotation.rectAnchor = CPTRectAnchorTopRight;
        newTitleAnnotation.displacement = CGPointMake(-80, -10);
        [graph addAnnotation: newTitleAnnotation];
    }
    priceTextLayer.attributedText = annotationString;
}

- (void)setInterval: (StocksTimeInterval)newInterval
{
    interval = newInterval;
    forceUpdate = YES;
    count = 0;

    // Hide close sign if not in intraday mode.
    [closedView.animator setHidden: interval != StocksIntervalIntraday];
    [self updateTimer];
}

- (void)setSymbol: (NSString *)newSymbol
{
    symbol = [newSymbol copy];
    forceUpdate = YES;
    count = 0;
    firstTimeUpdate = YES;

    // Hide graph and closed sign (if they are visible). If a valid symbol was set it will be shown again
    // when new results arrive.
    if (graph.opacity > 0) {
        CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath: @"opacity"];
        fadeOut.fromValue = [NSNumber numberWithFloat: 1.0];
        fadeOut.toValue = [NSNumber numberWithFloat: 0.0];
        fadeOut.duration = 0.5;
        fadeOut.repeatCount = 1;
        [graph addAnimation: fadeOut forKey: nil];
        graph.opacity = 0;

        [closedView.animator setHidden: YES];
    }

    [self updateTimer];
}

- (void)setColor: (NSColor *)newColor
{
    color = newColor;
    [self updatePlot];
}

- (void)updateTimer
{
    // Stop all timers if we have no symbol to read.
    if (interval == StocksIntervalIntraday && symbol.length > 0) {
        if (queryTimer != nil) {
            // If there's already a timer then it is the one shot timer set after
            // market close.
            [queryTimer invalidate];
        }

        if (!marketIsOpen && marketOpenTime > 0) {
            // If markets are closed schedule a timer for market start.
            // Let it recheck once every minute if the markets did not start at that time.
            // If we are behind market close then schedule for the following day.
            time_t startTime = marketOpenTime;
            NSDate *now = [NSDate date];
            if (now.timeIntervalSince1970 > marketCloseTime) {
                struct tm *time = localtime(&marketOpenTime);
                time->tm_mday++;
                startTime = mktime(time);
            }
            queryTimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSince1970: startTime]
                                                  interval: 60
                                                    target: self
                                                  selector: @selector(onTimer:)
                                                  userInfo: nil
                                                   repeats: YES];
            [[NSRunLoop mainRunLoop] addTimer: queryTimer forMode: NSDefaultRunLoopMode];
        } else {
            queryTimer = [NSTimer scheduledTimerWithTimeInterval: 15
                                                          target: self
                                                        selector: @selector(onTimer:)
                                                        userInfo: nil
                                                         repeats: YES];
        }
        
        // Manually trigger first run.
        [self onTimer: queryTimer];
    } else {
        if (queryTimer != nil) {
            [queryTimer invalidate];
            queryTimer = nil;
        }
        if (symbol.length > 0) {
            [self onTimer: nil]; // One shot sync.
        }
    }
}

- (void)startProgressIndicator
{
    [progressIndicator.animator setHidden: NO];
    [progressIndicator startAnimation: self];
}

- (void)stopProgressIndicator
{
    [progressIndicator stopAnimation: self];
    [progressIndicator.animator setHidden: YES];

    // We are done with the current query. Run another one if we missed intermediate requests.
    if (updatePending) {
        updatePending = NO;
        [self onTimer: nil];
    }
}

- (void)onTimer: (id)timer
{
    // If the progress indicator is visible then we already run a query.
    // Take a note of that and run onTimer again after finishing the current run.
    if (!progressIndicator.isHidden) {
        updatePending = YES;
    } else {
        [self startProgressIndicator];
        [YahooStockData quotesForSymbols: @[symbol]
                       completionHandler: ^(NSDictionary* values, NSError* error) {
                           [self checkForChanges: values];
                       }
         ];
    }
}

- (void)checkForChanges: (NSDictionary *)values
{
    NSDictionary *quote = values[@"response"][@"result"][@"list"][@"quote"];

    double currentPrice = [quote[@"price"][@"text"] floatValue];
    BOOL doReadTicker = forceUpdate || (price != currentPrice);

    if (!doReadTicker) {
        ++noChangeCounter;
        if (marketIsOpen && noChangeCounter > 4) {
            // If there were no changes for over a minute and we are still assuming the market is
            // open we might just have gone past market close. So recheck that.
            doReadTicker = YES;
        }
    }

    if (doReadTicker) {
        forceUpdate = NO;
        noChangeCounter = 0;
        price = currentPrice;
        name = quote[@"issuername"][@"text"];
        if (name.length > 15) {
            name = [NSString stringWithFormat: @"%@...", [name substringWithRange: NSMakeRange(0, 15)]];
        } else {
            if (name.length == 0) {
                name = NSLocalizedString(@"AP19", nil);
            }
        }
        change = [quote[@"change"][@"text"] floatValue];
        changePercent = [quote[@"changepercent"][@"text"] floatValue];
        currency = quote[@"currency"][@"text"];
        if (currency.length == 0) {
            currency = @"EUR";
        }
        exchange = quote[@"exchange"][@"text"];
        if (exchange.length == 0) {
            exchange = @"---";
        }
        high = [quote[@"high"][@"text"] floatValue];
        low = [quote[@"low"][@"text"] floatValue];
        open = [quote[@"open"][@"text"] floatValue];
        marketCap = quote[@"marketcap"][@"text"];
        if (marketCap.length == 0) {
            marketCap = @"---";
        }

        [self updateGraphTitle];

        NSString *intervalString;
        switch (interval) {
            case StocksIntervalOneWeek:
                intervalString = @"5d";
                break;

            case StocksIntervalOneMonth:
                intervalString = @"1m";
                break;

            case StocksIntervalOneQuarter:
                intervalString = @"3m";
                break;

            case StocksIntervalOneYear:
                intervalString = @"1y";
                break;

            case StocksIntervalThreeYears:
                intervalString = @"3y";
                break;

            case StocksIntervalAllTime:
                intervalString = @"20y";
                break;

            default:
                intervalString = @"1d";
        }

        [YahooStockData tickerValuesForSymbols: @[symbol]
                                      interval: intervalString
                             completionHandler: ^(NSDictionary* values, NSError* error) {
                                 [self prepareDataForPlot: values];
                             }
         ];
    } else {
        [self stopProgressIndicator];
    }
}

- (void)prepareDataForPlot: (NSDictionary *)values
{
    // For no appearent reason it can happen that an update contains less datapoints
    // than a previous request. Since previous prices are likely not to change we just ignore
    // such updates.
    NSDictionary *list = values[@"response"][@"result"][@"list"];
    NSUInteger newCount = [list[@"count"] intValue];
    if (newCount > count) {
        count = newCount;

        int timestamp = [values[@"response"][@"result"][@"timestamp"] intValue];
        free(timePoints);
        timePoints = nil;

        free(stockValues);
        stockValues = nil;

        // Times in the dictionaries are Unix timestamps and we keep it at that.
        // The label formatter will take care for creating the right display strings.
        if (count > 0) {

            timeOffset = [list[@"meta"][@"gmtoffset"][@"text"] intValue];
            marketCloseTime = [list[@"meta"][@"marketclose"][@"text"] intValue];
            marketOpenTime = [list[@"meta"][@"marketopen"][@"text"] intValue];

            if (interval == StocksIntervalIntraday) {
                if (timestamp < marketOpenTime || timestamp > marketCloseTime) {
                    if (marketIsOpen) {
                        [self marketClosed];
                    }
                } else {
                    if (!marketIsOpen) {
                        [self marketOpened];
                    }
                }
            }

            CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
            CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(marketOpenTime)
                                                                   length: CPTDecimalFromDouble(marketCloseTime - marketOpenTime)];
            plotSpace.globalXRange = plotRange;
            plotSpace.xRange = plotRange;

            CPTXYAxisSet *axisSet = (id)graph.axisSet;
            [self updateAxis: axisSet.xAxis];

            if (count > 0) {
                double min = 1e100;
                double max = -1e100;

                timePoints = malloc(count * sizeof(double));
                stockValues = malloc(count * sizeof(double));

                NSArray *points = list[@"point"];
                for (NSUInteger i = 0; i < count; ++i) {
                    NSDictionary *point = points[i];
                    timePoints[i] = [point[@"timestamp"] intValue];
                    stockValues[i] = [point[@"close"] floatValue];

                    if (stockValues[i] < min) {
                        min = stockValues[i];
                    }
                    if (stockValues[i] > max) {
                        max = stockValues[i];
                    }
                }

                min *= 0.999; // Make min a small amount smaller to have a little offset from the base line.
                CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(min)
                                                                       length: CPTDecimalFromDouble(max - min)];
                plotSpace.globalYRange = plotRange;
                plotSpace.yRange = plotRange;
                
            }
        }
        [graph reloadData];

        // If the closed indicator is hidden but the markets are closed then reshow it.
        // It means we hided it when switching symbols.
        if (interval == StocksIntervalIntraday && !marketIsOpen && closedView.isHidden) {
            [closedView.animator setHidden: NO];
        }
    }

    [self stopProgressIndicator];

    if (firstTimeUpdate) {
        [self setUpAxes];

        firstTimeUpdate = NO;

        CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath: @"opacity"];
        fadeIn.fromValue = [NSNumber numberWithFloat: 0.0];
        fadeIn.toValue = [NSNumber numberWithFloat: 1.0];
        fadeIn.duration = 0.5;
        fadeIn.repeatCount = 1;
        [graph addAnimation: fadeIn forKey: nil];
        graph.opacity = 1;
    }
}

- (void)updateAxis: (CPTXYAxis *)axis
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    
    int calendarUnit;
    NSMutableSet *majorTickLocations = [NSMutableSet set];
    
    struct tm *time = localtime(&marketCloseTime);
    time->tm_min = 0;
    time->tm_sec = 0;
    switch (interval) {
        case StocksIntervalOneWeek:
            calendarUnit = NSDayCalendarUnit;

            time->tm_hour = 0;
            for (int i = 0; i < 7; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_mday--; // Might underflow a month. mktime handles this automatically.
            }
            break;

        case StocksIntervalOneMonth:
            calendarUnit = NSDayCalendarUnit;

            time->tm_hour = 0;
            for (int i = 0; i < 10; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_mday -= 3;
            }
            break;
            
        case StocksIntervalOneQuarter:
            calendarUnit = NSMonthCalendarUnit;

            time->tm_hour = 0;
            time->tm_mday = 1;
            for (int i = 0; i < 3; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_mon--;
            }
            break;
            
        case StocksIntervalOneYear:
            calendarUnit = NSMonthCalendarUnit;

            time->tm_hour = 0;
            time->tm_mday = 1;
            for (int i = 0; i < 12; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_mon--;
            }
            break;
            
        case StocksIntervalThreeYears:
            calendarUnit = NSYearCalendarUnit;

            time->tm_hour = 0;
            time->tm_mday = 1;
            time->tm_mon = 1;
            for (int i = 0; i < 3; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_year--;
            }
            break;

        case StocksIntervalAllTime:
            calendarUnit = NSYearCalendarUnit;

            time->tm_hour = 0;
            time->tm_mday = 1;
            time->tm_mon = 1;
            for (int i = 0; i < 10; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_year -= 2;
            }
            break;

        default:
            calendarUnit = NSHourCalendarUnit;

            for (int i = 0; i < 24; i++) {
                time_t timePoint = mktime(time);
                [majorTickLocations addObject: [NSDecimalNumber numberWithUnsignedInteger: timePoint]];
                time->tm_hour--;
            }
            break;
    }

    StocksPlotTimeFormatter *timeFormatter = [[StocksPlotTimeFormatter alloc] initWithDateFormatter: dateFormatter
                                                                                       calendarUnit: calendarUnit];
    axis.labelFormatter = timeFormatter;

    if (count > 0) {
        axis.labelingPolicy = CPTAxisLabelingPolicyLocationsProvided;
        axis.majorTickLocations = majorTickLocations;
    } else {
        axis.labelingPolicy = CPTAxisLabelingPolicyNone;
    }
}

- (void)setUpAxes
{
    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.minorTicksPerInterval = 0;
    x.labelOffset = -4;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];

    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithComponentRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 0.125];
    x.majorGridLineStyle = lineStyle;
    lineStyle.lineColor = [CPTColor colorWithComponentRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 0.5];
    x.axisLineStyle = lineStyle;

    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor colorWithComponentRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 0.5];
    textStyle.fontName = @"HelveticaNeue-Bold";
    textStyle.fontSize = 9.5;
    x.labelTextStyle = textStyle;

    CPTXYAxis *y = axisSet.yAxis;
    y.labelTextStyle = textStyle;
    y.minorTicksPerInterval = 0;
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    y.preferredNumberOfMajorTicks = 4;

    y.majorGridLineStyle = nil;
    y.minorGridLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = lineStyle;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.usesSignificantDigits = YES;
    formatter.minimumFractionDigits = 2;
    formatter.numberStyle = kCFNumberFormatterNoStyle;
    formatter.zeroSymbol = @"0";
    y.labelFormatter = formatter;
}

/**
 * Market just opened. Update the UI.
 */
- (void)marketOpened
{
    marketIsOpen = YES;
    [closedView removeFromSuperview];

    // Replace the market start timer by the regular repeating timer.
    [self updateTimer];
}

/**
 * Market just closed or was closed when we queried the first time. Show our hint annotation.
 */
- (void)marketClosed
{
    marketIsOpen = NO;
    if (closedView == nil) {
        int x = NSMidX(self.bounds) - 25;
        int y = NSMidY(self.bounds) - 23;
        closedView = [[NSImageView alloc] initWithFrame: NSMakeRect(x, y, 80, 80)];
        closedView.imageScaling = NSImageScaleNone;
        closedView.image = [NSImage imageNamed: @"closed-sign"];
        closedView.toolTip = NSLocalizedString(@"AP951", nil);
    }
    [self addSubview: closedView];

    // Remove the standard timer and set a timer for market open if we are in
    // intraday report mode.
    [self updateTimer];
}

#pragma mark -
#pragma mark Plot Data Source Methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot *)plot
{
    return count;
}

- (double *)doublesForPlot: (CPTPlot *)plot field: (NSUInteger)fieldEnum recordIndexRange: (NSRange)indexRange
{
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return &timePoints[indexRange.location];

        case CPTScatterPlotFieldY:
            return &stockValues[indexRange.location];
            
        default:
            return nil;
    }
}

- (CPTLayer *)dataLabelForPlot: (CPTPlot *)plot recordIndex: (NSUInteger)index
{
    return (id)[NSNull null]; // Don't show any data label.
}

@end

#pragma mark - StockCard implementation

@interface StockCard ()
{
    NSSegmentedControl *intervalSelector;
    NSMutableArray *graphs;
}

@end

@implementation StockCard

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        [self setupUI];
    }

    return self;
}

- (void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSUInteger i = 1; i <= 3; i++) {
        NSString *symbolKey = [NSString stringWithFormat: @"stocksSymbol%li", i];
        NSString *stockSymbol = [defaults stringForKey: symbolKey];
        if (stockSymbol.length > 0) {
            NSString *colorKey = [NSString stringWithFormat: @"stocksSymbolColor%li", i];
            [defaults removeObserver: self forKeyPath: symbolKey];
            [defaults removeObserver: self forKeyPath: colorKey];
        }
    }
}

- (void)setupUI
{
    NSRect frame = NSMakeRect(0, 0, 181, 13);
    intervalSelector = [[NSSegmentedControl alloc] initWithFrame: frame];
    intervalSelector.segmentStyle = NSSegmentStyleRoundRect;
    intervalSelector.segmentCount = 7;
    [intervalSelector.cell setControlSize: NSMiniControlSize];
    intervalSelector.font = [NSFont controlContentFontOfSize: 8.5];
    [intervalSelector setLabel: NSLocalizedString(@"AP956", nil) forSegment: 0];
    [intervalSelector setLabel: NSLocalizedString(@"AP957", nil) forSegment: 1];
    [intervalSelector setLabel: NSLocalizedString(@"AP958", nil) forSegment: 2];
    [intervalSelector setLabel: NSLocalizedString(@"AP959", nil) forSegment: 3];
    [intervalSelector setLabel: NSLocalizedString(@"AP960", nil) forSegment: 4];
    [intervalSelector setLabel: NSLocalizedString(@"AP961", nil) forSegment: 5];
    [intervalSelector setLabel: NSLocalizedString(@"AP962", nil) forSegment: 6];
    [intervalSelector sizeToFit];
    [self addSubview: intervalSelector];

    intervalSelector.selectedSegment = 0;
    intervalSelector.target = self;
    intervalSelector.action = @selector(intervalChanged:);

    // TODO: if there was a network problem quotes might be nil or empty. Show an indicator in the UI for that.
    graphs = [NSMutableArray arrayWithCapacity: 3];

    NSColor *graphColor;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    StocksTimeInterval initialInterval = StocksIntervalIntraday;
    if ([defaults objectForKey: @"stocksInterval"] != nil) {
        initialInterval = [defaults integerForKey: @"stocksInterval"];
    }
    intervalSelector.selectedSegment = initialInterval;

    for (NSUInteger i = 1; i <= 3; i++) {
        NSString *symbolKey = [NSString stringWithFormat: @"stocksSymbol%li", i];
        NSString *stockSymbol = [defaults stringForKey: symbolKey];
        //if (stockSymbol.length > 0) create hidden graphs for empty symbols
        {
            NSString *colorKey = [NSString stringWithFormat: @"stocksSymbolColor%li", i];
            [defaults addObserver: self forKeyPath: symbolKey options: 0 context: nil];
            [defaults addObserver: self forKeyPath: colorKey options: 0 context: nil];

            id data = [defaults objectForKey: colorKey];
            if (data != nil) {
                graphColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData: data];
            } else {
                graphColor = [NSColor nextDefaultStockGraphColor];
            }
            StockGraph *graph = [[StockGraph alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                                           symbol: stockSymbol
                                                  initialInterval: initialInterval
                                                            color: graphColor];
            [graphs addObject: graph];
            [self addSubview: graph];
            
        }
    }
}

- (void)intervalChanged: (id)sender
{
    StocksTimeInterval interval;
    switch (intervalSelector.selectedSegment) {
        case 0:
            interval = StocksIntervalIntraday;
            break;
        case 1:
            interval = StocksIntervalOneWeek;
            break;
        case 2:
            interval = StocksIntervalOneMonth;
            break;
        case 3:
            interval = StocksIntervalOneQuarter;
            break;
        case 4:
            interval = StocksIntervalOneYear;
            break;
        case 5:
            interval = StocksIntervalThreeYears;
            break;
        case 6:
            interval = StocksIntervalAllTime;
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger: interval forKey: @"stocksInterval"];

    for (StockGraph *graph in graphs) {
       graph.interval = interval;
    }

}

/**
 * Layouts all charts in a column format.
 */
- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    NSRect frame = self.bounds;
    frame.size.width -= 40;
    frame.size.height = (int)(frame.size.height - 55) / 3;
    frame.origin.x = 15;
    frame.origin.y = 35;

    for (NSView *child in self.subviews) {
        if ([child isKindOfClass: [NSSegmentedControl class]]) {
            NSPoint controlLocation = NSMakePoint(NSMaxX(self.bounds) - NSWidth(child.bounds) - 15, 13);
            child.frameOrigin = controlLocation;
        } else {
            child.frame = frame;
            frame.origin.y += frame.size.height;
        }
    }
}

#pragma mark - Bindings, KVO and KVC

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([keyPath isEqualToString: @"stocksSymbol1"]) {
        if (graphs.count > 0) {
            [graphs[0] setSymbol: [defaults stringForKey: keyPath]];
        }
        return;
    }
    if ([keyPath isEqualToString: @"stocksSymbol2"]) {
        if (graphs.count > 1) {
            [graphs[1] setSymbol: [defaults stringForKey: keyPath]];
        }
        return;
    }
    if ([keyPath isEqualToString: @"stocksSymbol3"]) {
        if (graphs.count > 2) {
            [graphs[2] setSymbol: [defaults stringForKey: keyPath]];
        }
        return;
    }

    // Colors.
    id data = [defaults objectForKey: keyPath];
    if (data != nil) {
        if ([keyPath isEqualToString: @"stocksSymbolColor1"]) {
            if (graphs.count > 0) {
                NSColor *graphColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData: data];
                [graphs[0] setColor: graphColor];
            }
            return;
        }
        if ([keyPath isEqualToString: @"stocksSymbolColor2"]) {
            if (graphs.count > 1) {
                NSColor *graphColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData: data];
                [graphs[1] setColor: graphColor];
            }
            return;
        }
        if ([keyPath isEqualToString: @"stocksSymbolColor3"]) {
            if (graphs.count > 2) {
                NSColor *graphColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData: data];
                [graphs[2] setColor: graphColor];
            }
            return;
        }
    }
}

@end
