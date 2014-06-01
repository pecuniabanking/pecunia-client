/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import "Category.h"
#import "ShortDate.h"
#import "AssetsCard.h"

#import "NSColor+PecuniaAdditions.h"
#import "PecuniaPlotTimeFormatter.h"
#import "NSDecimalNumber+PecuniaAdditions.h"

#import "MOAssistant.h"
#import "BankingController.h"
#import "MessageLog.h"
#import "Mathematics.h"

#import "LocalSettingsController.h"

extern void *UserDefaultsBindingContext;

@interface AssetGraph : CPTGraphHostingView  <CPTPlotDataSource, CPTAnimationDelegate>
{
    @private
    CPTXYGraph *graph;

    ShortDate *referenceDate;

    // Only used if we add zooming. Otherwise constant for the entire range of data.
    ShortDate *fromDate;
    ShortDate *toDate;

    CPTTextLayer *titleLayer;

    NSUInteger count; // Number of entries in all 3 data arrays (all same size).
    double     *timePoints;
    double     *positiveBalances;
    double     *negativeBalances;
    double     *totalBalances;

    double min;
    double max;

    NSDecimalNumber *roundedLocalMinValue;
    NSDecimalNumber *roundedLocalMaxValue;

    // Temporary values for animations.
    float newMainYInterval;

    // Animations.
    CPTAnimationOperation *rangeAnimationOperation;
    CPTAnimationOperation *globalRangeAnimationOperation;

    CPTFunctionDataSource *regressionDataSource;

    NSPoint lastMouseDown;
}

@property (nonatomic, strong) Category *category;
@property NSInteger                    tag;

@end

@implementation AssetGraph

@synthesize category;

- (id)initWithFrame: (NSRect)frame category: (Category *)aCategory {
    LogEnter;

    self = [super initWithFrame: frame];
    if (self) {
        category = aCategory;
        [self setupGraph];
        [self performSelector: @selector(loadData) withObject: nil afterDelay: 0.3];
    }

    LogLeave;

    return self;
}

- (void)dealloc {
    LogEnter;

    free(timePoints);
    free(positiveBalances);
    free(negativeBalances);
    free(totalBalances);

    LogLeave;
}

- (void)prepareForShutDown {
    LogEnter;

    if (rangeAnimationOperation != nil) {
        [CPTAnimation.sharedInstance removeAnimationOperation: rangeAnimationOperation];
    }
    if (globalRangeAnimationOperation != nil) {
        [CPTAnimation.sharedInstance removeAnimationOperation: globalRangeAnimationOperation];
    }

    LogLeave;
}

- (void)setupGraph {
    LogEnter;

    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame : NSRectToCGRect(self.bounds)];
    self.hostedGraph = graph;

    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;

    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(35)];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;

    // Graph padding
    graph.paddingLeft = 0;
    graph.paddingTop = 0;
    graph.paddingRight = 0;
    graph.paddingBottom = 0;
    graph.fill = nil;

    CPTPlotAreaFrame *frame = graph.plotAreaFrame;
    frame.paddingLeft = 20;
    frame.paddingRight = 50;
    frame.paddingTop = 20;
    frame.paddingBottom = 20;

    [self setupPlot];
    [self setUpAxes];

    LogLeave;
}

static CGFloat factors[3];

double trend(double x) {
    return factors[0] + x * factors[1] + x * x * factors[2]; // Square trend function.
}

