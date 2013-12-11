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

#import "Category.h"
#import "ShortDate.h"
#import "SaveAndRedeemCard.h"

#import "AnimationHelper.h"
#import "NSColor+PecuniaAdditions.h"
#import "PecuniaPlotTimeFormatter.h"
#import "MCEMDecimalNumberAdditions.h"
#import "ColumnLayoutCorePlotLayer.h"

#import "MOAssistant.h"
#import "BankingController.h"
#import "PreferenceController.h"
#import "LocalSettingsController.h"

extern void *UserDefaultsBindingContext;

#define ANIMATION_TIME 0.75

/**
 * The companion of the principal balance graph. It displays the monthly paid rate split into
 * interest and redemption.
 */
@interface RedemptionGraph : CPTGraphHostingView  <CPTPlotDataSource, CPTAnimationDelegate,
  CPTPlotSpaceDelegate, CPTBarPlotDataSource>

- (void)updateTrackLineAndInfoDisplay: (CGFloat)location;
- (void)showInfoComponents;
- (void)hideInfoComponents;
- (void)switchToMonthMode;
- (void)switchToYearMode;
- (void)changePlotRange: (CPTPlotRange *)newRange;

@end

@interface PrincipalBalanceGraph : CPTGraphHostingView  <CPTPlotDataSource, CPTAnimationDelegate, CPTPlotSpaceDelegate>
{
@public
    RedemptionGraph *peerGraph;

@private
    SaveAndRedeemCard *owner;
    CPTXYGraph *graph;

    ShortDate *referenceDate;

    // Annuity loan in the course of the year.
    // Also known as fixed-rate mortgage (http://en.wikipedia.org/wiki/Fixed-rate_mortgage ).
    // Better described however on the german wiki page: (http://de.wikipedia.org/wiki/Annuit%C3%A4tendarlehen ).
    ShortDate *fromDate;     // Start date of debt pay off.
    ShortDate *toDate;       // fromDate + maturity (or term).

    NSDecimalNumber *borrowedAmount;
    NSDecimalNumber *monthlyRate;

    NSDecimalNumberHandler *roundUp;
    NSDecimalNumberHandler *roundDown;
    NSDecimalNumberHandler *bankersRounding;

    NSUInteger numberOfMonths; // Number of entries in all month data arrays (all same size).
                               // Computed from the original values without considering special payments.
    double     *monthTimePoints;
    double     *monthDebtValues;
    double     *monthDebtValues2; // Values without special repayments.
    NSUInteger realNumberOfMonths; // Real number of months (special payments applied).

    NSUInteger numberOfYears; // Ditto.
    double     *yearTimePoints;
    double     *yearDebtValues;
    double     *yearDebtValues2;
    NSUInteger realNumberOfYears;

    double min;
    double max;
    double totalPaid;
    double totalPaid2;
    double interestPaid;
    double interestPaid2;

    NSCalendarUnit currentGrouping;
    NSUInteger     lastInfoTimePoint;

    CPTBorderedLayer *zoomImageLayer;

    CPTXYAxis             *indicatorLine;
    CPTAnimationOperation *indicatorAnimation;
    CPTAnimationOperation *zoomInAnimation;
    CPTAnimationOperation *zoomOutAnimation;

    NSMutableArray      *yearAnnotations;
    CPTMutableTextStyle *yearLabelTextStyle;

    NSUInteger peerUpdateCount;
    BOOL animating;

    NSTrackingArea *trackingArea;
}

@end

@implementation PrincipalBalanceGraph

- (id)initWithFrame: (NSRect)frame
          startDate: (ShortDate *)date
        totalAmount: (double)amount
       interestRate: (double)rate
             redeem: (double)redeemValue
  specialRedemption: (NSDictionary *)unscheduledRepayment
              owner: (SaveAndRedeemCard *)anOwner
{
    self = [super initWithFrame: frame];
    if (self) {
        owner = anOwner;
        currentGrouping = NSCalendarUnitYear;

        yearLabelTextStyle = [[CPTMutableTextStyle alloc] init];
        yearLabelTextStyle.color = [CPTColor colorWithComponentRed: 0.388 green: 0.382 blue: 0.363 alpha: 1];
        yearLabelTextStyle.fontName = @"HelveticaNeue-CondensedBlack";
        yearLabelTextStyle.fontSize = 14;

        roundUp = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundUp
                                                                                  scale: 2
                                                                       raiseOnExactness: NO
                                                                        raiseOnOverflow: NO
                                                                       raiseOnUnderflow: NO
                                                                    raiseOnDivideByZero: YES];

        roundDown = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundDown
                                                                           scale: 2
                                                                raiseOnExactness: NO
                                                                 raiseOnOverflow: NO
                                                                raiseOnUnderflow: NO
                                                             raiseOnDivideByZero: YES];

        bankersRounding = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundBankers
                                                                                 scale: 2
                                                                      raiseOnExactness: NO
                                                                       raiseOnOverflow: NO
                                                                      raiseOnUnderflow: NO
                                                                   raiseOnDivideByZero: YES];

        [self setupGraph];
        [self updateDataForDate: date
                         amount: amount
                   interestRate: rate
                         redeem: redeemValue
              specialRedemption: unscheduledRepayment];
    }

    return self;
}

- (void)showGraph
{
    CPTPlot          *plot = (id)[graph plotWithIdentifier : @"mainDebtValues"];
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath: @"opacity"];
    fadeIn.beginTime = CACurrentMediaTime() + 0.5;
    fadeIn.fromValue = [NSNumber numberWithFloat: 0.0];
    fadeIn.toValue = [NSNumber numberWithFloat: 1.0];
    fadeIn.duration = 1;
    fadeIn.repeatCount = 1;
    fadeIn.delegate = self;
    [plot addAnimation: fadeIn forKey: nil];

    plot = (id)[graph plotWithIdentifier : @"rawDebtValues"];
    fadeIn = [CABasicAnimation animationWithKeyPath: @"opacity"];
    fadeIn.beginTime = CACurrentMediaTime() + 0.5;
    fadeIn.fromValue = [NSNumber numberWithFloat: 0.0];
    fadeIn.toValue = [NSNumber numberWithFloat: 1.0];
    fadeIn.duration = 1;
    fadeIn.repeatCount = 1;
    fadeIn.delegate = nil;
    [plot addAnimation: fadeIn forKey: nil];
}

- (void)dealloc
{
    free(monthTimePoints);
    free(monthDebtValues);
    free(monthDebtValues2);

    free(yearTimePoints);
    free(yearDebtValues);
    free(yearDebtValues2);
}

- (void)animationDidStart: (CAAnimation *)anim
{
    CPTPlot *plot = (id)[graph plotWithIdentifier : @"mainDebtValues"];
    plot.opacity = 1; // We can't set the final opacity earlier since the animation is delayed.
    plot = (id)[graph plotWithIdentifier : @"rawDebtValues"];
    plot.opacity = 1;
}

- (void)setupGraph
{
    self.allowPinchScaling = NO;

    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame : NSRectToCGRect(self.bounds)];
    self.hostedGraph = graph;

    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.allowsMomentum = YES;
    plotSpace.delegate = self;

    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(100000)];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;

    // Graph padding
    graph.paddingLeft = 0;
    graph.paddingTop = 0;
    graph.paddingRight = 0;
    graph.paddingBottom = 0;
    graph.fill = nil;

    CPTPlotAreaFrame *frame = graph.plotAreaFrame;
    frame.paddingLeft = 70;
    frame.paddingRight = 20;
    frame.paddingTop = 20;
    frame.paddingBottom = 10;
    frame.masksToBorder = NO;
    frame.masksToBounds = NO;

    [self setupPlots];
    [self setUpAxes];
    [self setupAnnotations];
}

- (void)setupPlots
{
    CPTBarPlot *plot = [[CPTBarPlot alloc] init];
    plot.opacity = 0;
    plot.alignsPointsToPixels = YES;

    plot.delegate = self;
    plot.dataSource = self;

    plot.identifier = @"mainDebtValues";

    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineWidth = 3.0;
    barLineStyle.lineColor = [CPTColor colorWithComponentRed: 0.388 green: 0.382 blue: 0.363 alpha: 1];
    plot.lineStyle = barLineStyle;

    plot.fill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 0.388 green: 0.382 blue: 0.363 alpha: 0.55f]];
    plot.barBasesVary = NO;
    plot.barCornerRadius = 3.0f;
    plot.barsAreHorizontal = NO;
    plot.barWidth = CPTDecimalFromFloat(0.65);

    [graph addPlot: plot];

    plot = [[CPTBarPlot alloc] init];
    plot.opacity = 0;
    plot.alignsPointsToPixels = YES;

    plot.delegate = self;
    plot.dataSource = self;

    plot.identifier = @"rawDebtValues";

    barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineWidth = 1.5;
    barLineStyle.lineColor = [CPTColor colorWithComponentRed: 0.388 green: 0.382 blue: 0.363 alpha: 0.5];
    plot.lineStyle = barLineStyle;

    plot.fill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 0.388 green: 0.382 blue: 0.363 alpha: 0.25]];
    plot.barBasesVary = NO;
    plot.barCornerRadius = 3.0f;
    plot.barsAreHorizontal = NO;
    plot.barWidth = CPTDecimalFromFloat(0.9);

    [graph addPlot: plot];
}

- (void)setUpAxes
{
    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 1.0f;
    majorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.1];

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 1.0f;
    minorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.05];

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.minorTicksPerInterval = 0;
    x.majorGridLineStyle = majorGridLineStyle;
    x.minorGridLineStyle = nil;

    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.preferredNumberOfMajorTicks = 10;

    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [[CPTColor blackColor] colorWithAlphaComponent: 0.3];
    textStyle.fontName = @"ArialNarrow-Bold";
    textStyle.fontSize = 11.0;
    x.labelTextStyle = textStyle;
    x.labelOffset = -1;

    CPTXYAxis *y = axisSet.yAxis;
    textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [[CPTColor blackColor] colorWithAlphaComponent: 0.3];
    textStyle.fontName = @"ArialNarrow-Bold";
    textStyle.fontSize = 11.0;
    y.labelTextStyle = textStyle;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];

    y.majorGridLineStyle = majorGridLineStyle;
    y.minorGridLineStyle = minorGridLineStyle;
    y.minorTicksPerInterval = 9;

    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = nil;

    // The second y axis is used as the current location identifier.
    indicatorLine = [[CPTXYAxis alloc] init];
    indicatorLine.hidden = YES;
    indicatorLine.coordinate = CPTCoordinateY;
    indicatorLine.plotSpace = graph.defaultPlotSpace;
    indicatorLine.labelingPolicy = CPTAxisLabelingPolicyNone;
    indicatorLine.separateLayers = NO;
    indicatorLine.preferredNumberOfMajorTicks = 0;
    indicatorLine.minorTicksPerInterval = 0;

    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithGenericGray: 64 / 255.0];
    lineStyle.lineCap = kCGLineCapRound;
    lineStyle.dashPattern = lineStyle.dashPattern = @[@10.0f, @5.0f];
    indicatorLine.axisLineStyle = lineStyle;
    indicatorLine.majorTickLineStyle = nil;

    axisSet.axes = @[x, y, indicatorLine];

    NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.388 green: 0.382 blue: 0.363 alpha: 1.000],
                                 NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 12]};

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"AP964", nil)
                                                                              attributes: attributes];
    CPTLayerAnnotation *titleAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer: graph.plotAreaFrame];
    CPTTextLayer       *titleLayer = [[CPTTextLayer alloc] init];
    titleAnnotation.contentLayer = titleLayer;
    titleAnnotation.rectAnchor = CPTRectAnchorLeft;
    titleAnnotation.rotation = pi / 2;
    titleLayer.attributedText = title;
    [graph addAnnotation: titleAnnotation];
}

