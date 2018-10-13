/**
 * Copyright (c) 2013, 2015, Pecunia Project. All rights reserved.
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

#import "CategoryHeatMapController.h"
#import "ShortDate.h"
#import "BankingCategory.h"
#import "AnimationHelper.h"
#import "NSColor+PecuniaAdditions.h"

#import "StatCatAssignment.h"
#import "BankStatement.h"

#import "OnOffSwitchControl.h"
#import "OnOffSwitchControlCell.h"

@class HeatMapCalendar;

@interface CategoryHeatMapController (Private)

- (void)showValuePopupForDate: (ShortDate *)date relativeToRect: (NSRect)area forView: (NSView *)view;

@end

@implementation ValuePopupCell

- (void)awakeFromNib
{
    NSDictionary *positiveAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Positive Cash"]};
    NSDictionary *negativeAttributes = @{NSForegroundColorAttributeName: [NSColor applicationColorForKey: @"Negative Cash"]};
    [self.valueText.formatter setTextAttributesForPositiveValues: positiveAttributes];
    [self.valueText.formatter setTextAttributesForNegativeValues: negativeAttributes];
}

- (void)drawRect: (NSRect)dirtyRect
{
    if (self.categoryColor != nil) {
        NSColor    *startingColor  = self.categoryColor;
        NSColor    *endingColor = [startingColor colorWithAlphaComponent: 0.75];
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor: startingColor endingColor: endingColor];
        NSRect     colorMark = NSInsetRect(self.bounds, 3, 3);
        colorMark.size.width = 3;
        [gradient drawInRect: colorMark angle: 90];
    }
}

@end

@interface HeatMapView ()
- (void)resetSelectedDate: (HeatMapCalendar *)sender;
@end;

@interface HeatMapCalendar : NSView
{
@private
    NSUInteger  month;
    NSUInteger  year;
    HeatMapType currentType;

    HighLowValues limits; // Largest/smallest value found for the entire year (used for determining
                          // color scale factor.
    NSArray   *values;    // The actual values (for the entire year, use only the month that matters here)
    NSArray   *dates;     // Values and dates are shared between all calendar views.
    int       type;       // Type of the display: 0 - boxed months 1 - lined up months
    ShortDate *selectedDate;

    ShortDate       *date;
    NSString        *monthName;
    NSDateFormatter *dateFormatter;

    CGFloat contentAlpha;
    NSRect  valueArea;
}

@property (nonatomic, assign) CGFloat     contentAlpha;
@property (nonatomic, strong) ShortDate   *selectedDate; // nil if not selected.
@property (nonatomic, assign) HeatMapType type;

@end

@implementation HeatMapCalendar

@synthesize contentAlpha;
@synthesize selectedDate;
@synthesize type = currentType;

+ (id)defaultAnimationForKey: (NSString *)key
{
    if ([key isEqualToString: @"contentAlpha"]) {
        return [CABasicAnimation animation];
    } else {
        return [super defaultAnimationForKey: key];
    }
}

- (id)initWithFrame: (NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self != nil) {
        year = 0;
        month = 0;

        contentAlpha = 1;

        [self updateConstantValues];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setMonth: (NSUInteger)m
{
    month = m;
    [self updateConstantValues];
    [self setNeedsDisplay: YES];
}

- (void)setYear: (NSUInteger)y
{
    year = y;
    [self updateConstantValues];
    [self setNeedsDisplay: YES];
}

- (void)setValues: (NSArray *)theValues dates: (NSArray *)theDates limits: (HighLowValues)theLimits forType: (int)theType
{
    // Values and dates arrays must have the same number of entries.
    values = theValues;
    dates = theDates;
    limits = theLimits;
    type = theType;
    [self setNeedsDisplay: YES];
}

- (void)setContentAlpha: (CGFloat)value
{
    contentAlpha = value;
    [self setNeedsDisplay: YES];
}

- (void)setType: (HeatMapType)newType
{
    currentType = newType;
    [self updateConstantValues];
    [self setNeedsDisplay: YES];
}

- (void)setSelectedDate: (ShortDate *)value
{
    BOOL change = NO;
    if (selectedDate == nil) {
        if (value == nil) {
            return;
        } else {
            change = YES;
        }
    } else {
        change = ![selectedDate isEqual: value];
    }
    if (change) {
        selectedDate = value;
        [self display];
        [(HeatMapView *)self.superview resetSelectedDate : self];
    }
}

- (void)mouseDown: (NSEvent *)theEvent
{
    NSPoint windowLocation = theEvent.locationInWindow;
    NSPoint location = [self convertPoint: windowLocation fromView: nil];

    CategoryHeatMapController *controller = [(HeatMapView *)self.superview controller];

    if (NSPointInRect(location, valueArea)) {
        location.x -= valueArea.origin.x;
        location.y -= valueArea.origin.y;

        NSRect cellArea;
        if (currentType == HeatMapBlockType) {
            cellArea.size.width = valueArea.size.width / 7;
            cellArea.size.height = valueArea.size.height / 6;

            NSUInteger weekDay = (NSUInteger)location.x / cellArea.size.width;
            NSUInteger week = (NSUInteger)location.y / cellArea.size.height;
            self.selectedDate = [date dateByAddingUnits: (int)(week * 7 + weekDay) byUnit: NSCalendarUnitDay];

            cellArea.origin.x = valueArea.origin.x + weekDay * cellArea.size.width;
            cellArea.origin.y = valueArea.origin.y + week * cellArea.size.height;
        } else {
            location.y -= 5;
            cellArea.size.height = floor((valueArea.size.height - 10) / 37.0);
            cellArea.size.width = valueArea.size.width;
            NSUInteger day = location.y / cellArea.size.height;
            self.selectedDate = [date dateByAddingUnits: (int)day byUnit: NSCalendarUnitDay];
            cellArea.origin.x = valueArea.origin.x;
            cellArea.origin.y = valueArea.origin.y + day * cellArea.size.height + 5;
        }
        [controller showValuePopupForDate: selectedDate relativeToRect: cellArea forView: self];
    } else {
        self.selectedDate = nil;
    }
}

static NSColor *transparentTextColor;
static NSColor *darkTextColor;
static NSColor *gridColor;
static NSColor *frameColor;
static NSColor *monthNameColor;
static NSColor *grayColor;

static NSFont       *monthNameFont;
static NSDictionary *monthTextAttributes;

static NSFont       *smallFont;
static NSColor      *smallTextColor;
static NSDictionary *smallTextAttributes;

static NSFont *normalNumberFont;
static NSFont *smallNumberFont;

- (void)setupStaticValues
{
    dateFormatter = [[NSDateFormatter alloc] init];
    gridColor = [NSColor colorWithCalibratedWhite: 214 / 255.0 alpha: 1];
    frameColor = [NSColor colorWithCalibratedWhite: 193 / 255.0 alpha: 1];
    monthNameColor = [NSColor colorWithCalibratedRed: 226 green: 150 / 255.0 blue: 24 / 255.0 alpha: 1];

    monthNameFont = [NSFont fontWithName: @"HelveticaNeue" size: 14];
    monthTextAttributes = @{NSForegroundColorAttributeName: monthNameColor,
                            NSFontAttributeName: monthNameFont};

    smallTextColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.6];
    smallFont = [NSFont fontWithName: @"HelveticaNeue" size: 9];
    smallTextAttributes = @{NSForegroundColorAttributeName: smallTextColor,
                            NSFontAttributeName: smallFont};

    normalNumberFont = [NSFont fontWithName: @"HelveticaNeue" size: 11];
    smallNumberFont = [NSFont fontWithName: @"HelveticaNeue" size: 9];

    grayColor = [NSColor colorWithCalibratedWhite: 239 / 255.0 alpha: 1];
    darkTextColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.7];
}

- (void)updateConstantValues
{
    if (dateFormatter == nil) {
        [self setupStaticValues];
    }

   if (month == 0 || year == 0) {
        return;
    }

    ShortDate *firstDay = [ShortDate dateWithYear: (unsigned)year month: (unsigned)month day: 1];
    date = [firstDay firstDayInWeek];

    [dateFormatter setDateFormat: @"MMMM"];
    monthName = [dateFormatter stringFromDate: firstDay.lowDate];

    if (currentType == HeatMapBlockType) {
        transparentTextColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.3];
    } else {
        transparentTextColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.5];
    }
}

- (void)drawBlockMap
{
    // Start with the day grid.
    valueArea = self.bounds;
    valueArea.origin.x += 20;
    valueArea.origin.y += 35;

    NSUInteger cellWidth = (valueArea.size.width - 20) / 7.0;
    valueArea.size.width = cellWidth * 7;
    NSUInteger cellHeight = (valueArea.size.height - 35) / 6.0;
    valueArea.size.height = cellHeight * 6;

    NSFont *numberFont;
    if (cellWidth > 20 && cellHeight > 20) {
        numberFont = normalNumberFont;
    } else {
        numberFont = smallNumberFont;
    }
    smallTextAttributes = @{NSForegroundColorAttributeName: smallTextColor,
                            NSFontAttributeName: smallFont};

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth: 1];

    // A month can span at most 6 weeks.
    CGFloat offset = valueArea.origin.x + cellWidth;
    for (NSUInteger day = 0; day < 6; day++) {
        [path moveToPoint: NSMakePoint(round(offset) + 0.5, NSMinY(valueArea))];
        [path lineToPoint: NSMakePoint(round(offset) + 0.5, NSMaxY(valueArea))];
        offset += cellWidth;
    }
    offset = valueArea.origin.y + cellHeight;
    for (NSUInteger week = 0; week < 5; week++) {
        [path moveToPoint: NSMakePoint(NSMinX(valueArea), round(offset) + 0.5)];
        [path lineToPoint: NSMakePoint(NSMaxX(valueArea), round(offset) + 0.5)];
        offset += cellHeight;
    }
    [gridColor set];
    [path stroke];

    [frameColor set];
    NSFrameRect(valueArea);

    if (month == 0 || year == 0) {
        return;
    }

    ShortDate *today = [ShortDate currentDate];
    NSRect    dayRect = NSMakeRect(valueArea.origin.x - 1, valueArea.origin.y, cellWidth + 1, cellHeight + 1);

    // Next are month name, week numbers and day names.
    [monthName drawAtPoint: NSMakePoint(20, 0) withAttributes: monthTextAttributes];

    offset = valueArea.origin.y + (cellHeight - smallFont.pointSize) / 2 - 2;
    ShortDate *workDate = [date copy];
    for (unsigned week = 0; week < 6; week++) {
        NSString *weekString = [NSString stringWithFormat: @"%i", workDate.week];
        [weekString drawAtPoint: NSMakePoint(5,  offset) withAttributes: smallTextAttributes];
        offset += dayRect.size.height - 1;
        workDate = [workDate dateByAddingUnits: 1 byUnit: NSWeekCalendarUnit];
    }
    [dateFormatter setDateFormat: @"EEE"];
    NSDate *dayNameDate = date.lowDate;
    offset = valueArea.origin.x + 8;
    for (unsigned i = 0; i < 7; i++) {
        NSString *dayName = [dateFormatter stringFromDate: dayNameDate];
        [dayName drawAtPoint: NSMakePoint(offset, 21) withAttributes: smallTextAttributes];
        dayNameDate = [dayNameDate dateByAddingTimeInterval: 24 * 3600];
        offset += dayRect.size.width - 1;
    }
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect: NSInsetRect(valueArea, 1, 1)];
    [clipPath setClip];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment: NSCenterTextAlignment];

    NSColor *textColor;
    workDate = [date copy];
    NSUInteger index = 0;
    for (NSUInteger week = 0; week < 6; week++) {
        dayRect.origin.x = valueArea.origin.x;

        for (NSUInteger day = 0; day < 7; day++) {
            NSGradient *gradient;
            NSColor    *startingColor;
            NSColor    *endingColor;
            if (workDate.month == month) {
                // Find the next date in our data that is the same or larger than the work date.
                while (index < dates.count && [(ShortDate *)dates[index] compare : workDate] == NSOrderedAscending) {
                    index++;
                }

                if ([today isEqual: workDate]) {
                    startingColor = [NSColor applicationColorForKey: @"Selection Gradient (high)"];
                    endingColor = [NSColor applicationColorForKey: @"Selection Gradient (low)"];
                    textColor = [NSColor whiteColor];
                } else {
                    if (index < dates.count && [dates[index] isEqual: workDate]) {
                        textColor = transparentTextColor;

                        // Normalize the value so we can derive a color from it.
                        double value = [values[index] doubleValue];
                        if (limits.low < 0) {
                            // Two color mode. Negative values get red (with a purpur touch for the lowest 10%) and
                            // positive values get green
                            if (value < 0) {
                                double factor = value / (0.9 * limits.low);
                                if (factor <= 1) {
                                    factor = MIN(1 - factor, 0.9); // Limit variable part for prettier result.
                                    endingColor = [NSColor colorWithCalibratedRed: 1 green: factor blue: 0 alpha: 0.68 * contentAlpha];
                                } else {
                                    factor = 100 / 255.0 * value / limits.high;
                                    endingColor = [NSColor colorWithCalibratedRed: 1 green: 0 blue: factor alpha: 0.68 * contentAlpha];
                                }
                                startingColor = [endingColor colorWithAlphaComponent: 0.4 * contentAlpha];
                            } else {
                                double factor = value / (0.9 * limits.high);
                                if (factor <= 1) {
                                    factor = MIN(1 - factor, 0.9);
                                    endingColor = [NSColor colorWithCalibratedRed: factor green: 1 blue: factor alpha: 0.68 * contentAlpha];
                                } else {
                                    factor = 100 / 255.0 * value / limits.high;
                                    endingColor = [NSColor colorWithCalibratedRed: 0 green: 0.75 blue: factor alpha: 0.68 * contentAlpha];
                                }
                                startingColor = [endingColor colorWithAlphaComponent: 0.4 * contentAlpha];
                            }
                        } else {
                            // Single color mode. Only positive values, from yellow to red + purpur for the highest 10%.
                            double factor = value / (0.9 * limits.high);
                            if (factor <= 1) {
                                factor = MIN(1 - factor, 0.9);
                                endingColor = [NSColor colorWithCalibratedRed: 1 green: factor blue: 0 alpha: 0.68 * contentAlpha];
                            } else {
                                factor = 100 / 255.0 * value / limits.high;
                                endingColor = [NSColor colorWithCalibratedRed: 1 green: 0 blue: factor alpha: 0.68 * contentAlpha];
                            }
                            startingColor = [endingColor colorWithAlphaComponent: 0.4 * contentAlpha];
                        }
                    } else {
                        textColor = darkTextColor;
                        if ([workDate isEqual: selectedDate]) {
                            startingColor = [NSColor whiteColor];
                            endingColor = [NSColor whiteColor];
                        }
                    }
                }

                if (startingColor != nil) {
                    if ([workDate isEqual: selectedDate]) {
                        startingColor = [startingColor colorWithChangedBrightness: 0.8];
                        endingColor = [endingColor colorWithChangedBrightness: 0.8];
                    }
                    gradient = [[NSGradient alloc] initWithStartingColor: startingColor endingColor: endingColor];
                    [gradient drawInRect: dayRect angle: 90];
                }
            } else {
                NSColor *color = ([workDate isEqual: selectedDate]) ? [grayColor colorWithChangedBrightness: 0.8] : grayColor;
                [color set];
                NSRectFill(NSInsetRect(dayRect, 1, 1));
                textColor = transparentTextColor;
            }

            NSString     *text = [NSString stringWithFormat: @"%i", workDate.day];
            NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                         NSForegroundColorAttributeName: textColor,
                                         NSFontAttributeName: numberFont};

            workDate = [workDate dateByAddingUnits: 1 byUnit: NSCalendarUnitDay];

            NSRect drawRect = dayRect;
            CGSize size = [text sizeWithAttributes: attributes];
            drawRect.origin.y += (dayRect.size.height - size.height) / 2;

            [text drawInRect: drawRect withAttributes: attributes];
            dayRect.origin.x += cellWidth;
        }
        dayRect.origin.y += cellHeight;
    }
}

- (void)drawStripeMap
{
    valueArea = NSIntegralRect(self.bounds);
    valueArea.origin.y += 20;
    valueArea.size.height -= 40;
    valueArea.size.width = 20;
    valueArea.origin.x = floor((self.bounds.size.width - valueArea.size.width) / 2);

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: valueArea xRadius: 3 yRadius: 3];

    NSColor    *startColor = [NSColor colorWithCalibratedWhite: 0.9 alpha: 0.8];
    NSColor    *endColor = [NSColor colorWithCalibratedWhite: 1 alpha: 0.8];
    NSGradient *mainGradient = [[NSGradient alloc] initWithStartingColor: startColor endingColor: endColor];
    [mainGradient drawInBezierPath: path angle: 0];

    CGFloat cellHeight = floor((valueArea.size.height - 10) / 37.0); // 5 * 7 + 2 days (after the last weekend).
    NSRect  dayRect = NSMakeRect(valueArea.origin.x, valueArea.origin.y + 5, valueArea.size.width, cellHeight);

    smallTextAttributes = @{NSForegroundColorAttributeName: smallTextColor,
                            NSFontAttributeName: smallFont};

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment: NSCenterTextAlignment];

    NSColor *textColor;
    CGFloat gradientStartAlpha = 0.5;
    CGFloat gradientEndAlpha = 0.8;

    ShortDate  *today = [ShortDate currentDate];
    ShortDate  *workDate = [date copy];
    NSUInteger index = 0;
    for (NSUInteger day = 0; day < 37; day++) {
        NSGradient *gradient;
        NSColor    *startingColor;
        NSColor    *endingColor;

        if (workDate.month == month) {
            // Find the next date in our data that is the same or larger than the work date.
            while (index < dates.count && [(ShortDate *)dates[index] compare : workDate] == NSOrderedAscending) {
                index++;
            }

            if ([today isEqual: workDate]) {
                startingColor = [NSColor applicationColorForKey: @"Selection Gradient (high)"];
                endingColor = [NSColor applicationColorForKey: @"Selection Gradient (low)"];
                textColor = [NSColor whiteColor];
            } else {
                if (index < dates.count && [dates[index] isEqual: workDate]) {
                    textColor = transparentTextColor;

                    // Normalize the value so we can derive a color from it.
                    double value = [values[index] doubleValue];
                    if (limits.low < 0) {
                        // Two color mode. Negative values get red (with a purpur touch for the lowest 10%) and
                        // positive values get green
                        if (value < 0) {
                            double factor = value / (0.9 * limits.low);
                            if (factor <= 1) {
                                factor = MIN(1 - factor, 0.9); // Limit variable part for prettier result.
                                endingColor = [NSColor colorWithCalibratedRed: 1 green: factor blue: 0 alpha: gradientEndAlpha * contentAlpha];
                            } else {
                                factor = 100 / 255.0 * value / limits.high;
                                endingColor = [NSColor colorWithCalibratedRed: 1 green: 0 blue: factor alpha: gradientEndAlpha * contentAlpha];
                            }
                            startingColor = [endingColor colorWithAlphaComponent: gradientStartAlpha * contentAlpha];
                        } else {
                            double factor = value / (0.9 * limits.high);
                            if (factor <= 1) {
                                factor = MIN(1 - factor, 0.9);
                                endingColor = [NSColor colorWithCalibratedRed: factor green: 1 blue: factor alpha: gradientEndAlpha * contentAlpha];
                            } else {
                                factor = 100 / 255.0 * value / limits.high;
                                endingColor = [NSColor colorWithCalibratedRed: 0 green: 0.75 blue: factor alpha: gradientEndAlpha * contentAlpha];
                            }
                            startingColor = [endingColor colorWithAlphaComponent: gradientStartAlpha * contentAlpha];
                        }
                    } else {
                        // Single color mode. Only positive values, from yellow to red + purpur for the highest 10%.
                        double factor = value / (0.9 * limits.high);
                        if (factor <= 1) {
                            factor = MIN(1 - factor, 0.9);
                            endingColor = [NSColor colorWithCalibratedRed: 1 green: factor blue: 0 alpha: gradientEndAlpha * contentAlpha];
                        } else {
                            factor = 100 / 255.0 * value / limits.high;
                            endingColor = [NSColor colorWithCalibratedRed: 1 green: 0 blue: factor alpha: gradientEndAlpha * contentAlpha];
                        }
                        startingColor = [endingColor colorWithAlphaComponent: gradientStartAlpha * contentAlpha];
                    }
                } else {
                    textColor = transparentTextColor;
                    if ([workDate isEqual: selectedDate]) {
                        startingColor = [NSColor whiteColor];
                        endingColor = [NSColor whiteColor];
                    }
                }
            }

            if (startingColor != nil) {
                if ([workDate isEqual: selectedDate]) {
                    startingColor = [startingColor colorWithChangedBrightness: 0.8];
                    endingColor = [endingColor colorWithChangedBrightness: 0.8];
                }
                gradient = [[NSGradient alloc] initWithStartingColor: startingColor endingColor: endingColor];
                [gradient drawInRect: dayRect angle: 180];
            }

            NSString *text;
            NSFont   *numberFont = normalNumberFont;
            if (workDate.dayInWeek == 1 || workDate.dayInWeek == 7 || workDate.isFirstDayInMonth) {
                text = [NSString stringWithFormat: @"%i", workDate.day];
            } else {
                text = @"•";
            }

            NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                         NSForegroundColorAttributeName: textColor,
                                         NSFontAttributeName: numberFont};
            NSRect drawRect = dayRect;
            CGSize size = [text sizeWithAttributes: attributes];
            drawRect.origin.y += (dayRect.size.height - size.height) / 2 - 1;

            [text drawInRect: drawRect withAttributes: attributes];
        }

        workDate = [workDate dateByAddingUnits: 1 byUnit: NSCalendarUnitDay];
        dayRect.origin.y += cellHeight;
    }
    [[NSColor colorWithCalibratedWhite: 0.7 alpha: 1] setFill];
    NSFrameRect(valueArea);
}

- (void)drawRect: (NSRect)dirtyRect
{
    switch (currentType) {
        case HeatMapBlockType:
            [self drawBlockMap];
            break;

        case HeatMapStripeType:
            [self drawStripeMap];
            break;
    }
}

@end

//------------------------------------------------------------------------------------------------------------

#define HORIZONTAL_SPACING 20
#define VERTICAL_SPACING   20

@implementation HeatMapView

@synthesize controller;
@synthesize mapType;
@synthesize currentYear;

- (BOOL)isFlipped
{
    return YES;
}

- (void)awakeFromNib
{
    self.mapType = HeatMapBlockType;

    NSUInteger month = 1;
    for (NSView *view in self.subviews) {
        [(HeatMapCalendar *)view setMonth : month++];
    }
}

- (void)setMapType: (HeatMapType)value
{
    mapType = value;
    for (NSView *view in self.subviews) {
        [(HeatMapCalendar *)view setType : value];
    }
    [self resizeSubviewsWithOldSize: NSZeroSize];
    [self setNeedsDisplay: YES];
}

- (void)setCurrentYear: (NSUInteger)value
{
    currentYear = value;
    for (NSView *view in self.subviews) {
        HeatMapCalendar *calendar = (HeatMapCalendar *)view;
        calendar.year = value;
        calendar.contentAlpha = 0;
    }
    [self setNeedsDisplay: YES];
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldBoundsSize
{
    NSRect bounds = self.bounds;

    switch (mapType) {
        case HeatMapBlockType: {
            CGFloat calendarWidth = (bounds.size.width - 3 * HORIZONTAL_SPACING) / 4.0;
            CGFloat calendarHeight = (bounds.size.height - 2 * VERTICAL_SPACING) / 3.0;
            NSArray *subviews = self.subviews;
            for (NSUInteger row = 0; row < 3; row++) {
                for (NSUInteger column = 0; column < 4; column++) {
                    NSRect frame = NSMakeRect((int)(column * (HORIZONTAL_SPACING + calendarWidth)),
                                              (int)(row * (VERTICAL_SPACING + calendarHeight)),
                                              (int)calendarWidth, (int)calendarHeight);
                    [subviews[row * 4 + column] setFrame: frame];
                }
            }
            break;
        }

        case HeatMapStripeType: {
            CGFloat offset = 100;
            CGFloat calendarWidth = (bounds.size.width - 11 * HORIZONTAL_SPACING - offset) / 12.0;
            CGFloat calendarHeight = bounds.size.height;

            for (NSView *view in self.subviews) {
                NSRect frame = NSMakeRect(floor(offset), 0, (int)calendarWidth, (int)calendarHeight);
                offset += calendarWidth + HORIZONTAL_SPACING;
                [view setFrame: frame];
            }
            break;
        }
    }
}

- (void)resetSelectedDate: (HeatMapCalendar *)sender
{
    if (resettingDate) {
        return;
    }

    resettingDate = YES;
    for (NSView *view in self.subviews) {
        HeatMapCalendar *calendar = (HeatMapCalendar *)view;
        if (calendar != sender) {
            calendar.selectedDate = nil;
        }
    }
    resettingDate = NO;
}

- (void)mouseDown: (NSEvent *)theEvent
{
    [self resetSelectedDate: nil];
}

- (void)drawRect: (NSRect)dirtyRect
{
    if (mapType != HeatMapStripeType) {
        return;
    }

    NSImage *hatch = [NSImage imageNamed: @"gray-hatch"];
    NSColor *pattern = [NSColor colorWithPatternImage: hatch];
    NSColor *borderColor = [NSColor colorWithCalibratedRed: 88 / 255.0 green: 86 / 255.0 blue: 77 / 255.0 alpha: 0.1];

    NSRect bounds = self.bounds;
    bounds.origin.y += 25;
    bounds.size.height -= 50;

    CGFloat cellHeight = floor(bounds.size.height / 37.0); // 5 * 7 + 2 days (after the last weekend).
    CGFloat offset = floor(bounds.origin.y) + 0.5;
    for (NSUInteger week = 0; week < 5; week++) {
        NSRect weekendFrame = NSMakeRect(bounds.origin.x + 50, offset + 5 * cellHeight,
                                         bounds.size.width - 50, 2 * cellHeight);
        [pattern set];
        NSRectFill(weekendFrame);

        NSBezierPath *border = [NSBezierPath bezierPath];
        [border moveToPoint: NSMakePoint(weekendFrame.origin.x, weekendFrame.origin.y)];
        [border lineToPoint: NSMakePoint(weekendFrame.origin.x + weekendFrame.size.width, weekendFrame.origin.y)];
        [border lineToPoint: NSMakePoint(weekendFrame.origin.x + weekendFrame.size.width, weekendFrame.origin.y + weekendFrame.size.height)];
        [border lineToPoint: NSMakePoint(weekendFrame.origin.x, weekendFrame.origin.y + weekendFrame.size.height)];
        [borderColor set];
        [border stroke];

        offset += 7 * cellHeight;
    }
    // Print week numbers.
    bounds.origin.x += 100;
    bounds.size.width -= 100;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment: NSRightTextAlignment];
    NSFont       *font = [NSFont fontWithName: @"HelveticaNeue-Italic" size: 20];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                 NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite: 0 alpha: 0.15],
                                 NSFontAttributeName: font};

    CGFloat calendarWidth = (bounds.size.width - 11 * HORIZONTAL_SPACING) / 12.0;
    CGFloat offsetX = bounds.origin.x + 6;
    for (unsigned month = 1; month <= 12; month++) {
        CGFloat   offsetY = floor(bounds.origin.y) + 3 * cellHeight + 6;
        ShortDate *workDate = [ShortDate dateWithYear: (unsigned)currentYear month: month day: 1];
        for (NSUInteger week = 0; week < 5; week++) {
            NSString *weekString = [NSString stringWithFormat: @"%i", workDate.week];

            NSRect weekRect = NSMakeRect(offsetX - 40, offsetY, 40, 40);
            [weekString drawInRect: weekRect withAttributes: attributes];
            offsetY += 7 * cellHeight;
            workDate = [workDate dateByAddingUnits: 1 byUnit: NSCalendarUnitWeekOfYear];
        }
        offsetX += calendarWidth + HORIZONTAL_SPACING;
    }
}

@end

//------------------------------------------------------------------------------------------------------------

@implementation CategoryHeatMapController

@synthesize mainView;
@synthesize selectedCategory;

- (void)awakeFromNib
{
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.minorVersion >= 10) {
        helpPopover.appearance = [NSAppearance appearanceNamed: NSAppearanceNameVibrantDark];
    }

    formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale: NSLocale.currentLocale];

    // Help text.
    NSBundle           *mainBundle = [NSBundle mainBundle];
    NSString           *path = [mainBundle pathForResource: @"category-heatmap-help" ofType: @"rtf"];
    NSAttributedString *text = [[NSAttributedString alloc] initWithPath: path documentAttributes: NULL];
    [helpText setAttributedStringValue: text];
    NSRect bounds = [text boundingRectWithSize: NSMakeSize(helpText.bounds.size.width, 0) options: NSStringDrawingUsesLineFragmentOrigin];
    helpContentView.frame = NSMakeRect(0, 0, helpText.bounds.size.width + 20, bounds.size.height + 20);

    heatMapView.controller = self;
    [valuePopupList reloadData];

    switchTypeButtonCell.useiOSStyle = YES;
    switchTypeButtonCell.offSwitchLabel = @"";
    switchTypeButtonCell.onSwitchLabel = @"";
}

- (void)updateValues
{
    NSArray        *values;
    NSArray        *dates;
    HighLowValues  limits = {0, 0};
    switch (dataSourceSwitch.selectedSegment) {
        case 0: {
            [formatter setFormat: @"#,##0.##"];

            limits.high = [selectedCategory turnoversForYear: currentYear toDates: &dates turnovers: &values recursive: YES];

            // Make sure we have a minimal max value so that we don't show a low number of statements as hot.
            if (limits.high < 10) {
                limits.high = 10;
            }
            break;
        }

        case 1: {
            [formatter setFormat: @"#,##0.## ¤"];

            limits.high = [selectedCategory absoluteValuesForYear: currentYear toDates: &dates values: &values recursive: YES];

            if (limits.high < 1000) {
                limits.high = 1000;
            }
            break;
        }

        case 2: {
            [formatter setFormat: @"#,##0.## ¤"];

            limits = [selectedCategory valuesForYear: currentYear toDates: &dates values: &values recursive: YES];

            if (limits.high < 1000) {
                limits.high = 1000;
            }
            if (limits.low > -1000) {
                limits.low = -1000;
            }
            break;
        }
    }

    for (NSView *view in heatMapView.subviews) {
        HeatMapCalendar *calendar = (HeatMapCalendar *)view;
        [calendar setValues: values dates: dates limits: limits forType: 0];
    }
    NSNumber   *sum = [values valueForKeyPath: @"@sum.self"];
    ShortDate  *date = [ShortDate dateWithYear: currentYear month: 1 day: 1];
    NSUInteger dayCount = [date daysToDate: [ShortDate dateWithYear: currentYear + 1 month: 1 day: 1]];
    perDayText.stringValue = [formatter stringFromNumber: @(sum.doubleValue / dayCount)];
    perMonthText.stringValue = [formatter stringFromNumber: @(sum.doubleValue / 12.0)];
}

- (void)showValuePopupForDate: (ShortDate *)date relativeToRect: (NSRect)area forView: (NSView *)view
{
    currentAssignments = [selectedCategory assignmentsFrom: date to: date withChildren: YES];
    [valuePopupList reloadData];

    NSRect frame = valuePopupList.frame;
    frame.origin = NSMakePoint(2, 2);
    if (currentAssignments.count < 6) {
        frame.size.height = MAX(currentAssignments.count, 1U) * 21;
    } else {
        frame.size.height = 5 * 21;
    }

    NSSize contentSize = frame.size;
    contentSize.width += 4; // Border left/right.
    contentSize.height += 4; // Ditto for top/bottom.
    if (contentSize.height < 26) {
        contentSize.height = 26;
    }
    valuePopupList.frame = frame;
    statementsPopover.contentSize = contentSize;

    [statementsPopover showRelativeToRect: area ofView: view preferredEdge: NSMaxXEdge];
    valuePopupList.frameOrigin = frame.origin; // Set the origin again, as NSPopover messes this up.
}

#pragma mark -
#pragma mark IB Actions

- (IBAction)changeDatasource: (id)sender
{
    [self updateValues];
}

- (IBAction)showHelp: (id)sender
{
    if (!helpPopover.shown) {
        [helpPopover showRelativeToRect: helpButton.bounds ofView: helpButton preferredEdge: NSMinYEdge];
    }
}

- (IBAction)switchType: (id)sender
{
    [[heatMapView animator] setAlphaValue: 0];
    [self performSelector: @selector(doSwitchType:) withObject: sender afterDelay: 0.3];
}

- (void)doSwitchType: (id)sender
{
    OnOffSwitchControl *button = sender;

    switch ([button state]) {
        case NSOffState:
            heatMapView.mapType = HeatMapBlockType;
            break;

        case NSOnState:
            heatMapView.mapType = HeatMapStripeType;
            break;
    }
    [[heatMapView animator] setAlphaValue: 1];
}

#pragma mark -
#pragma mark PXListViewDelegate protocol

- (NSUInteger)numberOfRowsInListView: (PXListView *)aListView
{
    if (currentAssignments.count == 0) {
        return 1; // A single entry saying there's nothing to show.
    }
    return currentAssignments.count;
}

- (CGFloat)listView: (PXListView *)aListView heightOfRow: (NSUInteger)row forDragging: (BOOL)forDragging
{
    return 21;
}

- (NSRange)listView: (PXListView *)aListView rangeOfDraggedRow: (NSUInteger)row
{
    return NSMakeRange(0, 0);
}

- (id)formatValue: (id)value
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL           autoCasing = [userDefaults boolForKey: @"autoCasing"];

    if (autoCasing) {
        NSMutableArray *words = [[value componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] mutableCopy];
        for (NSUInteger i = 0; i < [words count]; i++) {
            NSString *word = words[i];
            if (i == 0 || [word length] > 3) {
                words[i] = [word capitalizedString];
            }
        }
        value = [words componentsJoinedByString: @" "];
    }
    return (value == nil) ? @"" : value;
}

- (PXListViewCell *)listView: (PXListView *)aListView cellForRow: (NSUInteger)row
{
    ValuePopupCell *cell = (ValuePopupCell *)[aListView dequeueCellWithReusableIdentifier: @"valueCell"];

    if (!cell) {
        cell = [ValuePopupCell cellLoadedFromNibNamed: @"CategoryHeatMap"
                                                owner: cell
                                   reusableIdentifier: @"valueCell"];
    }

    if (currentAssignments.count == 0) {
        cell.remoteNameText.stringValue = NSLocalizedString(@"AP750", nil);
        cell.valueText.hidden = YES;
        cell.currencyText.hidden = YES;
        cell.categoryColor = nil;
    } else {
        StatCatAssignment *assignment = currentAssignments[row];
        if (assignment.statement.remoteName.length == 0) {
            cell.remoteNameText.stringValue = [self formatValue: assignment.statement.transactionText];
        } else {
            cell.remoteNameText.stringValue = [self formatValue: assignment.statement.remoteName];
        }
        cell.valueText.hidden = NO;
        cell.valueText.objectValue = assignment.value;
        cell.currencyText.hidden = NO;
        cell.categoryColor = assignment.category.categoryColor;
    }
    return cell;
}

- (bool)listView: (PXListView *)aListView shouldSelectRows: (NSIndexSet *)rows byExtendingSelection: (BOOL)shouldExtend
{
    return NO;
}

#pragma mark -
#pragma mark PecuniaSectionItem protocol

- (void)activate
{
}

- (void)deactivate
{
}

- (void)setTimeRangeFrom: (ShortDate *)from to: (ShortDate *)to
{
    currentYear = from.year;
    yearLabel.objectValue = [NSString stringWithFormat: @"%i", currentYear];

    heatMapView.currentYear = currentYear;
    [self updateValues];
    for (NSView *view in heatMapView.subviews) {
        [(id)view.animator setContentAlpha: 1];
    }
}

- (void)print
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    [printInfo setHorizontalPagination: NSFitPagination];
    [printInfo setVerticalPagination: NSAutoPagination];

    NSPrintOperation *printOp;
    printOp = [NSPrintOperation printOperationWithView: mainView printInfo: printInfo];
    [printOp setShowsPrintPanel: YES];
    [printOp runOperation];
}

- (void)setSelectedCategory: (BankingCategory *)theCategory
{
    if (selectedCategory != theCategory) {
        for (NSView *view in heatMapView.subviews) {
            [(HeatMapCalendar *)view setContentAlpha : 0];
        }
        selectedCategory = theCategory;
        [self updateValues];
        for (NSView *view in heatMapView.subviews) {
            [(id)view.animator setContentAlpha: 1];
        }
    }
}

@end