- (void)setupPlot {
    LogEnter;

    if (category != nil) {
        CPTScatterPlot *linePlot = [CPTScatterPlot new];
        linePlot.alignsPointsToPixels = YES;

        linePlot.dataLineStyle = nil;
        linePlot.interpolation = CPTScatterPlotInterpolationStepped;
        linePlot.areaBaseValue = CPTDecimalFromInt(0);

        linePlot.delegate = self;
        linePlot.dataSource = self;

        CGColorRef color = CGColorCreateGenericGray(0, 1);
        linePlot.shadowColor = color;

        linePlot.shadowRadius = 2.0;
        linePlot.shadowOffset = CGSizeMake(2, -2);
        linePlot.shadowOpacity = 0.5;

        linePlot.identifier = @"positiveBalances";

        [graph addPlot: linePlot];

        linePlot = [CPTScatterPlot new];
        linePlot.alignsPointsToPixels = YES;

        linePlot.dataLineStyle = nil;
        linePlot.interpolation = CPTScatterPlotInterpolationStepped;
        linePlot.areaBaseValue = CPTDecimalFromInt(0);

        linePlot.delegate = self;
        linePlot.dataSource = self;

        linePlot.shadowColor = color;
        linePlot.shadowRadius = 2.0;
        linePlot.shadowOffset = CGSizeMake(2, -2);
        linePlot.shadowOpacity = 0.5;

        linePlot.identifier = @"negativeBalances";

        CGColorRelease(color);
        [graph addPlot: linePlot];

        // Regression plot.
        linePlot = [CPTScatterPlot new];
        linePlot.alignsPointsToPixels = NO;

        linePlot.interpolation = CPTScatterPlotInterpolationLinear;
        linePlot.areaFill = nil;
        linePlot.areaBaseValue = CPTDecimalFromInt(0);
        linePlot.delegate = self;
        linePlot.identifier = @"regressionPlot";

        CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle new];
        lineStyle.lineColor = CPTColor.whiteColor;

        lineStyle.lineWidth = 2;
        lineStyle.lineCap = kCGLineCapRound;
        lineStyle.dashPattern = @[@8.0f, @4.5f];
        linePlot.dataLineStyle = lineStyle;

        CPTMutableShadow *shadow = [CPTMutableShadow shadow];
        shadow.shadowColor = [CPTColor colorWithComponentRed: 0 green: 0 blue: 0 alpha: 0.75];
        shadow.shadowBlurRadius = 2.0;
        shadow.shadowOffset = CGSizeMake(0, 0);
        linePlot.shadow = shadow;

        [graph addPlot: linePlot];

        regressionDataSource = [CPTFunctionDataSource dataSourceForPlot: linePlot
                                                           withFunction: trend];
        regressionDataSource.resolution = 10;

        [self updateColors];
    }

    LogLeave;
}

- (void)setUpAxes {
    LogEnter;

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.axisLineStyle = nil; // This axis shows no axis line. We do that with a separate axis.
    x.majorTickLineStyle = nil;
    x.minorTicksPerInterval = 0;
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.preferredNumberOfMajorTicks = 10;

    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [[CPTColor blackColor] colorWithAlphaComponent: 0.3];
    textStyle.fontName = @"ArialNarrow-Bold";
    textStyle.fontSize = 10.0;
    x.labelTextStyle = textStyle;
    x.labelOffset = -1;

    // Add an axis which only draws the Y = 0 axis line (the labels stay outside).
    CPTXYAxis *zeroLineAxis = [[CPTXYAxis alloc] init];
    zeroLineAxis.majorTickLineStyle = nil;
    zeroLineAxis.coordinate = CPTCoordinateX;
    zeroLineAxis.plotSpace = graph.defaultPlotSpace;
    zeroLineAxis.minorTicksPerInterval = 0;
    zeroLineAxis.labelingPolicy = CPTAxisLabelingPolicyNone;

    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.5];
    zeroLineAxis.axisLineStyle = lineStyle;

    CPTXYAxis *y = axisSet.yAxis;
    textStyle.fontName = @"ArialNarrow-Bold";
    textStyle.color = [[CPTColor blackColor] colorWithAlphaComponent: 0.3];
    y.labelTextStyle = textStyle;
    y.axisConstraints = [CPTConstraints constraintWithUpperOffset: 0];
    y.tickDirection = CPTSignPositive;

    lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.05];
    y.majorGridLineStyle = lineStyle;
    x.majorGridLineStyle = lineStyle;

    y.minorGridLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = nil;
    y.minorTicksPerInterval = 0;

    axisSet.axes = @[x, zeroLineAxis, y];

    // Graph title preparation. The actual title is set in updateGraphTitle.
    CPTLayerAnnotation *titleAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer: graph.plotAreaFrame];
    titleLayer = [[CPTTextLayer alloc] init];
    titleAnnotation.contentLayer = titleLayer;
    titleAnnotation.rectAnchor = CPTRectAnchorLeft;
    titleAnnotation.rotation = pi / 2;
    [graph addAnnotation: titleAnnotation];
}

- (void)updateGraphTitle {
    LogEnter;

    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.388 green: 0.382 blue: 0.363 alpha: 1.000],
        NSFontAttributeName: [NSFont fontWithName: @"HelveticaNeue-Bold" size: 12]
    };

    titleLayer.attributedText = [[NSAttributedString alloc] initWithString: category.localName
                                                                attributes: attributes];

    LogLeave;
}