- (void)setupAnnotations
{
    CPTAnnotation *zoomImageAnnotation = [[CPTAnnotation alloc] init];

    zoomImageLayer = [[CPTBorderedLayer alloc] init];
    zoomImageLayer.shadowColor = CGColorCreateGenericGray(0, 1);
    zoomImageLayer.shadowRadius = 2.0;
    zoomImageLayer.shadowOffset = CGSizeMake(1, -1);
    zoomImageLayer.shadowOpacity = 0.25;

    CPTImage *image = [CPTImage imageNamed: @"time-zoom-in"];
    zoomImageLayer.fill = [CPTFill fillWithImage: image];
    zoomImageLayer.bounds = CGRectMake(0, 0, image.nativeImage.size.width, image.nativeImage.size.height);
    zoomImageLayer.hidden = YES;

    zoomImageAnnotation.contentLayer = zoomImageLayer;
    [graph addAnnotation: zoomImageAnnotation];
}

- (void)updateGraphUsingMinimalTickCount: (BOOL)flag
{
    int totalUnits;
    int tickCount;
    if (currentGrouping == NSCalendarUnitMonth) {
        tickCount = 12;
        totalUnits = (numberOfMonths > 1) ? monthTimePoints[numberOfMonths - 1] + 1 : 0;
        if (totalUnits < tickCount) {
            totalUnits = tickCount;
        }
    } else {
        tickCount = 10;
        totalUnits = (numberOfYears > 1) ? yearTimePoints[numberOfYears - 1] + 1 : 0;
        if (totalUnits < tickCount) {
            totalUnits = tickCount;
        }
    }

    // Set the available plot space depending on the min, max and day values we found.
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;

    // Horizontal range.
    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(-0.5)
                                                           length: CPTDecimalFromDouble(totalUnits)];
    plotSpace.globalXRange = plotRange;

    float from = [self distanceFromDate: referenceDate toDate: fromDate];
    float to = [self distanceFromDate: referenceDate toDate: toDate];
    if (flag && (to - from < tickCount)) {
        to = from + tickCount;
    }
    plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(from - 0.5) length: CPTDecimalFromFloat(to - from)];
    plotSpace.xRange = plotRange;

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.preferredNumberOfMajorTicks = tickCount;

    // Recreate the time formatter to apply the new reference date. Just setting the date on the existing
    // formatter is not enough.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;

    PecuniaPlotTimeFormatter *timeFormatter = [[PecuniaPlotTimeFormatter alloc] initWithDateFormatter: dateFormatter
                                                                                         calendarUnit: currentGrouping];
    timeFormatter.useMonthNames = YES;
    timeFormatter.referenceDate = [referenceDate lowDate];
    x.labelFormatter = timeFormatter;

    // The currency of the main category can change so update the y axis label formatter as well.
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.usesSignificantDigits = YES;
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.currencyCode = @"EUR";
    currencyFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", currencyFormatter.currencySymbol];
    axisSet.yAxis.labelFormatter = currencyFormatter;
}

- (void)updateVerticalGraphRange
{
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    CPTXYAxisSet   *axisSet = (id)graph.axisSet;

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
    NSDecimalNumber *roundedMin = [[NSDecimalNumber decimalNumberWithDecimal: decimalMinValue] roundToUpperOuter];
    NSDecimalNumber *roundedMax;
    if (useDefault) {
        roundedMax = [NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue];
    } else {
        roundedMax = [[NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue] roundToUpperOuter];
    }

    // Let the larger area (negative or positive) determine the size of the major tick range.
    NSDecimalNumber *minAbsolute = [roundedMin abs];
    NSDecimalNumber *maxAbsolute = [roundedMax abs];
    float           interval;
    if ([minAbsolute compare: maxAbsolute] == NSOrderedDescending) {
        interval = [self intervalFromRange: minAbsolute];
    } else {
        interval = [self intervalFromRange: maxAbsolute];
    }

    y.majorIntervalLength = CPTDecimalFromFloat(interval);
    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: roundedMin.decimalValue
                                                           length: [[roundedMax decimalNumberBySubtracting: roundedMin] decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
}

- (CPTPlotSpaceAnnotation *)createAnnotationAtPosition: (CGPoint)position
{
    NSMutableArray *point = [[NSMutableArray alloc] initWithCapacity: 2];
    NSDecimal      decimal = CPTDecimalFromDouble(position.x);
    [point addObject: [NSDecimalNumber decimalNumberWithDecimal: decimal]];
    decimal = CPTDecimalFromDouble(position.y);
    [point addObject: [NSDecimalNumber decimalNumberWithDecimal: decimal]];
    CPTPlotSpaceAnnotation *annotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace: graph.defaultPlotSpace
                                                                           anchorPlotPoint: point];
    return annotation;

}

- (void)updateYearLabelsRefill: (BOOL)refill
{
    CPTBarPlot *plot = (id)[graph plotWithIdentifier : @"mainDebtValues"];
    for (CPTPlotSpaceAnnotation *annotation in yearAnnotations) {
        if (annotation.annotationHostLayer != nil) {
            [plot removeAnnotation: annotation];
        }
    }
    if (currentGrouping == NSCalendarUnitMonth) {
        if (yearAnnotations == nil || refill) {
            yearAnnotations = [NSMutableArray array];

            // Always create a label for the very first entry. Then move on to the first January
            // and jump by 12 months for the next indexes.
            NSUInteger             currentIndex = 0;
            CPTPlotSpaceAnnotation *annotation = [self createAnnotationAtPosition: CGPointMake(currentIndex, 0)];
            CPTTextLayer           *content = [[CPTTextLayer alloc] initWithText: [NSString stringWithFormat: @"%u", referenceDate.year]
                                                                           style: yearLabelTextStyle];
            annotation.contentLayer = content;

            CPTPlotSpace *plotSpace = graph.defaultPlotSpace;
            NSDecimal    target[2] = {0, 0};
            CGPoint      zeroPoint = [plotSpace plotAreaViewPointForPlotPoint: target numberOfCoordinates: 2];
            target[1] = CPTDecimalFromDouble(max);
            CGPoint point = [plotSpace plotAreaViewPointForPlotPoint: target numberOfCoordinates: 2];
            annotation.displacement = CGPointMake(-2, floor(point.y - NSMidX(content.bounds) - 5));
            annotation.rotation = M_PI_2;
            [yearAnnotations addObject: annotation];

            NSInteger year = referenceDate.year + 1;
            for (currentIndex = 13 - referenceDate.month; currentIndex < numberOfMonths; currentIndex += 12) {
                annotation = [self createAnnotationAtPosition: CGPointMake(currentIndex, 0)];
                content = [[CPTTextLayer alloc] initWithText: [NSString stringWithFormat: @"%li", year++]
                                                       style: yearLabelTextStyle];
                annotation.rotation = M_PI_2;
                annotation.contentLayer = content;

                target[1] = CPTDecimalFromDouble(monthDebtValues[currentIndex]);
                CGPoint point = [plotSpace plotAreaViewPointForPlotPoint: target numberOfCoordinates: 2];
                if ((point.y - zeroPoint.y - 10) < NSWidth(content.bounds)) {
                    point.y += NSMidX(content.bounds) + 5;
                } else {
                    point.y -= NSMidX(content.bounds) + 5;
                }
                annotation.displacement = CGPointMake(-2, floor(point.y));

                [yearAnnotations addObject: annotation];
            }
        }

        CPTBarPlot *plot = (id)[graph plotWithIdentifier : @"mainDebtValues"];
        for (CPTPlotSpaceAnnotation *annotation in yearAnnotations) {
            [plot addAnnotation: annotation];
        }
    }
}

- (void)updateDataForDate: (ShortDate *)date
                   amount: (double)amount
             interestRate: (double)rate
                   redeem: (double)redeemValue
        specialRedemption: (NSDictionary *)unscheduledRepayment
{
    ++peerUpdateCount;

    free(monthTimePoints);
    free(monthDebtValues);
    free(monthDebtValues2);

    free(yearTimePoints);
    free(yearDebtValues);
    free(yearDebtValues2);

    referenceDate = date;

    NSDecimal       decimal = CPTDecimalFromInt(1200);
    NSDecimalNumber *thousandTwoHundered = [NSDecimalNumber decimalNumberWithDecimal: decimal];

    // Initial interest rate and redeem (which in sum represets the constant monthly rate).
    decimal = CPTDecimalFromDouble(rate);
    NSDecimalNumber *interestRate = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    decimal = CPTDecimalFromDouble(amount);
    borrowedAmount = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    decimal = CPTDecimalFromDouble(redeemValue);
    NSDecimalNumber *redeem = [NSDecimalNumber decimalNumberWithDecimal: decimal];

    interestRate = [interestRate decimalNumberByDividingBy: thousandTwoHundered];
    interestRate = [interestRate decimalNumberByMultiplyingBy: borrowedAmount];
    interestRate = [interestRate decimalNumberByRoundingAccordingToBehavior: roundUp];

    redeem = [redeem decimalNumberByDividingBy: thousandTwoHundered];
    redeem = [redeem decimalNumberByMultiplyingBy: borrowedAmount];
    redeem = [redeem decimalNumberByRoundingAccordingToBehavior: roundDown];

    monthlyRate = [interestRate decimalNumberByAdding: redeem];

    // Compute total maturity (in number of months).
    decimal = CPTDecimalFromInt(12);
    NSDecimalNumber *twelf = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    NSDecimalNumber *annuity = [monthlyRate decimalNumberByMultiplyingBy: twelf];

    NSDecimalNumber *repaymentRate = [annuity decimalNumberByDividingBy: borrowedAmount];
    decimal = CPTDecimalFromDouble(rate / 100);
    NSDecimalNumber *convertedRate = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    repaymentRate = [repaymentRate decimalNumberBySubtracting: convertedRate];

    // Change 12 if there is a different number of payments per year.
    numberOfMonths = ceil(log(1 + convertedRate.doubleValue / repaymentRate.doubleValue) / log(1 + convertedRate.doubleValue / 12));

    monthTimePoints = malloc(numberOfMonths * sizeof(double));
    monthDebtValues = malloc(numberOfMonths * sizeof(double));
    monthDebtValues2 = malloc(numberOfMonths * sizeof(double));

    ShortDate *endDate = [referenceDate dateByAddingUnits: numberOfMonths byUnit: NSCalendarUnitMonth];
    endDate = [endDate dateByAddingUnits: -1 byUnit: NSCalendarUnitDay];
    numberOfYears = endDate.year - referenceDate.year + 1;
    yearTimePoints = malloc(numberOfYears * sizeof(double));
    yearDebtValues = malloc(numberOfYears * sizeof(double));
    yearDebtValues2 = malloc(numberOfYears * sizeof(double));

    // Select a meaningful initial display window for the entire range.
    NSUInteger units = currentGrouping == NSCalendarUnitMonth ? 12 : 10;
    ShortDate  *now = [ShortDate currentDate];
    if ([referenceDate compare: now] == NSOrderedDescending) {
        // First date is after the current date. Our initial window is hence just the first "units" months/years.
        fromDate = referenceDate;
        toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
    } else {
        NSUInteger count = currentGrouping == NSCalendarUnitMonth ? numberOfMonths : numberOfYears;
        toDate = [referenceDate dateByAddingUnits: count byUnit: currentGrouping];
        if ([toDate compare: now] == NSOrderedAscending) {
            // The end is already in the past. The initial window is hence the last "units" months/years.
            if (count >= 12) {
                fromDate = [toDate dateByAddingUnits: -units byUnit: currentGrouping];
            } else {
                // Too few units for the entire range. Start with the first date and
                // show a range of the given units, even if there aren't enough entries.
                fromDate = referenceDate;
                toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
            }
        } else {
            // Most common case: we are within an active range.
            // Start with "units - 1" entries back and 1 in the future or full units back if we are at the end of the range.
            if ([now.firstDayInMonth compare: toDate.firstDayInMonth] == NSOrderedSame) {
                fromDate = [toDate dateByAddingUnits: -units byUnit: currentGrouping];
            } else {
                if (count >= units) {
                    toDate = [now dateByAddingUnits: 1 byUnit: currentGrouping];
                    fromDate = [toDate dateByAddingUnits: -units byUnit: currentGrouping];
                } else {
                    fromDate = referenceDate;
                    toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
                }
            }

            // If we set the start date to before the actual start then shift the entire range to
            // begin at the actual start date.
            if ([fromDate compare: referenceDate] == NSOrderedAscending) {
                fromDate = referenceDate;
                toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
            }
        }
    }

    // Note: unscheduledRepayment contains NSNumber stored under a ShortDate hash which must address
    //       the first day in a month where the payment was done. The actual day doesn't matter
    //       as an unscheduled repayment is always taken into account in the next time period only.
    NSDecimalNumber *run = borrowedAmount;
    NSDecimalNumber *run2 = borrowedAmount;   // Run without unscheduled payments.
    NSDecimalNumber *currentRedeem = redeem;
    NSDecimalNumber *currentRedeem2 = redeem; // Redeem without unscheduled payments.

    NSDecimalNumber *total = [NSDecimalNumber zero];
    NSDecimalNumber *total2 = [NSDecimalNumber zero];

    decimal = CPTDecimalFromFloat(rate);
    NSDecimalNumber *rateFactor = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    rateFactor = [rateFactor decimalNumberByDividingBy: thousandTwoHundered];
    NSUInteger yearIndex = 0;
    ShortDate *currentDate = fromDate.firstDayInMonth;
    BOOL foundEarlierFullPayOff = NO;
    for (NSUInteger i = 0; i < numberOfMonths; ++i) {
        monthTimePoints[i] = i;

        BOOL allPaidOff = run.doubleValue <= 0;
        monthDebtValues[i] = allPaidOff ? NAN : run.doubleValue;

        if ([run compare: run2] == NSOrderedSame) {
            monthDebtValues2[i] = NAN;
        } else {
            monthDebtValues2[i] = run2.doubleValue;
        }

        if (currentDate.month == 1 || i == 0) {
            yearTimePoints[yearIndex] = yearIndex;
            yearDebtValues[yearIndex] = allPaidOff ? NAN : run.doubleValue;

            if ([run compare: run2] == NSOrderedSame) {
                yearDebtValues2[yearIndex] = NAN;
            } else {
                yearDebtValues2[yearIndex] = run2.doubleValue;
            }

            yearIndex++;
        }

        if (run.doubleValue > 0) {
            run = [run decimalNumberBySubtracting: currentRedeem];
            total = [total decimalNumberByAdding : monthlyRate];

            NSNumber *special = unscheduledRepayment[@(currentDate.hash)];
            if (special != nil) {
                decimal = CPTDecimalFromDouble(special.doubleValue);
                NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithDecimal: decimal];
                run = [run decimalNumberBySubtracting: temp];
                total = [total decimalNumberByAdding : temp];
            }
            if (run.doubleValue <= 0) {
                // We reached the actual end of the payment time frame.
                total = [total decimalNumberByAdding : run];

                run = [NSDecimalNumber zero];
                foundEarlierFullPayOff = YES;
                realNumberOfMonths = i + 1;
                realNumberOfYears = currentDate.year - fromDate.year + 1;
            }
            NSDecimalNumber *currentInterestRate = [run decimalNumberByMultiplyingBy: rateFactor
                                                                        withBehavior: bankersRounding];
            currentRedeem = [monthlyRate decimalNumberBySubtracting: currentInterestRate];
        }
        total2 = [total2 decimalNumberByAdding : monthlyRate];

        // The run value for the normal series never goes to zero before the end of the entire range,
        // but in can at the end (if the last redemption is larger than the remaining debt.
        run2 = [run2 decimalNumberBySubtracting: currentRedeem2];
        if (run2.doubleValue < 0) {
            total2 = [total2 decimalNumberByAdding : run2];
        }
        NSDecimalNumber *currentInterestRate = [run2 decimalNumberByMultiplyingBy: rateFactor
                                                                     withBehavior: bankersRounding];
        currentRedeem2 = [monthlyRate decimalNumberBySubtracting: currentInterestRate];

        currentDate = [currentDate dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth];
    }

    if (yearIndex < numberOfYears) {
        yearTimePoints[numberOfYears - 1] = yearIndex;
    }

    if (!foundEarlierFullPayOff) {
        realNumberOfMonths = numberOfMonths;
        realNumberOfYears = numberOfYears;
    }

    totalPaid = total.doubleValue;
    totalPaid2 = total2.doubleValue;
    if (totalPaid == totalPaid2) {
        totalPaid2 = NAN;
    }

    min = 0;
    max = borrowedAmount.doubleValue;

    [self showGeneralInfo];
    [self updateGraphUsingMinimalTickCount: YES];
    [self updateVerticalGraphRange];
    [self updateYearLabelsRefill: YES];
    [graph reloadData];

    --peerUpdateCount;
}

/**
 * Called when the users moved the mouse over the graph.
 * Move the indicator line to the current mouse position and update the info annotation.
 *
 * The location is given in plot area coordinates.
 */
- (void)updateTrackLineAndInfoDisplay: (CGFloat)location
{
    if (numberOfMonths < 1) {
        return;
    }

    // Determine the content for the info layer.
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    CGPoint        point = CGPointMake(location, 0);

    NSDecimal dataPoint[2];
    [plotSpace plotPoint: dataPoint numberOfCoordinates: 2 forPlotAreaViewPoint: point];
    double timePoint = CPTDecimalDoubleValue(dataPoint[0]);

    // Check if the time point is within the visible range.
    if (timePoint < plotSpace.xRange.minLimitDouble || timePoint >= plotSpace.xRange.maxLimitDouble) {
        [self hideInfoComponents];
        lastInfoTimePoint = 0;
        return;
    }

    // Find closest point in our time points that is before the computed time value.
    NSUInteger index = timePoint < 0 ? 0 : round(timePoint);
    NSDecimal snapPoint[2] = {0, 0};
    snapPoint[0] = CPTDecimalFromInteger(index);
    CGPoint targetPoint = [plotSpace plotAreaViewPointForPlotPoint: snapPoint numberOfCoordinates: 2];

    // Another check for visiblity, now with rounded coordinate.
    if (targetPoint.x < 0 || index > plotSpace.xRange.maxLimitDouble) {
        [self hideInfoComponents];
        lastInfoTimePoint = 0;
        return;
    }

    location = targetPoint.x;

    if (lastInfoTimePoint == 0 || (index != lastInfoTimePoint)) {
        lastInfoTimePoint = index;

        [self showInfoComponents];

        /* TODO: for now we cannot use CPTAnimation for this as it does not cope well with
                 repeated animations for the same property.
        if (indicatorAnimation == nil) {
            indicatorAnimation = [CPTAnimation animate: indicatorLine
                                              property: @"orthogonalCoordinateDecimal"
                                           fromDecimal: indicatorLine.orthogonalCoordinateDecimal
                                             toDecimal: CPTDecimalFromFloat(index)
                                              duration: 0.125
                                             withDelay: 0
                                        animationCurve: CPTAnimationCurveCubicInOut
                                              delegate: self];
        } else {
            indicatorAnimation.canceled = YES;
        }
         */
        indicatorLine.orthogonalCoordinateDecimal = CPTDecimalFromFloat(index);

        if (currentGrouping == NSCalendarUnitMonth) {
            if (index < numberOfMonths) {
                double currentDept = index < realNumberOfMonths ? monthDebtValues[index] : NAN;
                double paidOff = isnan(currentDept) ? 1 : (borrowedAmount.doubleValue - currentDept) / borrowedAmount.doubleValue;
                double currentDept2 = index < numberOfMonths ? monthDebtValues2[index] : NAN;
                double paidOff2 = isnan(currentDept2) ? 1 : (borrowedAmount.doubleValue - currentDept2) / borrowedAmount.doubleValue;
                [owner updateInfoForDate: nil
                        principalBalance: currentDept
                       principalBalance2: currentDept2
                                 paidOff: paidOff
                                paidOff2: paidOff2
                           remainingTime: index > realNumberOfMonths ? 0 : realNumberOfMonths - index
                          remainingTime2: index > numberOfMonths ? 0 : numberOfMonths - index];
            } else {
                [self showGeneralInfo];
            }
        } else {
            [zoomImageLayer slideTo: CGPointMake(location + graph.plotAreaFrame.paddingLeft, NSMaxY(self.bounds) - 15) inTime: 0.125];

            if (index < numberOfYears) {
                // In year mode we need to consider the first and last year separately as neither of
                // them may consist of a full 12 months range.
                NSUInteger remainingTime;
                NSUInteger remainingTime2;
                if (index > 0) {
                    NSUInteger monthsDone = 12 - referenceDate.month + 1 + (index - 1) * 12;
                    remainingTime = monthsDone > realNumberOfMonths ? 0 : realNumberOfMonths - monthsDone;
                    remainingTime2 = monthsDone > numberOfMonths ? 0 : numberOfMonths - monthsDone;
                } else {
                    remainingTime = realNumberOfMonths;
                    remainingTime2 = numberOfMonths;
                }

                double currentDept = index < realNumberOfYears ? yearDebtValues[index] : NAN;
                double paidOff = isnan(currentDept) ? 1 : (borrowedAmount.doubleValue - currentDept) / borrowedAmount.doubleValue;
                double currentDept2 = index < numberOfYears ? yearDebtValues2[index] : NAN;
                double paidOff2 = isnan(currentDept2) ? 1 : (borrowedAmount.doubleValue - currentDept2) / borrowedAmount.doubleValue;
                [owner updateInfoForDate: nil
                        principalBalance: currentDept
                       principalBalance2: currentDept2
                                 paidOff: paidOff
                                paidOff2: paidOff2
                           remainingTime: remainingTime
                          remainingTime2: remainingTime2];
            } else {
                [self showGeneralInfo];
            }
        }
    }
}

- (void)showInfoComponents
{
    if (peerUpdateCount > 0) {
        return;
    }

    ++peerUpdateCount;
    [indicatorLine fadeIn];
    if (currentGrouping == NSCalendarUnitYear) {
        [zoomImageLayer fadeIn];
    }
    [peerGraph showInfoComponents];
    --peerUpdateCount;
}

- (void)hideInfoComponents
{
    if (peerUpdateCount > 0) {
        return;
    }

    ++peerUpdateCount;
    [indicatorLine fadeOut];
    if (currentGrouping == NSCalendarUnitYear) {
        [zoomImageLayer fadeOut];
    }

    [peerGraph hideInfoComponents];
    --peerUpdateCount;
}

- (void)switchToMonthMode
{
    currentGrouping = NSCalendarUnitMonth;

    CPTImage *image = [CPTImage imageNamed: @"time-zoom-out"];
    zoomImageLayer.fill = [CPTFill fillWithImage: image];
    [zoomImageLayer slideTo: CGPointMake(NSMidX(self.bounds), NSMaxY(self.bounds) - 5) inTime: 0.25];

    unsigned month = 1;
    if (lastInfoTimePoint == 0) {
        month = referenceDate.month;
    }
    fromDate = [ShortDate dateWithYear: referenceDate.year + lastInfoTimePoint month: month day: 1];
    toDate = [fromDate dateByAddingUnits: 12 byUnit: NSCalendarUnitMonth];

    int totalUnits;
    int tickCount;
    tickCount = 12;
    totalUnits = (numberOfMonths > 1) ? monthTimePoints[numberOfMonths - 1] + 1 : 0;
    if (totalUnits < tickCount) {
        totalUnits = tickCount;
    }

    // We are still in year coordinates.
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    CPTPlotRange   *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(lastInfoTimePoint - 0.5)
                                                             length: CPTDecimalFromFloat(1)];

    lastInfoTimePoint *= 12; // Convert to month index.
                             // Make the bar fill the entire width.

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    CPTBarPlot *plot = (id)[graph plotWithIdentifier : @"mainDebtValues"];
    [CPTAnimation animate: plot
                 property: @"barWidth"
              fromDecimal: plot.barWidth
                toDecimal: CPTDecimalFromCGFloat(1)
                 duration: ANIMATION_TIME
                withDelay: 0
           animationCurve: CPTAnimationCurveCubicInOut
                 delegate: nil];

    plot = (id)[graph plotWithIdentifier : @"rawDebtValues"];
    [CPTAnimation animate: plot
                 property: @"barWidth"
              fromDecimal: plot.barWidth
                toDecimal: CPTDecimalFromCGFloat(1)
                 duration: ANIMATION_TIME
                withDelay: 0
           animationCurve: CPTAnimationCurveCubicInOut
                 delegate: nil];

    zoomInAnimation = [CPTAnimation animate: plotSpace
                                   property: @"xRange"
                              fromPlotRange: plotSpace.xRange
                                toPlotRange: plotRange
                                   duration: ANIMATION_TIME
                                  withDelay: 0
                             animationCurve: CPTAnimationCurveCubicInOut
                                   delegate: self];

    [peerGraph switchToMonthMode];
}