- (void)updateGraph {
    LogEnter;

    [self updateGraphTitle];

    int tickCount = 8; // For months.
    int totalUnits = (count > 1) ? timePoints[count - 2] + 1 : 0;
    if (totalUnits < tickCount) {
        totalUnits = tickCount;
    }

    // Set the available plot space depending on the min, max and day values we found.
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;

    // Horizontal range.
    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(totalUnits)];
    plotSpace.globalXRange = plotRange;

    int from = [self distanceFromDate: referenceDate toDate: fromDate];
    int to = [self distanceFromDate: referenceDate toDate: toDate];
    if (to - from < tickCount) {
        to = from + 8;
    }
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromInt(from) length: CPTDecimalFromInt(to - from)];

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.preferredNumberOfMajorTicks = tickCount;

    // Recreate the time formatter to apply the new reference date. Just setting the date on the existing
    // formatter is not enough.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;

    PecuniaPlotTimeFormatter *timeFormatter = [[PecuniaPlotTimeFormatter alloc] initWithDateFormatter: dateFormatter
                                                                                         calendarUnit: NSCalendarUnitMonth];

    timeFormatter.referenceDate = [referenceDate lowDate];
    x.labelFormatter = timeFormatter;

    // The currency of the main category can change so update the y axis label formatter as well.
    NSString          *currency = (category == nil) ? @"EUR" : category.currency;
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.usesSignificantDigits = YES;
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.currencyCode = currency;
    currencyFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", currencyFormatter.currencySymbol];
    axisSet.yAxis.labelFormatter = currencyFormatter;

    LogLeave;
}

- (void)updateGraphRange {
    LogEnter;

    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    CPTXYAxisSet *axisSet = (id)graph.axisSet;

    // Set the ticks (and so the lables) to the side with less values.
    if (fabs(max) >= fabs(min)) {
        axisSet.xAxis.tickDirection = CPTSignNegative;
        axisSet.xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];
    } else {
        axisSet.xAxis.tickDirection = CPTSignPositive;
        axisSet.xAxis.axisConstraints = [CPTConstraints constraintWithUpperOffset: 0];
    }

    float animationDuration = 0.3;
    if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) != 0) {
        animationDuration = 3;
    }

    // Set the y axis ticks depending on the maximum value.
    CPTXYAxis *y = axisSet.yAxis;

    BOOL useDefault = max - min < 10;
    if (useDefault) {
        if (max - min == 0) {
            max = min + 120; // Empty set.
        } else {
            max = min + 10; // Round the range up to 10.
        }
    }
    NSDecimal decimalMinValue = CPTDecimalFromDouble(min);
    NSDecimal decimalMaxValue = CPTDecimalFromDouble(max);
    roundedLocalMinValue = [[NSDecimalNumber decimalNumberWithDecimal: decimalMinValue] roundToUpperOuter];
    if (useDefault) {
        roundedLocalMaxValue = [NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue];
    } else {
        roundedLocalMaxValue = [[NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue] roundToUpperOuter];
    }

    // Let the larger area (negative or positive) determine the size of the major tick range.
    NSDecimalNumber *minAbsolute = [roundedLocalMinValue abs];
    NSDecimalNumber *maxAbsolute = [roundedLocalMaxValue abs];
    float           interval;
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
        newMainYInterval = -1;
    } else {
        newMainYInterval = interval; // Keep this temporarily in this ivar. It is applied at the end of the animation.
    }

    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: roundedLocalMinValue.decimalValue
                                                           length: [[roundedLocalMaxValue decimalNumberBySubtracting: roundedLocalMinValue] decimalValue]];

    if (rangeAnimationOperation != nil) {
        [CPTAnimation.sharedInstance removeAnimationOperation: rangeAnimationOperation];
    }
    if (globalRangeAnimationOperation != nil) {
        [CPTAnimation.sharedInstance removeAnimationOperation: globalRangeAnimationOperation];
    }

    globalRangeAnimationOperation = [CPTAnimation animate: plotSpace
                                                 property: @"globalYRange"
                                            fromPlotRange: plotSpace.globalYRange
                                              toPlotRange: plotRange
                                                 duration: animationDuration
                                                withDelay: 0
                                           animationCurve: CPTAnimationCurveCubicInOut
                                                 delegate: self];
    rangeAnimationOperation = [CPTAnimation animate: plotSpace
                                           property: @"yRange"
                                      fromPlotRange: plotSpace.yRange
                                        toPlotRange: plotRange
                                           duration: animationDuration
                                          withDelay: 0
                                     animationCurve: CPTAnimationCurveCubicInOut
                                           delegate: self];

    LogLeave;
}

- (void)loadData {
    LogEnter;

    count = 0;
    free(timePoints);
    timePoints = nil;

    free(positiveBalances);
    positiveBalances = nil;

    free(negativeBalances);
    negativeBalances = nil;

    free(totalBalances);
    totalBalances = nil;

    min = 1e100;
    max = -1e100;

    referenceDate = [ShortDate currentDate];
    fromDate = referenceDate;
    toDate = fromDate;

    if (category != nil) {
        NSArray *dates = nil;
        NSArray *rawBalances = nil;
        NSArray *turnovers = nil;
        [category historyToDates: &dates
                        balances: &rawBalances
                   balanceCounts: &turnovers
                    withGrouping: GroupByMonths
                           sumUp: YES
                       recursive: YES];

        if (dates != nil) {
            count = dates.count + 1;

            // Convert the dates to distance units from a reference date.
            timePoints = malloc(count * sizeof(double));
            if (dates.count > 0) {
                referenceDate = dates[0];
                fromDate = dates[0];
            }

            int index = 0;
            for (ShortDate *date in dates) {
                timePoints[index++] = [referenceDate unitsToDate: date byUnit: NSCalendarUnitMonth];
            }
            timePoints[index] = timePoints[index - 1] + 1;
            toDate = [dates.lastObject dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth];

            // Convert all NSDecimalNumbers to double for better performance.
            positiveBalances = malloc(count * sizeof(double));
            negativeBalances = malloc(count * sizeof(double));
            totalBalances = malloc(count * sizeof(double));

            index = 0;
            for (NSDecimalNumber *value in rawBalances) {
                double doubleValue = value.doubleValue;
                totalBalances[index] = doubleValue;
                if (doubleValue < min) {
                    min = doubleValue;
                }

                if (doubleValue > max) {
                    max = doubleValue;
                }

                if (doubleValue < 0) {
                    positiveBalances[index] = 0;
                    negativeBalances[index] = doubleValue;
                } else {
                    positiveBalances[index] = doubleValue;
                    negativeBalances[index] = 0;
                }
                index++;
            }
            // Always start plots at y = 0;
            if (min > 0) {
                min = 0;
            }
            if (max < 0) {
                max = 0;
            }

            positiveBalances[index] = positiveBalances[index - 1];
            negativeBalances[index] = negativeBalances[index - 1];
            totalBalances[index] = totalBalances[index - 1];
        } else {
            min = 0;
            max = 100;
        }

        [Mathematics computeSquareFunctionParametersX: timePoints
                                                    y: totalBalances
                                                count: dates.count
                                               result: factors];
    }

    [graph reloadData];
    [self updateGraph];
    [self updateGraphRange];

    LogLeave;
}

- (void)setCategory: (Category *)value {
    category = value;
    [self loadData];
}

- (void)mouseDown: (NSEvent *)theEvent {
    [super mouseDown: theEvent];
    lastMouseDown = theEvent.locationInWindow;
}

- (void)mouseUp: (NSEvent *)theEvent {
    [super mouseUp: theEvent];
    NSPoint location = theEvent.locationInWindow;
    if (abs(location.x - lastMouseDown.x) < 8 && abs(location.y - lastMouseDown.y) < 8) {
        [(HomeScreenCard *)self.superview cardClicked : category];
    }
}

#pragma mark - Utility functions

- (void)updateColors {
    LogEnter;

    CGColorRef  gradientHighColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Positive Plot Gradient (high)"] colorWithAlphaComponent: 1]);
    CGColorRef  gradientLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Positive Plot Gradient (low)"] colorWithAlphaComponent: 1]);
    CPTGradient *positiveGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                                endingColor: [CPTColor colorWithCGColor: gradientLowColor]
        ];
    CGColorRelease(gradientHighColor);
    CGColorRelease(gradientLowColor);

    positiveGradient.angle = -90.0;

    CPTScatterPlot *plot = (id)[graph plotWithIdentifier : @"positiveBalances"];
    plot.areaFill = [CPTFill fillWithGradient: positiveGradient];

    gradientHighColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Negative Plot Gradient (high)"] colorWithAlphaComponent: 1]);
    gradientLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Negative Plot Gradient (low)"] colorWithAlphaComponent: 0.9]);
    CPTGradient *negativeGradient = [CPTGradient gradientWithBeginningColor: [CPTColor colorWithCGColor: gradientHighColor]
                                                                endingColor: [CPTColor colorWithCGColor: gradientLowColor]
        ];
    CGColorRelease(gradientHighColor);
    CGColorRelease(gradientLowColor);

    negativeGradient.angle = -90.0;
    plot = (id)[graph plotWithIdentifier : @"negativeBalances"];
    plot.areaFill = [CPTFill fillWithGradient: negativeGradient];

    LogLeave;
}