/**
 * Called when the range animation has ended.
 */
- (void)finishSwitchToMonthMode
{
    CPTBarPlot *plot = (id)[graph plotWithIdentifier : @"mainDebtValues"];
    plot.barWidth = CPTDecimalFromCGFloat(0.75);

    plot = (id)[graph plotWithIdentifier : @"rawDebtValues"];
    plot.barWidth = CPTDecimalFromCGFloat(0.75);

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    [self updateGraphUsingMinimalTickCount: YES];
    [self updateVerticalGraphRange];
    [self updateYearLabelsRefill: NO];
    [graph reloadData];
}

- (void)switchToYearMode
{
    CPTImage *image = [CPTImage imageNamed: @"time-zoom-in"];
    zoomImageLayer.fill = [CPTFill fillWithImage: image];

    // First switch immediately to a year range with the current year taking the full width.
    // Then animate this to the final range.
    toDate = [fromDate dateByAddingUnits: 1 byUnit: NSCalendarUnitYear];
    lastInfoTimePoint /= 12; // Convert to year index.
    currentGrouping = NSCalendarUnitYear;

    [self updateGraphUsingMinimalTickCount: NO];
    [self updateVerticalGraphRange];
    [self updateYearLabelsRefill: NO];
    [graph reloadData];

    // Now compute the real dates. Center the current year.
    fromDate = [ShortDate dateWithYear: fromDate.year - 5 month: 1 day: 1];
    if ([fromDate compare: referenceDate] == NSOrderedAscending) {
        fromDate = referenceDate;
    }
    toDate = [fromDate dateByAddingUnits: 10 byUnit: NSCalendarUnitYear];

    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    float          from = [self distanceFromDate: referenceDate toDate: fromDate];
    float          to = [self distanceFromDate: referenceDate toDate: toDate];
    if (to - from < 10) {
        to = from + 10;
    }
    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(from - 0.5)
                                                           length: CPTDecimalFromFloat(to - from)];
    zoomOutAnimation = [CPTAnimation animate: plotSpace
                                    property: @"xRange"
                               fromPlotRange: plotSpace.xRange
                                 toPlotRange: plotRange
                                    duration: ANIMATION_TIME
                                   withDelay: 0
                              animationCurve: CPTAnimationCurveCubicInOut
                                    delegate: self];

    [peerGraph switchToYearMode];
}

- (void)changePlotRange: (CPTPlotRange *)newRange
{
    if (zoomInAnimation != nil || zoomOutAnimation != nil) {
        return;
    }
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    plotSpace.xRange = newRange;
    fromDate = [referenceDate dateByAddingUnits: newRange.locationDouble byUnit: currentGrouping];
    toDate = [fromDate dateByAddingUnits: newRange.lengthDouble byUnit: currentGrouping];
}

- (void)showGeneralInfo
{
    [owner updateInfoWithBorrowedAmount: borrowedAmount.doubleValue
                              totalPaid: totalPaid
                             totalPaid2: totalPaid2
                           interestPaid: totalPaid - borrowedAmount.doubleValue
                          interestPaid2: isnan(totalPaid2) ? NAN : totalPaid2 - borrowedAmount.doubleValue];
}

#pragma mark - Event handling

- (void)mouseMoved: (NSEvent *)theEvent
{
    [super mouseMoved: theEvent];

    CPTXYPlotSpace *plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        return;
    }

    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [self updateTrackLineAndInfoDisplay: pointInHostedGraph.x];

    if (peerUpdateCount > 0) {
        return;
    }

    ++peerUpdateCount;
    [peerGraph updateTrackLineAndInfoDisplay: pointInHostedGraph.x];
    --peerUpdateCount;
}

- (void)mouseExited: (NSEvent *)theEvent
{
    [super mouseExited: theEvent];
    lastInfoTimePoint = 0;
    [self hideInfoComponents];
    [self showGeneralInfo];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];

    if (trackingArea != nil) {
        [self removeTrackingArea: trackingArea];
    }

    trackingArea = [[NSTrackingArea alloc] initWithRect: self.bounds
                                                options: NSTrackingMouseEnteredAndExited
                                                         | NSTrackingMouseMoved
                                                         | NSTrackingActiveInKeyWindow
                                                  owner: self
                                               userInfo: nil];
    [self addTrackingArea: trackingArea];
}

#pragma mark - Utility functions

- (void)updateColors
{
    [graph reloadData];
}

- (int)distanceFromDate: (ShortDate *)from toDate: (ShortDate *)to
{
    return [from unitsToDate: to byUnit: currentGrouping];
}

/**
 * Determines the optimal length of a major interval length for a plot depending on the
 * overall size of the range. This is a bit tricky as we want sharp and easy intervals
 * for optimal perceptibility. The given range is already rounded up to two most significant digits.
 */
- (float)intervalFromRange: (NSDecimalNumber *)range
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
        return convertedValue <= 5 ? 2 : 4;
    }

    if (convertedValue < 10) {
        return pow(10, digitCount - 1);
    }
    if (convertedValue == 10) {
        return 4 * pow(10, digitCount - 2);
    }
    if (convertedValue <= 15) {
        return 5 * pow(10, digitCount - 2);
    }
    if (convertedValue <= 45) {
        return 10 * pow(10, digitCount - 2);
    }

    return 2 * pow(10, digitCount - 1);
}

#pragma mark - Plot data source methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot *)plot
{
    return (currentGrouping == NSCalendarUnitMonth) ? numberOfMonths : numberOfYears;
}

- (double *)doublesForPlot: (CPTPlot *)plot field: (NSUInteger)fieldEnum recordIndexRange: (NSRange)indexRange
{
    if (fieldEnum == CPTBarPlotFieldBarLocation || fieldEnum == CPTScatterPlotFieldX) {
        if (currentGrouping == NSCalendarUnitMonth) {
            return &monthTimePoints[indexRange.location];
        }
        return &yearTimePoints[indexRange.location];
    }

    NSString *identifier = (id)plot.identifier;
    if ([identifier isEqualToString: @"mainDebtValues"]) {
        if (currentGrouping == NSCalendarUnitMonth) {
            return &monthDebtValues[indexRange.location];
        }
        return &yearDebtValues[indexRange.location];
    } else {
        if (currentGrouping == NSCalendarUnitMonth) {
            return &monthDebtValues2[indexRange.location];
        }
        return &yearDebtValues2[indexRange.location];
    }

    return nil;
}

- (CPTLayer *)dataLabelForPlot: (CPTPlot *)plot recordIndex: (NSUInteger)index
{
    return (id)[NSNull null];
}

#pragma mark - Plot space delegate methods

- (BOOL)                      plotSpace: (CPTPlotSpace *)space
    shouldHandlePointingDeviceDownEvent: (CPTNativeEvent *)event
                                atPoint: (CGPoint)point
{
    return !CGRectContainsPoint(zoomImageLayer.frame, point);
}

- (BOOL)                    plotSpace: (CPTPlotSpace *)space
    shouldHandlePointingDeviceUpEvent: (CPTNativeEvent *)event
                              atPoint: (CGPoint)point
{
    BOOL inZoomLayer = CGRectContainsPoint(zoomImageLayer.frame, point);
    if (!space.isDragging && inZoomLayer) {
        if (currentGrouping == NSCalendarUnitMonth) {
            [self switchToYearMode];
        } else {
            [self switchToMonthMode];
        }
    }

    return !inZoomLayer;
}

- (CGPoint)plotSpace: (CPTPlotSpace *)space willDisplaceBy: (CGPoint)proposedDisplacementVector
{
    [self hideInfoComponents];

    proposedDisplacementVector.y = 0;
    return proposedDisplacementVector;
}

-(CPTPlotRange *)plotSpace: (CPTPlotSpace *)space
     willChangePlotRangeTo: (CPTPlotRange *)newRange
             forCoordinate: (CPTCoordinate)coordinate
{
    if (peerUpdateCount > 0 || coordinate != CPTCoordinateX) {
        return newRange;
    }

    ++peerUpdateCount;
    [peerGraph changePlotRange: newRange];
    --peerUpdateCount;
    return newRange;
}

#pragma mark - Coreplot delegate methods

- (void)animationDidFinish: (CPTAnimationOperation *)operation
{
    if (operation == indicatorAnimation) {
        indicatorAnimation = nil;
    } else {
        if (operation == zoomInAnimation) {
            zoomInAnimation = nil;
            [self finishSwitchToMonthMode];
        } else {
            zoomOutAnimation = nil;
        }
    }
}

- (void)animationCancelled: (CPTAnimationOperation *)operation
{
    if (operation == indicatorAnimation) {
        indicatorAnimation = nil;
    } else {
        if (operation == zoomInAnimation) {
            [self finishSwitchToMonthMode];
            zoomInAnimation = nil;
        } else {
            zoomOutAnimation = nil;
        }
    }
}

@end

#pragma mark - RedemptionGraph implementation

/**
 * The companion of the principal balance graph. It displays the monthly paid rate split into
 * interest and redemption.
 */
@interface RedemptionGraph ()
{
@public
    PrincipalBalanceGraph *peerGraph;

@private
    SaveAndRedeemCard *owner;
    CPTXYGraph *graph;

    ShortDate *referenceDate;

    // Currently visible date range.
    ShortDate *fromDate;
    ShortDate *toDate;

    NSDecimalNumber *monthlyRate;

    NSDecimalNumberHandler *roundUp;
    NSDecimalNumberHandler *roundDown;
    NSDecimalNumberHandler *bankersRounding;

    NSUInteger numberOfMonths; // Number of entries in all month data arrays (all same size).
                               // Computed from the original values without considering special payments.
    double     *monthTimePoints;
    double     *monthInterestValues;
    double     *monthInterestValues2; // Values without special repayments.
    double     *monthRedemptionValues;
    double     *monthRedemptionValues2;
    NSUInteger realNumberOfMonths; // Real number of months (special payments applied).

    NSUInteger numberOfYears; // Ditto.
    double     *yearTimePoints;
    double     *yearInterestValues;
    double     *yearInterestValues2;
    double     *yearRedemptionValues;
    double     *yearRedemptionValues2;
    NSUInteger realNumberOfYears;

    double min;
    double max;

    NSCalendarUnit currentGrouping;
    NSUInteger     lastInfoTimePoint;

    CPTXYAxis             *indicatorLine;
    CPTAnimationOperation *indicatorAnimation;

    NSNumberFormatter *infoTextFormatter;

    NSUInteger peerUpdateCount;

    NSTrackingArea *trackingArea;
}

@end

@implementation RedemptionGraph

- (id)initWithFrame: (NSRect)frame
          startDate: (ShortDate *)date
        totalAmount: (double)amount
       interestRate: (double)rate
             redeem: (double)redeemValue
  specialRedemption: (NSDictionary *)unscheduledRepayment
              owner: (SaveAndRedeemCard *)anOwner
{
    self = [super initWithFrame: frame];
    if (self) {
        owner = anOwner;
        currentGrouping = NSCalendarUnitYear;

        roundUp = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundUp
                                                                         scale: 2
                                                              raiseOnExactness: NO
                                                               raiseOnOverflow: NO
                                                              raiseOnUnderflow: NO
                                                           raiseOnDivideByZero: YES];

        roundDown = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundDown
                                                                           scale: 2
                                                                raiseOnExactness: NO
                                                                 raiseOnOverflow: NO
                                                                raiseOnUnderflow: NO
                                                             raiseOnDivideByZero: YES];

        bankersRounding = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundBankers
                                                                                 scale: 2
                                                                      raiseOnExactness: NO
                                                                       raiseOnOverflow: NO
                                                                      raiseOnUnderflow: NO
                                                                   raiseOnDivideByZero: YES];

        [self setupGraph];
        [self updateDataForDate: date
                         amount: amount
                   interestRate: rate
                         redeem: redeemValue
              specialRedemption: unscheduledRepayment];
    }

    return self;
}