- (int)distanceFromDate: (ShortDate *)from toDate: (ShortDate *)to {
    return [from unitsToDate: to byUnit: NSCalendarUnitMonth];
}

- (NSDecimal)distanceAsDecimalFromDate: (ShortDate *)from toDate: (ShortDate *)to {
    return CPTDecimalFromInt([self distanceFromDate: from toDate: to]);
}

/**
 * Determines the optimal length of a major interval length for a plot depending on the
 * overall size of the range. This is a bit tricky as we want sharp and easy intervals
 * for optimal perceptibility. The given range is already rounded up to two most significant digits.
 */
- (float)intervalFromRange: (NSDecimalNumber *)range forTurnovers: (BOOL)lesserValues {
    int digitCount = [range numberOfDigits];

    NSDecimal value = [range decimalValue];
    NSDecimal hundred = [@100 decimalValue];
    if (NSDecimalCompare(&value, &hundred) == NSOrderedDescending) {
        // The range is > 100 so scale it down so it falls into that range.
        NSDecimalMultiplyByPowerOf10(&value, &value, -digitCount + 2, NSRoundDown);
    }
    double convertedValue = [[NSDecimalNumber decimalNumberWithDecimal: value] doubleValue];
    if (digitCount < 2) {
        return convertedValue <= 5 ? 2 : 4;
    }

    double base = lesserValues ? 20 : 10;
    if (convertedValue < 10) {
        return pow(base, digitCount - 1);
    }
    if (convertedValue == 10) {
        return 4 * pow(base, digitCount - 2);
    }
    if (convertedValue <= 15) {
        return 5 * pow(base, digitCount - 2);
    }
    if (convertedValue <= 45) {
        return 10 * pow(base, digitCount - 2);
    }

    return 2 * pow(base, digitCount - 1);
}

#pragma mark - Coreplot delegate methods

- (void)animationDidFinish: (CPTAnimationOperation *)operation {
    if (operation.boundObject == graph.defaultPlotSpace) {
        // Animation of the main graph vertical plot space.
        // We can now set the final interval length and tick count.
        if (newMainYInterval > 0) {
            CPTXYAxisSet *axisSet = (id)graph.axisSet;
            CPTXYAxis    *y = axisSet.yAxis;

            y.majorIntervalLength = CPTDecimalFromFloat(newMainYInterval);
            newMainYInterval = 0;
        }
    }

    if (operation == globalRangeAnimationOperation) {
        globalRangeAnimationOperation = nil;
    }
    if (operation == rangeAnimationOperation) {
        rangeAnimationOperation = nil;
    }
}

- (void)animationCancelled: (CPTAnimationOperation *)operation {
    if (operation.boundObject == graph.defaultPlotSpace) {
        // Animation of the main graph vertical plot space.
        // We can now set the final interval length and tick count.
        if (newMainYInterval > 0) {
            CPTXYAxisSet *axisSet = (id)graph.axisSet;
            CPTXYAxis    *y = axisSet.yAxis;

            y.majorIntervalLength = CPTDecimalFromFloat(newMainYInterval);
            newMainYInterval = 0;
        }
    }

    if (operation == globalRangeAnimationOperation) {
        globalRangeAnimationOperation = nil;
    }
    if (operation == rangeAnimationOperation) {
        rangeAnimationOperation = nil;
    }
}

#pragma mark - Plot data source methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot *)plot {
    return count;
}

- (double *)doublesForPlot: (CPTPlot *)plot field: (NSUInteger)fieldEnum recordIndexRange: (NSRange)indexRange {
    if (fieldEnum == CPTBarPlotFieldBarLocation || fieldEnum == CPTScatterPlotFieldX) {
        return &timePoints[indexRange.location];
    }

    NSString *identifier = (id)plot.identifier;
    if ([identifier isEqualToString: @"positiveBalances"]) {
        return &positiveBalances[indexRange.location];
    } else {
        if ([identifier isEqualToString: @"negativeBalances"]) {
            return &negativeBalances[indexRange.location];
        }
    }

    return nil;
}

- (CPTLayer *)dataLabelForPlot: (CPTPlot *)plot recordIndex: (NSUInteger)index {
    return (id)[NSNull null]; // Don't show any data label.
}

@end

#pragma mark - AssetsCard implementation

@interface AssetsCard ()
{
}

@end

@implementation AssetsCard

+ (BOOL)isClickable {
    return YES;
}

+ (BOOL)isConfigurable {
    return YES;
}

- (id)initWithFrame: (NSRect)frame {
    LogEnter;

    self = [super initWithFrame: frame];
    if (self) {
        [self updateUI];

        LocalSettingsController *settings = LocalSettingsController.sharedSettings;
        [settings addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];
        [settings addObserver: self forKeyPath: @"assetGraph1" options: 0 context: UserDefaultsBindingContext];
        [settings addObserver: self forKeyPath: @"assetGraph2" options: 0 context: UserDefaultsBindingContext];

        [NSNotificationCenter.defaultCenter addObserver: self
                                               selector: @selector(handleDataModelChange:)
                                                   name: NSManagedObjectContextDidSaveNotification
                                                 object: MOAssistant.assistant.context];

    }

    LogLeave;

    return self;
}

- (void)dealloc {
    LogEnter;

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    [settings removeObserver: self forKeyPath: @"colors"];
    [settings removeObserver: self forKeyPath: @"assetGraph1"];
    [settings removeObserver: self forKeyPath: @"assetGraph2"];

    [NSNotificationCenter.defaultCenter removeObserver: self];

    LogLeave;
}

- (void)handleDataModelChange: (NSNotification *)notification {
    LogEnter;

    @try {
        if (!BankingController.controller.shuttingDown) {
            NSSet *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
            NSSet *insertedObjects = notification.userInfo[NSInsertedObjectsKey];

            if ((deletedObjects.count + insertedObjects.count) > 0) {
                [self updateUI];
            }
        }
    }
    @catch (NSException *exception) {
        LogError(@"%@", exception.debugDescription);
    }

    LogLeave;
}

- (void)updateUI {
    LogEnter;

    AssetGraph *graph;

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    Category                *category = [Category categoryForName: settings[@"assetGraph1"]];
    if (category != nil) {
        graph = [self viewWithTag: 1];
        if (graph == nil) {
            graph = [[AssetGraph alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                             category: category];
            graph.tag = 1;
            [self addSubview: graph];
        } else {
            graph.category = category;
        }
    }

    category = [Category categoryForName: settings[@"assetGraph2"]];
    if (category != nil) {
        graph = [self viewWithTag: 2];
        if (graph == nil) {
            graph = [[AssetGraph alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                             category: category];
            graph.tag = 2;
            [self addSubview: graph];
        } else {
            graph.category = category;
        }
    }

    [self resizeSubviewsWithOldSize: self.bounds.size];

    LogLeave;
}

/**
 * Layouts all charts in a column format.
 */
- (void)resizeSubviewsWithOldSize: (NSSize)oldSize {
    LogEnter;

    NSRect frame = self.bounds;
    frame.size.width -= 40;
    frame.size.height = (int)(frame.size.height - 55) / 2;
    frame.origin.x = 15;
    frame.origin.y = 35;

    for (NSView *child in self.subviews) {
        if ([child isKindOfClass: AssetGraph.class]) {
            child.frame = frame;
            frame.origin.y += frame.size.height;
        }
    }
    LogLeave;
}

- (void)mouseDown: (NSEvent *)theEvent {
    LogEnter;

    // Happens if the user clicked on space not covered by a graph. Take the first one in this case.
    [super mouseDown: theEvent];

    Category *category;
    for (NSView *child in self.subviews) {
        if ([child isKindOfClass: AssetGraph.class]) {
            AssetGraph *graph = (id)child;
            category = graph.category;
            break;
        }
    }
    if (category != nil) {
        [self cardClicked: category];
    }

    LogLeave;
}

#pragma mark - Bindings, KVO and KVC

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context {
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            for (AssetGraph *child in self.subviews) {
                [child updateColors];
            }
        }

        // Only listen for the second change. Both graph values are changed at the same time.
        if ([keyPath isEqualToString: @"assetGraph2"]) {
            [self updateUI];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

@end