- (void)showGraph
{
    CPTPlot          *plot = (id)[graph plotWithIdentifier : @"mainRedemptionPlot"];
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath: @"opacity"];
    fadeIn.beginTime = CACurrentMediaTime() + 0.5;
    fadeIn.fromValue = [NSNumber numberWithFloat: 0.0];
    fadeIn.toValue = [NSNumber numberWithFloat: 1.0];
    fadeIn.duration = 1;
    fadeIn.repeatCount = 1;
    fadeIn.delegate = self;
    [plot addAnimation: fadeIn forKey: nil];

    plot = (id)[graph plotWithIdentifier : @"rawRedemptionPlot"];
    fadeIn = [CABasicAnimation animationWithKeyPath: @"opacity"];
    fadeIn.beginTime = CACurrentMediaTime() + 0.5;
    fadeIn.fromValue = [NSNumber numberWithFloat: 0.0];
    fadeIn.toValue = [NSNumber numberWithFloat: 1.0];
    fadeIn.duration = 1;
    fadeIn.repeatCount = 1;
    fadeIn.delegate = nil;
    [plot addAnimation: fadeIn forKey: nil];
}

- (void)dealloc
{
    free(monthTimePoints);
    free(monthInterestValues);
    free(monthInterestValues2);
    free(monthRedemptionValues);
    free(monthRedemptionValues2);

    free(yearTimePoints);
    free(yearInterestValues);
    free(yearInterestValues2);
    free(yearRedemptionValues);
    free(yearRedemptionValues2);
}

- (void)animationDidStart: (CAAnimation *)anim
{
    CPTPlot *plot = (id)[graph plotWithIdentifier : @"mainRedemptionPlot"];
    plot.opacity = 1; // We can't set the final opacity earlier since the animation is delayed.
    plot = (id)[graph plotWithIdentifier : @"rawRedemptionPlot"];
    plot.opacity = 1;
}

- (void)setupGraph
{
    self.allowPinchScaling = NO;

    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame : NSRectToCGRect(self.bounds)];
    self.hostedGraph = graph;

    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.allowsMomentum = YES;
    plotSpace.delegate = self;

    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(0)
                                                           length: CPTDecimalFromDouble(10000)];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;

    // Graph padding
    graph.paddingLeft = 0;
    graph.paddingTop = 0;
    graph.paddingRight = 0;
    graph.paddingBottom = 0;
    graph.fill = nil;

    CPTPlotAreaFrame *frame = graph.plotAreaFrame;
    frame.paddingLeft = 70;
    frame.paddingRight = 20;
    frame.paddingTop = 20;
    frame.paddingBottom = 20;
    frame.masksToBorder = NO;
    frame.masksToBounds = NO;

    [self setupPlots];
    [self setUpAxes];
}

- (void)setupPlots
{
    CPTBarPlot *plot = [[CPTBarPlot alloc] init];
    plot.opacity = 0;
    plot.alignsPointsToPixels = YES;

    plot.delegate = self;
    plot.dataSource = self;
    plot.identifier = @"mainRedemptionPlot";
    plot.lineStyle = nil;
    plot.fill = nil;
    plot.barBasesVary = YES;
    plot.barCornerRadius = 3.0;
    plot.barBaseCornerRadius = 3.0;
    plot.barsAreHorizontal = NO;
    plot.barWidth = CPTDecimalFromFloat(0.65);

    [graph addPlot: plot];

    plot = [[CPTBarPlot alloc] init];
    plot.opacity = 0;
    plot.alignsPointsToPixels = YES;

    plot.delegate = self;
    plot.dataSource = self;
    plot.identifier = @"rawRedemptionPlot";
    plot.lineStyle = nil;
    plot.fill = [CPTFill fillWithColor: [CPTColor colorWithComponentRed: 0.388 green: 0.382 blue: 0.363 alpha: 0.25]];
    plot.barBasesVary = YES;
    plot.barCornerRadius = 5.0;
    plot.barBaseCornerRadius = 5.0;
    plot.barsAreHorizontal = NO;
    plot.barWidth = CPTDecimalFromFloat(0.9);

    [graph addPlot: plot];
}

- (void)setUpAxes
{
    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 1.0f;
    majorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.1];

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 1.0f;
    minorGridLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent: 0.05];

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.minorTicksPerInterval = 0;
    x.majorGridLineStyle = majorGridLineStyle;
    x.minorGridLineStyle = nil;

    x.preferredNumberOfMajorTicks = 10;

    x.labelTextStyle = nil;

    CPTXYAxis *y = axisSet.yAxis;
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [[CPTColor blackColor] colorWithAlphaComponent: 0.3];
    textStyle.fontName = @"ArialNarrow-Bold";
    textStyle.fontSize = 11.0;
    y.labelTextStyle = textStyle;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset: 0];

    y.majorGridLineStyle = majorGridLineStyle;
    y.minorGridLineStyle = minorGridLineStyle;
    y.minorTicksPerInterval = 4;

    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.axisLineStyle = nil;

    // The second y axis is used as the current location identifier.
    indicatorLine = [[CPTXYAxis alloc] init];
    indicatorLine.hidden = YES;
    indicatorLine.coordinate = CPTCoordinateY;
    indicatorLine.plotSpace = graph.defaultPlotSpace;
    indicatorLine.labelingPolicy = CPTAxisLabelingPolicyNone;
    indicatorLine.separateLayers = NO;
    indicatorLine.preferredNumberOfMajorTicks = 0;
    indicatorLine.minorTicksPerInterval = 0;

    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 1;
    lineStyle.lineColor = [CPTColor colorWithGenericGray: 64 / 255.0];
    lineStyle.lineCap = kCGLineCapRound;
    lineStyle.dashPattern = lineStyle.dashPattern = @[@10.0f, @5.0f];
    indicatorLine.axisLineStyle = lineStyle;
    indicatorLine.majorTickLineStyle = nil;

    axisSet.axes = @[x, y, indicatorLine];

    NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed: 0.388 green: 0.382 blue: 0.363 alpha: 1.000],
                                 NSFontAttributeName: [NSFont fontWithName: PreferenceController.mainFontNameBold size: 12]};

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"AP968", nil)
                                                                              attributes: attributes];
    CPTLayerAnnotation *titleAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer: graph.plotAreaFrame];
    CPTTextLayer       *titleLayer = [[CPTTextLayer alloc] init];
    titleAnnotation.contentLayer = titleLayer;
    titleAnnotation.rectAnchor = CPTRectAnchorLeft;
    titleAnnotation.rotation = pi / 2;
    titleLayer.attributedText = title;
    [graph addAnnotation: titleAnnotation];
}

- (void)updateGraphUsingMinimalTickCount: (BOOL)flag
{
    int totalUnits;
    int tickCount;
    if (currentGrouping == NSCalendarUnitMonth) {
        tickCount = 12;
        totalUnits = (numberOfMonths > 1) ? monthTimePoints[numberOfMonths - 1] + 1 : 0;
        if (totalUnits < tickCount) {
            totalUnits = tickCount;
        }
    } else {
        tickCount = 10;
        totalUnits = (numberOfYears > 1) ? yearTimePoints[numberOfYears - 1] + 1 : 0;
        if (totalUnits < tickCount) {
            totalUnits = tickCount;
        }
    }

    // Set the available plot space depending on the min, max and day values we found.
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;

    // Horizontal range.
    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(-0.5)
                                                           length: CPTDecimalFromDouble(totalUnits)];
    plotSpace.globalXRange = plotRange;

    float from = [self distanceFromDate: referenceDate toDate: fromDate];
    float to = [self distanceFromDate: referenceDate toDate: toDate];
    if (flag && (to - from < tickCount)) {
        to = from + tickCount;
    }
    plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(from - 0.5) length: CPTDecimalFromFloat(to - from)];
    plotSpace.xRange = plotRange;

    CPTXYAxisSet *axisSet = (id)graph.axisSet;
    CPTXYAxis    *x = axisSet.xAxis;
    x.preferredNumberOfMajorTicks = tickCount;

    // Recreate the time formatter to apply the new reference date. Just setting the date on the existing
    // formatter is not enough.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;

    PecuniaPlotTimeFormatter *timeFormatter = [[PecuniaPlotTimeFormatter alloc] initWithDateFormatter: dateFormatter
                                                                                         calendarUnit: currentGrouping];
    timeFormatter.useMonthNames = YES;
    timeFormatter.referenceDate = [referenceDate lowDate];
    x.labelFormatter = timeFormatter;

    // The currency of the main category can change so update the y axis label formatter as well.
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.usesSignificantDigits = YES;
    currencyFormatter.minimumFractionDigits = 0;
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.currencyCode = @"EUR";
    currencyFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", currencyFormatter.currencySymbol];
    axisSet.yAxis.labelFormatter = currencyFormatter;
}

- (void)updateVerticalGraphRange
{
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    CPTXYAxisSet   *axisSet = (id)graph.axisSet;

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
    NSDecimalNumber *roundedMin = [[NSDecimalNumber decimalNumberWithDecimal: decimalMinValue] roundToUpperOuter];
    NSDecimalNumber *roundedMax;
    if (useDefault) {
        roundedMax = [NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue];
    } else {
        roundedMax = [[NSDecimalNumber decimalNumberWithDecimal: decimalMaxValue] roundToUpperOuter];
    }

    // Let the larger area (negative or positive) determine the size of the major tick range.
    NSDecimalNumber *minAbsolute = [roundedMin abs];
    NSDecimalNumber *maxAbsolute = [roundedMax abs];
    float           interval;
    if ([minAbsolute compare: maxAbsolute] == NSOrderedDescending) {
        interval = [self intervalFromRange: minAbsolute];
    } else {
        interval = [self intervalFromRange: maxAbsolute];
    }

    y.majorIntervalLength = CPTDecimalFromFloat(interval);
    CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: roundedMin.decimalValue
                                                           length: [[roundedMax decimalNumberBySubtracting: roundedMin] decimalValue]];
    plotSpace.globalYRange = plotRange;
    plotSpace.yRange = plotRange;
}

- (CPTPlotSpaceAnnotation *)createAnnotationAtPosition: (CGPoint)position
{
    NSMutableArray *point = [[NSMutableArray alloc] initWithCapacity: 2];
    NSDecimal      decimal = CPTDecimalFromDouble(position.x);
    [point addObject: [NSDecimalNumber decimalNumberWithDecimal: decimal]];
    decimal = CPTDecimalFromDouble(position.y);
    [point addObject: [NSDecimalNumber decimalNumberWithDecimal: decimal]];
    CPTPlotSpaceAnnotation *annotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace: graph.defaultPlotSpace
                                                                           anchorPlotPoint: point];
    return annotation;

}

- (void)updateDataForDate: (ShortDate *)date
                   amount: (double)amount
             interestRate: (double)rate
                   redeem: (double)redeemValue
        specialRedemption: (NSDictionary *)unscheduledRepayment
{
    ++peerUpdateCount;

    free(monthTimePoints);
    free(monthInterestValues);
    free(monthInterestValues2);
    free(monthRedemptionValues);
    free(monthRedemptionValues2);

    free(yearTimePoints);
    free(yearInterestValues);
    free(yearInterestValues2);
    free(yearRedemptionValues);
    free(yearRedemptionValues2);

    referenceDate = date;

    NSDecimal       decimal = CPTDecimalFromDouble(1200);
    NSDecimalNumber *thousandTwoHundered = [NSDecimalNumber decimalNumberWithDecimal: decimal];

    // Initial interest rate and redeem (which in sum represets the constant monthly rate).
    decimal = CPTDecimalFromDouble(rate);
    NSDecimalNumber *interestRate = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    decimal = CPTDecimalFromDouble(amount);
    NSDecimalNumber *borrowedAmount = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    decimal = CPTDecimalFromDouble(redeemValue);
    NSDecimalNumber *redeem = [NSDecimalNumber decimalNumberWithDecimal: decimal];

    interestRate = [interestRate decimalNumberByDividingBy: thousandTwoHundered];
    interestRate = [interestRate decimalNumberByMultiplyingBy: borrowedAmount];
    interestRate = [interestRate decimalNumberByRoundingAccordingToBehavior: roundUp];

    redeem = [redeem decimalNumberByDividingBy: thousandTwoHundered];
    redeem = [redeem decimalNumberByMultiplyingBy: borrowedAmount];
    redeem = [redeem decimalNumberByRoundingAccordingToBehavior: roundDown];

    monthlyRate = [interestRate decimalNumberByAdding: redeem];

    // Compute total maturity (in number of months).
    decimal = CPTDecimalFromInt(12);
    NSDecimalNumber *twelf = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    NSDecimalNumber *annuity = [monthlyRate decimalNumberByMultiplyingBy: twelf];

    NSDecimalNumber *repaymentRate = [annuity decimalNumberByDividingBy: borrowedAmount];
    decimal = CPTDecimalFromDouble(rate / 100);
    NSDecimalNumber *convertedRate = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    repaymentRate = [repaymentRate decimalNumberBySubtracting: convertedRate];

    // Change 12 if there is a different number of payments per year.
    // The actual number of months depends on special redemptions during that time.
    // This time is dynamically determined and kept in realNumberOfMonths and realNumberOfYears, respectively.
    numberOfMonths = ceil(log(1 + convertedRate.doubleValue / repaymentRate.doubleValue) / log(1 + convertedRate.doubleValue / 12));

    monthTimePoints = malloc(numberOfMonths * sizeof(double));
    monthInterestValues = malloc(numberOfMonths * sizeof(double));
    monthInterestValues2 = malloc(numberOfMonths * sizeof(double));
    monthRedemptionValues = malloc(numberOfMonths * sizeof(double));
    monthRedemptionValues2 = malloc(numberOfMonths * sizeof(double));

    ShortDate *endDate = [referenceDate dateByAddingUnits: numberOfMonths byUnit: NSCalendarUnitMonth];
    endDate = [endDate dateByAddingUnits: -1 byUnit: NSCalendarUnitDay];
    numberOfYears = endDate.year - referenceDate.year + 1;
    yearTimePoints = malloc(numberOfYears * sizeof(double));
    yearInterestValues = malloc(numberOfYears * sizeof(double));
    yearInterestValues2 = malloc(numberOfYears * sizeof(double));
    yearRedemptionValues = malloc(numberOfYears * sizeof(double));
    yearRedemptionValues2 = malloc(numberOfYears * sizeof(double));

    // Select a meaningful initial display window for the entire range.
    NSUInteger units = currentGrouping == NSCalendarUnitMonth ? 12 : 10;
    ShortDate  *now = [ShortDate currentDate];
    if ([referenceDate compare: now] == NSOrderedDescending) {
        // First date is after the current date. Our initial window is hence just the first "units" months/years.
        fromDate = referenceDate;
        toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
    } else {
        NSUInteger count = currentGrouping == NSCalendarUnitMonth ? numberOfMonths : numberOfYears;
        toDate = [referenceDate dateByAddingUnits: count byUnit: currentGrouping];
        if ([toDate compare: now] == NSOrderedAscending) {
            // The end is already in the past. The initial window is hence the last "units" months/years.
            if (count >= 12) {
                fromDate = [toDate dateByAddingUnits: -units byUnit: currentGrouping];
            } else {
                // Too few units for the entire range. Start with the first date and
                // show a range of the given units, even if there aren't enough entries.
                fromDate = referenceDate;
                toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
            }
        } else {
            // Most common case: we are within an active range.
            // Start with "units - 1" entries back and 1 in the future or full units back if we are at the end of the range.
            if ([now.firstDayInMonth compare: toDate.firstDayInMonth] == NSOrderedSame) {
                fromDate = [toDate dateByAddingUnits: -units byUnit: currentGrouping];
            } else {
                if (count >= units) {
                    toDate = [now dateByAddingUnits: 1 byUnit: currentGrouping];
                    fromDate = [toDate dateByAddingUnits: -units byUnit: currentGrouping];
                } else {
                    fromDate = referenceDate;
                    toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
                }
            }

            // If we set the start date to before the actual start then shift the entire range to
            // begin at the actual start date.
            if ([fromDate compare: referenceDate] == NSOrderedAscending) {
                fromDate = referenceDate;
                toDate = [fromDate dateByAddingUnits: units byUnit: currentGrouping];
            }
        }
    }

    // Note: unscheduledRepayment contains NSNumber stored under a ShortDate hash which must address
    //       the first day in a month where the payment was done. The actual day doesn't matter
    //       as an unscheduled repayment is always taken into account in the next time period only.
    NSDecimalNumber *run = borrowedAmount;
    NSDecimalNumber *run2 = borrowedAmount; // Run without unscheduled payments.
    NSDecimalNumber *currentRedemption = redeem;
    NSDecimalNumber *currentRedemption2 = redeem; // Redeem without unscheduled payments.

    decimal = CPTDecimalFromFloat(rate);
    NSDecimalNumber *rateFactor = [NSDecimalNumber decimalNumberWithDecimal: decimal];
    rateFactor = [rateFactor decimalNumberByDividingBy: thousandTwoHundered];
    NSUInteger yearIndex = 0;
    ShortDate *currentDate = fromDate.firstDayInMonth;
    BOOL foundEarlierFullPayOff = NO;
    for (NSUInteger i = 0; i < numberOfMonths; ++i) {
        monthTimePoints[i] = i;

        BOOL allPaidOff = run.doubleValue <= 0;
        monthInterestValues[i] = allPaidOff ? NAN : currentRedemption.doubleValue - monthlyRate.doubleValue;
        monthRedemptionValues[i] = allPaidOff ? NAN : currentRedemption.doubleValue;

        if ([run compare: run2] == NSOrderedSame) {
            monthInterestValues2[i] = NAN;
            monthRedemptionValues2[i] = NAN;
        } else {
            monthInterestValues2[i] = currentRedemption2.doubleValue - monthlyRate.doubleValue;
            monthRedemptionValues2[i] = currentRedemption2.doubleValue;
        }

        if (currentDate.month == 1 || i == 0) {
            yearTimePoints[yearIndex] = yearIndex;
            yearInterestValues[yearIndex] = monthInterestValues[i];
            yearRedemptionValues[yearIndex] = monthRedemptionValues[i];

            if ([run compare: run2] == NSOrderedSame) {
                yearInterestValues2[yearIndex] = NAN;
                yearRedemptionValues2[yearIndex] = NAN;
            } else {
                yearInterestValues2[yearIndex] = monthInterestValues2[i];
                yearRedemptionValues2[yearIndex] = monthRedemptionValues2[i];
            }

            yearIndex++;
        }

        if (run.doubleValue > 0) {
            run = [run decimalNumberBySubtracting: currentRedemption];

            NSNumber *special = unscheduledRepayment[@(currentDate.hash)];
            if (special != nil) {
                decimal = CPTDecimalFromDouble(special.doubleValue);
                NSDecimalNumber *temp = [NSDecimalNumber decimalNumberWithDecimal: decimal];
                run = [run decimalNumberBySubtracting: temp];
            }
            if (run.doubleValue <= 0) {
                // We reached the actual end of the payment time frame.
                run = [NSDecimalNumber decimalNumberWithString: @"0"];
                foundEarlierFullPayOff = YES;
                realNumberOfMonths = i + 1;
                realNumberOfYears = currentDate.year - fromDate.year + 1;
            }
            NSDecimalNumber *currentInterestRate = [run decimalNumberByMultiplyingBy: rateFactor
                                                                        withBehavior: bankersRounding];
            currentRedemption = [monthlyRate decimalNumberBySubtracting: currentInterestRate];
        }

        // The run value for the normal series never goes to zero before the end of the entire range.
        run2 = [run2 decimalNumberBySubtracting: currentRedemption2];

        NSDecimalNumber *currentInterestRate = [run2 decimalNumberByMultiplyingBy: rateFactor
                                                                     withBehavior: bankersRounding];
        currentRedemption2 = [monthlyRate decimalNumberBySubtracting: currentInterestRate];

        currentDate = [currentDate dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth];
    }
    if (yearIndex < numberOfYears) {
        yearTimePoints[numberOfYears - 1] = yearIndex;
    }

    if (!foundEarlierFullPayOff) {
        realNumberOfMonths = numberOfMonths;
        realNumberOfYears = numberOfYears;
    }
    min = monthInterestValues[0];
    max = monthRedemptionValues[realNumberOfMonths - 1];

    [self updateGraphUsingMinimalTickCount: YES];
    [self updateVerticalGraphRange];
    [graph reloadData];
    --peerUpdateCount;
}

/**
 * Called when the users moved the mouse over the graph.
 * Move the indicator line to the current mouse position and update the info annotation.
 *
 * The location is given in plot area coordinates.
 */
- (void)updateTrackLineAndInfoDisplay: (CGFloat)location
{
    if (numberOfMonths < 1) {
        return;
    }

    // Determine the content for the info layer.
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    CGPoint        point = CGPointMake(location, 0);

    NSDecimal dataPoint[2];
    [plotSpace plotPoint: dataPoint numberOfCoordinates: 2 forPlotAreaViewPoint: point];
    double timePoint = CPTDecimalDoubleValue(dataPoint[0]);

    // Check if the time point is within the visible range.
    if (timePoint < plotSpace.xRange.minLimitDouble || timePoint > plotSpace.xRange.maxLimitDouble) {
        [self hideInfoComponents];
        lastInfoTimePoint = 0;
        return;
    }

    // Find closest point in our time points that is before the computed time value.
    NSUInteger index = timePoint < 0 ? 0 : round(timePoint);

    NSDecimal snapPoint[2] = {0, 0};
    snapPoint[0] = CPTDecimalFromInteger(index);
    CGPoint targetPoint = [plotSpace plotAreaViewPointForPlotPoint: snapPoint numberOfCoordinates: 2];

    // Another check for visiblity, now with rounded coordinate.
    if (targetPoint.x < 0 || index > plotSpace.xRange.maxLimitDouble) {
        [self hideInfoComponents];
        lastInfoTimePoint = 0;
        return;
    }

    location = targetPoint.x;

    if (lastInfoTimePoint == 0 || (index != lastInfoTimePoint)) {
        lastInfoTimePoint = index;

        [self showInfoComponents];

        /* TODO: see comment for the other indicatorLine change code.
        if (indicatorAnimation == nil) {
            indicatorAnimation = [CPTAnimation animate: indicatorLine
                                              property: @"orthogonalCoordinateDecimal"
                                           fromDecimal: indicatorLine.orthogonalCoordinateDecimal
                                             toDecimal: CPTDecimalFromUnsignedInteger(index)
                                              duration: 0.125
                                             withDelay: 0
                                        animationCurve: CPTAnimationCurveCubicInOut
                                              delegate: self];
        } else {
            indicatorAnimation.canceled = YES;
        }
         */

        indicatorLine.orthogonalCoordinateDecimal = CPTDecimalFromFloat(index);
    }
}

- (void)showInfoComponents
{
    if (peerUpdateCount > 0) {
        return;
    }
    ++peerUpdateCount;
    [indicatorLine fadeIn];
    [peerGraph showInfoComponents];
    --peerUpdateCount;
}

- (void)hideInfoComponents
{
    if (peerUpdateCount > 0) {
        return;
    }

    ++peerUpdateCount;
    [indicatorLine fadeOut];
    [peerGraph hideInfoComponents];
    --peerUpdateCount;
}

- (void)switchToMonthMode
{
    currentGrouping = NSCalendarUnitMonth;
    unsigned month = 1;
    if (lastInfoTimePoint == 0) {
        month = referenceDate.month;
    }
    fromDate = [ShortDate dateWithYear: referenceDate.year + lastInfoTimePoint month: month day: 1];
    toDate = [fromDate dateByAddingUnits: 12 byUnit: NSCalendarUnitMonth];

    int totalUnits;
    int tickCount;
    tickCount = 12;
    totalUnits = (numberOfMonths > 1) ? monthTimePoints[numberOfMonths - 1] + 1 : 0;
    if (totalUnits < tickCount) {
        totalUnits = tickCount;
    }

    lastInfoTimePoint *= 12; // Convert to month index.
                             // Make the bar fill the entire width.

    // Only animate the bar widths. The peer graph notifications for the plot range
    // will animate our range then.
    CPTBarPlot *plot = (id)[graph plotWithIdentifier : @"mainRedemptionPlot"];
    [CPTAnimation animate: plot
                 property: @"barWidth"
              fromDecimal: plot.barWidth
                toDecimal: CPTDecimalFromCGFloat(1)
                 duration: ANIMATION_TIME
                withDelay: 0
           animationCurve: CPTAnimationCurveCubicInOut
                 delegate: nil];

    plot = (id)[graph plotWithIdentifier : @"rawRedemptionPlot"];
    [CPTAnimation animate: plot
                 property: @"barWidth"
              fromDecimal: plot.barWidth
                toDecimal: CPTDecimalFromCGFloat(1)
                 duration: ANIMATION_TIME
                withDelay: 0
           animationCurve: CPTAnimationCurveCubicInOut
                 delegate: self];
}

/**
 * Called when the range animation has ended.
 */
- (void)finishSwitchToMonthMode
{
    ++peerUpdateCount;
    CPTBarPlot *plot = (id)[graph plotWithIdentifier : @"mainRedemptionPlot"];
    plot.barWidth = CPTDecimalFromFloat(0.65);

    plot = (id)[graph plotWithIdentifier : @"rawRedemptionPlot"];
    plot.barWidth = CPTDecimalFromFloat(0.9);

    [self updateGraphUsingMinimalTickCount: YES];
    [self updateVerticalGraphRange];
    [graph reloadData];
    --peerUpdateCount;
}

- (void)switchToYearMode
{
    // Switch immediately to a year range with the current year taking the full width.
    // The notifications of the peer graph will then animate it to the final range.
    toDate = [fromDate dateByAddingUnits: 1 byUnit: NSCalendarUnitYear];
    lastInfoTimePoint /= 12; // Convert to year index.
    currentGrouping = NSCalendarUnitYear;

    [self updateGraphUsingMinimalTickCount: NO];
    [self updateVerticalGraphRange];
    [graph reloadData];

    // Now compute the real dates. Center the current year.
    fromDate = [ShortDate dateWithYear: fromDate.year - 5 month: 1 day: 1];
    if ([fromDate compare: referenceDate] == NSOrderedAscending) {
        fromDate = referenceDate;
    }
    toDate = [fromDate dateByAddingUnits: 10 byUnit: NSCalendarUnitYear];
}

- (void)changePlotRange: (CPTPlotRange *)newRange
{
    ++peerUpdateCount;
    CPTXYPlotSpace *plotSpace = (id)graph.defaultPlotSpace;
    plotSpace.xRange = newRange;
    fromDate = [referenceDate dateByAddingUnits: newRange.locationDouble byUnit: currentGrouping];
    toDate = [fromDate dateByAddingUnits: newRange.lengthDouble byUnit: currentGrouping];
    --peerUpdateCount;
}

#pragma mark - Event handling

- (void)mouseMoved: (NSEvent *)theEvent
{
    [super mouseMoved: theEvent];

    CPTXYPlotSpace *plotSpace = (id)[self hostedGraph].defaultPlotSpace;
    if (!plotSpace.allowsUserInteraction) {
        return;
    }

    NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    CGPoint mouseLocation = NSPointToCGPoint(location);
    CGPoint pointInHostedGraph = [self.layer convertPoint: mouseLocation toLayer: self.hostedGraph.plotAreaFrame.plotArea];
    [self updateTrackLineAndInfoDisplay: pointInHostedGraph.x];
    [peerGraph updateTrackLineAndInfoDisplay: pointInHostedGraph.x];
}

- (void)mouseExited: (NSEvent *)theEvent
{
    [super mouseExited: theEvent];
    lastInfoTimePoint = 0;
    [self hideInfoComponents];

    [peerGraph showGeneralInfo];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];

    if (trackingArea != nil) {
        [self removeTrackingArea: trackingArea];
    }

    trackingArea = [[NSTrackingArea alloc] initWithRect: self.bounds
                                                options: NSTrackingMouseEnteredAndExited
                                                         | NSTrackingMouseMoved
                                                         | NSTrackingActiveInKeyWindow
                                                  owner: self
                                               userInfo: nil];
    [self addTrackingArea: trackingArea];
}

#pragma mark - Utility functions

- (void)updateColors
{
    [graph reloadData];
}

- (int)distanceFromDate: (ShortDate *)from toDate: (ShortDate *)to
{
    return [from unitsToDate: to byUnit: currentGrouping];
}

/**
 * Determines the optimal length of a major interval length for a plot depending on the
 * overall size of the range. This is a bit tricky as we want sharp and easy intervals
 * for optimal perceptibility. The given range is already rounded up to two most significant digits.
 */
- (float)intervalFromRange: (NSDecimalNumber *)range
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
        return convertedValue <= 5 ? 2 : 4;
    }

    float base = 10;
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

#pragma mark - Plot data source methods

- (NSUInteger)numberOfRecordsForPlot: (CPTPlot *)plot
{
    return (currentGrouping == NSCalendarUnitMonth) ? numberOfMonths : numberOfYears;
}

- (double *)doublesForPlot: (CPTPlot *)plot field: (NSUInteger)fieldEnum recordIndexRange: (NSRange)indexRange
{
    NSString *identifier = (id)plot.identifier;
    switch (fieldEnum)
    {
        case CPTBarPlotFieldBarLocation:
            if (currentGrouping == NSCalendarUnitMonth) {
                return &monthTimePoints[indexRange.location];
            }
            return &yearTimePoints[indexRange.location];

        case CPTBarPlotFieldBarBase:
            if ([identifier isEqualToString: @"mainRedemptionPlot"]) {
                if (currentGrouping == NSCalendarUnitMonth) {
                    return &monthInterestValues[indexRange.location];
                }
                return &yearInterestValues[indexRange.location];
            } else {
                if (currentGrouping == NSCalendarUnitMonth) {
                    return &monthInterestValues2[indexRange.location];
                }
                return &yearInterestValues2[indexRange.location];
            }

        case CPTScatterPlotFieldY:
            if ([identifier isEqualToString: @"mainRedemptionPlot"]) {
                if (currentGrouping == NSCalendarUnitMonth) {
                    return &monthRedemptionValues[indexRange.location];
                }
                return &yearRedemptionValues[indexRange.location];
            } else {
                if (currentGrouping == NSCalendarUnitMonth) {
                    return &monthRedemptionValues2[indexRange.location];
                }
                return &yearRedemptionValues2[indexRange.location];
            }
    }
    return nil;
}

- (CPTLayer *)dataLabelForPlot: (CPTPlot *)plot recordIndex: (NSUInteger)index
{
    return (id)[NSNull null];
}

#pragma mark - CPTBarPlot data source delegate methods

- (CPTFill *)barFillForBarPlot: (CPTBarPlot *)barPlot recordIndex: (NSUInteger)idx
{
    NSString *identifier = (id)barPlot.identifier;
    double *interestValues;
    double alpha;
    if ([identifier isEqualToString: @"mainRedemptionPlot"]) {
        if (currentGrouping == NSCalendarUnitMonth) {
            interestValues = monthInterestValues;
        } else {
            interestValues = yearInterestValues;
        }
        alpha = 0.75;
    } else {
        if (currentGrouping == NSCalendarUnitMonth) {
            interestValues = monthInterestValues2;
        } else {
            interestValues = yearInterestValues2;
        }
        alpha = 0.30;
    }

    CPTGradient *gradient = [[CPTGradient alloc] init];
    gradient.angle = 90;

    CGColorRef  positiveLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Positive Plot Gradient (low)"] colorWithAlphaComponent: 1]);
    CGColorRef  negativeLowColor = CGColorCreateFromNSColor([[NSColor applicationColorForKey: @"Negative Plot Gradient (low)"] colorWithAlphaComponent: 0.9]);

    CGFloat splitPoint = -interestValues[idx] / monthlyRate.doubleValue;

    CPTColor *color = [[CPTColor colorWithCGColor: negativeLowColor] colorWithAlphaComponent: alpha];
    gradient = [gradient addColorStop: color atPosition: 0];
    color = [[CPTColor colorWithCGColor: negativeLowColor] colorWithAlphaComponent: alpha];
    gradient = [gradient addColorStop: color atPosition: splitPoint];
    color = [[CPTColor colorWithCGColor: positiveLowColor] colorWithAlphaComponent: alpha];
    gradient = [gradient addColorStop: color atPosition: splitPoint];
    color = [[CPTColor colorWithCGColor: positiveLowColor] colorWithAlphaComponent: alpha];
    gradient = [gradient addColorStop: color atPosition: 1];

    CGColorRelease(positiveLowColor);
    CGColorRelease(negativeLowColor);

    return [CPTFill fillWithGradient: gradient];
}

#pragma mark - Plot space delegate methods

- (CGPoint)plotSpace: (CPTPlotSpace *)space willDisplaceBy: (CGPoint)proposedDisplacementVector
{
    [self hideInfoComponents];

    proposedDisplacementVector.y = 0;
    return proposedDisplacementVector;
}

-(CPTPlotRange *)plotSpace: (CPTPlotSpace *)space
     willChangePlotRangeTo: (CPTPlotRange *)newRange
             forCoordinate: (CPTCoordinate)coordinate
{
    if (peerUpdateCount > 0 || coordinate != CPTCoordinateX) {
        return newRange;
    }

    ++peerUpdateCount;
    [peerGraph changePlotRange: newRange];
    --peerUpdateCount;
    return newRange;
}

#pragma mark - Coreplot delegate methods

- (void)animationDidFinish: (CPTAnimationOperation *)operation
{
    if (operation == indicatorAnimation) {
        indicatorAnimation = nil;
    } else {
        [self finishSwitchToMonthMode];
    }
}

- (void)animationCancelled: (CPTAnimationOperation *)operation
{
    if (operation == indicatorAnimation) {
        indicatorAnimation = nil;
    } else {
        [self finishSwitchToMonthMode];
    }
}

@end

#pragma mark - SaveAndRedeemCard implementation

@interface SaveAndRedeemCard ()
{
@private
    PrincipalBalanceGraph *graph1;
    RedemptionGraph *graph2;

    NSNumberFormatter *infoTextFormatter;
    NSTextView        *detailsField;

    double     currentBalance;
    double     currentBalance2;
    double     currentPaidOff;
    double     currentPaidOff2;
    double     currentDebt;
    double     currentDebt2;
    double     currentRedemption;
    double     currentRedemption2;
    NSUInteger currentTime;
    NSUInteger currentTime2;

    NSString *positiveColorHTML;
    NSString *negativeColorHTML;
    NSString *valueColorHTML1;
    NSString *valueColorHTML2;
}

@end

@implementation SaveAndRedeemCard

+ (BOOL)isConfigurable
{
    return YES;
}

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        NSString *currency = @"EUR"; // We may later make this configurable.
        infoTextFormatter = [[NSNumberFormatter alloc] init];
        infoTextFormatter.usesSignificantDigits = NO;
        infoTextFormatter.minimumFractionDigits = 2;
        infoTextFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
        infoTextFormatter.currencyCode = currency;
        infoTextFormatter.zeroSymbol = [NSString stringWithFormat: @"0 %@", infoTextFormatter.currencySymbol];

        positiveColorHTML = [[NSColor applicationColorForKey: @"Positive Plot Gradient (low)"] colorAsHTML];
        negativeColorHTML = [[NSColor applicationColorForKey: @"Negative Plot Gradient (low)"] colorAsHTML];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults addObserver: self forKeyPath: @"colors" options: 0 context: UserDefaultsBindingContext];

        LocalSettingsController *settings = LocalSettingsController.sharedSettings;
        [settings addObserver: self forKeyPath: @"loanValue" options: 0 context: UserDefaultsBindingContext];
        [settings addObserver: self forKeyPath: @"interestRate" options: 0 context: UserDefaultsBindingContext];
        [settings addObserver: self forKeyPath: @"redemptionRate" options: 0 context: UserDefaultsBindingContext];
        [settings addObserver: self forKeyPath: @"loanStartDate" options: 0 context: UserDefaultsBindingContext];
        [settings addObserver: self forKeyPath: @"specialRedemptions" options: 0 context: UserDefaultsBindingContext];

        [self setupUI];
    }

    return self;
}

- (void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: @"colors"];

    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    [settings removeObserver: self forKeyPath: @"loanValue"];
    [settings removeObserver: self forKeyPath: @"interestRate"];
    [settings removeObserver: self forKeyPath: @"redemptionRate"];
    [settings removeObserver: self forKeyPath: @"loanStartDate"];
    [settings removeObserver: self forKeyPath: @"specialRedemptions"];
}

- (void)setupUI
{
    detailsField = [[NSTextView alloc] init];
    detailsField.drawsBackground = NO;
    detailsField.editable = NO;
    detailsField.alignment = NSCenterTextAlignment;
    detailsField.font = [NSFont fontWithName: @"HelveticaNeue" size: 14];
    [self addSubview: detailsField];

    [self updateGraphs];
}

- (void)updateGraphs
{
    LocalSettingsController *settings = LocalSettingsController.sharedSettings;
    NSNumber *total = settings[@"loanValue"];
    NSNumber *interest = settings[@"interestRate"];
    NSNumber *redemption = settings[@"redemptionRate"];
    NSDate *startDate = settings[@"loanStartDate"];
    NSArray *specialRedemptions = settings[@"specialRedemptions"];

    NSMutableDictionary *unscheduled = [NSMutableDictionary dictionary];
    for (NSDictionary *entry in specialRedemptions) {
        unscheduled[@([entry[@"date"] hash])] = entry[@"amount"];
    }

    BOOL fadeIn = NO;
    if (total.doubleValue > 0 && interest.doubleValue > 0 && redemption.doubleValue > 0 && startDate != nil) {
        if (graph2 == nil) {
            fadeIn = YES;
            graph2 = [[RedemptionGraph alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                                  startDate: [ShortDate dateWithDate: startDate]
                                                totalAmount: total.doubleValue
                                               interestRate: interest.doubleValue
                                                     redeem: redemption.doubleValue
                                          specialRedemption: unscheduled
                                                      owner: self];
            [self addSubview: graph2];
        } else {
            [graph2 updateDataForDate: [ShortDate dateWithDate: startDate]
                               amount: total.doubleValue
                         interestRate: interest.doubleValue
                               redeem: redemption.doubleValue
                    specialRedemption: unscheduled];

        }

        if (graph1 == nil) {
            fadeIn = YES;
            graph1 = [[PrincipalBalanceGraph alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)
                                                        startDate: [ShortDate dateWithDate: startDate]
                                                      totalAmount: total.doubleValue
                                                     interestRate: interest.doubleValue
                                                           redeem: redemption.doubleValue
                                                specialRedemption: unscheduled
                                                            owner: self];
            [self addSubview: graph1];
        } else {
            [graph1 updateDataForDate: [ShortDate dateWithDate: startDate]
                               amount: total.doubleValue
                         interestRate: interest.doubleValue
                               redeem: redemption.doubleValue
                    specialRedemption: unscheduled];

        }

        if (graph1 != nil && graph2 != nil) {
            graph1->peerGraph = graph2;
            graph2->peerGraph = graph1;

            if (fadeIn ) {
                [graph1 showGraph];
                [graph2 showGraph];
            }
        }
    } else {
        [graph1 removeFromSuperview];
        graph1 = nil;
        [graph2 removeFromSuperview];
        graph2 = nil;

        NSString *formatString = @"<span style='font-family: HelveticaNeue-Light; font-size: 11pt;"
          " color: #909090'>%@</span>&nbsp;";
        NSString *html = [NSString stringWithFormat: formatString, NSLocalizedString(@"AP972", nil)];
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithHTML: [html dataUsingEncoding: NSUnicodeStringEncoding]
                                                                       documentAttributes: nil];

        NSImage *image = [NSImage imageNamed: @"gear"];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        NSTextAttachmentCell *cell = [[NSTextAttachmentCell alloc] initImageCell: image];
        cell.selectable = NO;
        cell.wraps = NO;
        cell.type = NSImageCellType;
        [attachment setAttachmentCell: cell];
        [text appendAttributedString: [NSAttributedString  attributedStringWithAttachment: attachment]];
        detailsField.textStorage.attributedString = text;
        detailsField.selectable = NO;
    }
    [self resizeSubviewsWithOldSize: self.bounds.size];
}

/**
 * Layouts all charts in a column format.
 */
- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    if (graph1 != nil && graph2 != nil) {
        NSRect frame = self.bounds;
        frame.size.width -= 40;
        frame.size.height = floor(frame.size.height / 2 - 60);
        frame.origin.x = 15;
        frame.origin.y = 30;
        graph1.frame = frame;

        frame.origin.y += frame.size.height - 5;
        frame.size.height += 10;
        graph2.frame = frame;

        frame.origin.y += frame.size.height - 5;
        frame.size.height = NSHeight(self.bounds) - NSMinY(frame) - 25;
        detailsField.frame = frame;
    } else {
        NSRect frame = self.bounds;
        detailsField.frame = NSInsetRect(frame, 30, 0); // Give the text field a width so it can determine its height.
        [detailsField sizeToFit];

        frame.origin.x = (NSWidth(frame) - NSWidth(detailsField.bounds)) / 2;
        frame.origin.y = (NSHeight(frame) - NSHeight(detailsField.bounds)) / 2;
        frame.size = detailsField.frame.size;
        detailsField.frame = frame;
    }
}

- (NSString *)computeTimeString: (NSUInteger)time
{
    NSUInteger years = time / 12;
    NSString *yearString = years == 1 ? NSLocalizedString(@"AP20", nil) : NSLocalizedString(@"AP21", nil);
    NSUInteger months = time % 12;
    NSString *monthString = months == 1 ? NSLocalizedString(@"AP22", nil) : NSLocalizedString(@"AP23", nil);
    if (years == 0) {
        if (months == 0) {
            return @"--";
        }
        return [NSString stringWithFormat: @"%lu %@", months, monthString];
    } else {
        if (months == 0) {
            return [NSString stringWithFormat: @"%lu %@", years, yearString];
        }
        return [NSString stringWithFormat: @"%lu %@, %lu %@", years, yearString, months, monthString];
    }
}

- (NSString *)formatValuePair: (NSString *)value1 second: (NSString *)value2
{
    static NSString *format1 = @"<span style='color: %@'>%@</span>";
    static NSString *format2 = @"<span style='color: %@'>%@</span> / <span style='color: %@'>%@</span>";

    NSString *htmlColor1 = [[NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000] colorAsHTML];
    NSString *htmlColor2 = [[NSColor colorWithCalibratedRed: 0.709 green: 0.698 blue: 0.664 alpha: 1.000] colorAsHTML];
    if (value2 == nil) {
        if (value1 == nil) {
            return [NSString stringWithFormat: format1, htmlColor1, @"0"];
        }
        return [NSString stringWithFormat: format1, htmlColor1, value1];
    }
    if (value1 == nil) {
        return [NSString stringWithFormat: format1, htmlColor1, value2];
    }
    return [NSString stringWithFormat: format2, htmlColor1, value1, htmlColor2, value2];
}

- (void)updateInfoTextFromCurrentValues
{
    static NSString *formatString = @"<table cellspacing = '0' cellpadding = '2' style = 'width: 100%%;"
      " font-family: HelveticaNeue; color: #40678B;'>"
      "  <tr>"
      "    <td align='right' width='40%%'>%@:</td>"
      "    <td width='60%%'><b>%@</b></td>"
      "  </tr>"
      "  <tr>"
      "    <td align='right'>%@:</td>"
      "    <td><b>%@</b></td>"
      "  </tr>"
      "  <tr>"
      "    <td align='right'>%@:</td>"
      "    <td><b>%@</b></td>"
      "  </tr>"
      "</table>";

    NSString *balanceString = [self formatValuePair: isnan(currentBalance) ? nil : [infoTextFormatter stringFromNumber: @(currentBalance)]
                                             second: isnan(currentBalance2) ? nil : [infoTextFormatter stringFromNumber: @(currentBalance2)]];
    NSString *paidOffString = [self formatValuePair: currentPaidOff == 1 ? nil : [NSString stringWithFormat: @"%.2f %%", 100 * currentPaidOff]
                                             second: currentPaidOff2 == 1 ? nil : [NSString stringWithFormat: @"%.2f %%", 100 * currentPaidOff2]];
    NSString *timeString = [self formatValuePair: currentTime == 0 ? nil : [self computeTimeString: currentTime]
                                          second: currentTime2 == 0 ? nil : [self computeTimeString: currentTime2]];
    NSString *html = [NSString stringWithFormat: formatString,
                       NSLocalizedString(@"AP964", nil), balanceString,
                       NSLocalizedString(@"AP965", nil), paidOffString,
                       NSLocalizedString(@"AP966", nil), timeString];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithHTML: [html dataUsingEncoding: NSUnicodeStringEncoding]
                                                                   documentAttributes: nil];
    detailsField.textStorage.attributedString = text;
    detailsField.selectable = YES;
}

- (void)updateInfoForDate: (ShortDate *)date
         principalBalance: (double)balance
        principalBalance2: (double)balance2
                  paidOff: (double)paidOff
                 paidOff2: (double)paidOff2
            remainingTime: (NSUInteger)time
           remainingTime2: (NSUInteger)time2
{
    currentBalance = balance;
    currentBalance2 = balance2;
    currentPaidOff = paidOff;
    currentPaidOff2 = paidOff2;
    currentTime = time;
    currentTime2 = time2;
    [self updateInfoTextFromCurrentValues];
}

- (void)updateInfoWithDebt: (double)debt
                     debt2: (double)debt2
                redemption: (double)redemption
               redemption2: (double)redemption2
{
    currentDebt = debt;
    currentDebt2 = debt2;
    currentRedemption = redemption;
    currentRedemption2 = redemption2;

    // No update here. We will shortly get a call to updateInfoForData:... and will update there.
}

- (void)updateInfoWithBorrowedAmount: (double)amount
                           totalPaid: (double)total
                          totalPaid2: (double)total2
                        interestPaid: (double)interest
                       interestPaid2: (double)interest2
{
    static NSString *formatString = @"<table cellspacing = '0' cellpadding = '2' style = 'width: 100%%;"
      " font-family: HelveticaNeue; color: #40678B;'>"
      "  <tr>"
      "    <td align='right' width='40%%'>%@:</td>"
      "    <td width='60%%'><b>%@</b></td>"
      "  </tr>"
      "  <tr>"
      "    <td align='right' >%@:</td>"
      "    <td><b>%@</b></td>"
      "  </tr>"
      "  <tr>"
      "    <td align='right' >%@:</td>"
      "    <td><b>%@</b></td>"
      "  </tr>"
      "</table>";

    NSString *amountString = [self formatValuePair: [infoTextFormatter stringFromNumber: @(amount)]
                                            second: nil];
    NSString *totalString = [self formatValuePair: isnan(total) ? nil : [infoTextFormatter stringFromNumber: @(total)]
                                           second: isnan(total2) ? nil : [infoTextFormatter stringFromNumber: @(total2)]];
    NSString *interestString = [self formatValuePair: isnan(interest) ? nil : [infoTextFormatter stringFromNumber: @(interest)]
                                              second: isnan(interest2) ? nil : [infoTextFormatter stringFromNumber: @(interest2)]];
    NSString *html = [NSString stringWithFormat: formatString,
                       NSLocalizedString(@"AP969", nil), amountString,
                       NSLocalizedString(@"AP970", nil), totalString,
                       NSLocalizedString(@"AP971", nil), interestString];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithHTML: [html dataUsingEncoding: NSUnicodeStringEncoding]
                                                                   documentAttributes: nil];
    detailsField.textStorage.attributedString = text;
}

#pragma mark - Bindings, KVO and KVC

- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    if (context == UserDefaultsBindingContext) {
        if ([keyPath isEqualToString: @"colors"]) {
            for (PrincipalBalanceGraph *child in self.subviews) {
                if ([child respondsToSelector: @selector(updateColors)]) {
                    [child updateColors];
                }
            }
        }

        if ([keyPath isEqualToString: @"loanValue"] || [keyPath isEqualToString: @"interestRate"]
            || [keyPath isEqualToString: @"redemptionRate"] || [keyPath isEqualToString: @"loanStartDate"]
            || [keyPath isEqualToString: @"specialRedemptions"]) {
            [self updateGraphs];
        }
        return;
    }
    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

@end
