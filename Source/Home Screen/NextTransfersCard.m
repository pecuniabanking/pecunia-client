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

#import "MessageLog.h"

#import "NextTransfersCard.h"
#import "NSColor+PecuniaAdditions.h"
#import "GraphicsAdditions.h"
#import "ShortDate.h"

#import "StandingOrder.h"
#import "MOAssistant.h"
#import "BankingController.h"

@interface NextTransfersCalendar : NSView
{
@private
    NextTransfersCard *card;

    NSMutableDictionary *values;
    ShortDate *selectedDate;
    ShortDate       *startDate;
    NSDateFormatter *dateFormatter;

    CGFloat contentAlpha;
    NSRect  valueArea;
}

@property (nonatomic, assign) CGFloat     contentAlpha;
@property (nonatomic, strong) ShortDate   *selectedDate; // nil if not selected.

@property (nonatomic, assign) NSUInteger month;
@property (nonatomic, assign) NSUInteger year;

@end

@implementation NextTransfersCalendar

@synthesize contentAlpha;
@synthesize selectedDate;
@synthesize month;
@synthesize year;

+ (id)defaultAnimationForKey: (NSString *)key
{
    LogEnter;

    if ([key isEqualToString: @"contentAlpha"]) {
        return [CABasicAnimation animation];
    } else {
        return [super defaultAnimationForKey: key];
    }

    LogLeave;
}

- (id)initWithFrame: (NSRect)frameRect owner: (NextTransfersCard *)owner
{
    LogEnter;

    self = [super initWithFrame: frameRect];
    if (self != nil) {
        card = owner;
        year = 0;
        month = 0;

        contentAlpha = 1;

        [self updateConstantValues];
    }

    LogLeave;

    return self;
}

- (void)setMonth: (NSUInteger)m
{
    LogEnter;

    month = m;
    [self updateConstantValues];
    [self setNeedsDisplay: YES];

    LogLeave;
}

- (void)setYear: (NSUInteger)y
{
    LogEnter;

    year = y;
    [self updateConstantValues];
    [self setNeedsDisplay: YES];

    LogLeave;
}

- (void)setValues: (NSMutableDictionary *)theValues
{
    LogEnter;

    values = theValues;
    [self setNeedsDisplay: YES];

    LogLeave;
}

- (void)setContentAlpha: (CGFloat)value
{
    LogEnter;

    contentAlpha = value;
    [self setNeedsDisplay: YES];

    LogLeave;
}

- (void)setSelectedDate: (ShortDate *)value
{
    LogEnter;

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
        [self setNeedsDisplay: YES];
    }

    LogLeave;
}

- (void)mouseDown: (NSEvent *)theEvent
{
    LogEnter;

    NSPoint windowLocation = theEvent.locationInWindow;
    NSPoint location = [self convertPoint: windowLocation fromView: nil];

    if (NSPointInRect(location, valueArea)) {
        location.x -= valueArea.origin.x;
        location.y -= valueArea.origin.y;

        NSRect cellArea;
        cellArea.size.width = valueArea.size.width / 7;
        cellArea.size.height = valueArea.size.height / 6;

        NSUInteger weekDay = (NSUInteger)location.x / cellArea.size.width;
        NSUInteger week = (NSUInteger)location.y / cellArea.size.height;
        ShortDate *date = [startDate dateByAddingUnits: week * 7 + weekDay byUnit: NSCalendarUnitDay];
        if (date.month == month) {
            if (values[date] != nil) {
                self.selectedDate = date;
            } else {
                self.selectedDate = nil;
            }

            if (self.selectedDate != nil) {
                cellArea.origin.x = valueArea.origin.x + weekDay * cellArea.size.width;
                cellArea.origin.y = valueArea.origin.y + week * cellArea.size.height;
                [card showValuePopupForDate: selectedDate
                                     values: values[selectedDate]
                             relativeToRect: cellArea
                                    forView: self];
            }
        }
    } else {
        self.selectedDate = nil;
    }

    LogLeave;
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
    LogEnter;

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

    LogLeave;
}

- (void)updateConstantValues
{
    LogEnter;

    if (dateFormatter == nil) {
        [self setupStaticValues];
    }

    if (month == 0 || year == 0) {
        return;
    }

    ShortDate *firstDay = [ShortDate dateWithYear: year month: month day: 1];
    startDate = [firstDay firstDayInWeek];

    transparentTextColor = [NSColor colorWithCalibratedWhite: 0 alpha: 0.3];

    LogLeave;
}

- (void)drawRect: (NSRect)dirtyRect
{
    // Start with the day grid.
    valueArea = NSIntegralRect(self.bounds);
    valueArea.origin.x += 20;
    valueArea.size.height -= 15;

    NSUInteger cellWidth = (valueArea.size.width - 20) / 7;
    valueArea.size.width = cellWidth * 7;
    NSUInteger cellHeight = valueArea.size.height / 6;
    valueArea.size.height = cellHeight * 6;

    NSFont *numberFont;
    if (cellWidth > 20 && cellHeight > 20) {
        numberFont = normalNumberFont;
    } else {
        numberFont = smallNumberFont;
    }

    if (month == 0 || year == 0) {
        return;
    }

    ShortDate *today = [ShortDate currentDate];
    NSRect    dayRect = NSMakeRect(valueArea.origin.x - 1, valueArea.origin.y, cellWidth + 1, cellHeight + 1);

    // Wweek numbers and day names.
    CGFloat offset = valueArea.origin.y + (cellHeight - smallFont.pointSize) / 2 - 1;
    ShortDate *workDate = [startDate copy];
    for (unsigned week = 0; week < 6; week++) {
        NSString *weekString = [NSString stringWithFormat: @"%i", workDate.week];
        [weekString drawAtPoint: NSMakePoint(5,  offset) withAttributes: smallTextAttributes];
        offset += dayRect.size.height - 1;
        workDate = [workDate dateByAddingUnits: 1 byUnit: NSWeekCalendarUnit];
    }
    [dateFormatter setDateFormat: @"EEE"];
    NSDate *dayNameDate = startDate.lowDate;
    offset = valueArea.origin.x + 6;
    for (unsigned i = 0; i < 7; i++) {
        NSString *dayName = [dateFormatter stringFromDate: dayNameDate];
        [dayName drawAtPoint: NSMakePoint(offset, NSMaxY(valueArea) + 1) withAttributes: smallTextAttributes];
        dayNameDate = [dayNameDate dateByAddingTimeInterval: 24 * 3600];
        offset += dayRect.size.width - 1;
    }
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRect: NSInsetRect(valueArea, 1, 1)];
    [clipPath setClip];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment: NSCenterTextAlignment];

    NSColor *textColor;
    workDate = [startDate copy];
    for (NSUInteger week = 0; week < 6; week++) {
        dayRect.origin.x = valueArea.origin.x;

        for (NSUInteger day = 0; day < 7; day++) {
            NSGradient *gradient;
            NSColor    *startingColor;
            NSColor    *endingColor;
            if (workDate.month == month) {
                NSArray *orders = values[workDate];

                if ([today isEqual: workDate]) {
                    startingColor = [NSColor applicationColorForKey: @"Selection Gradient (low)"];
                    endingColor = [NSColor applicationColorForKey: @"Selection Gradient (high)"];
                    textColor = [NSColor whiteColor];
                } else {
                    if ([today isGreaterThan: workDate]) {
                        // Already passed days in this month.
                        textColor = transparentTextColor;
                        startingColor = [NSColor colorWithCalibratedRed: 0.825 green: 0.808 blue: 0.760 alpha: 1.000];
                        endingColor = [NSColor colorWithCalibratedRed: 0.825 green: 0.808 blue: 0.760 alpha: 1.000];
                    } else {
                        if (orders != nil) {
                            textColor = [NSColor whiteColor];
                            startingColor = [NSColor colorWithCalibratedRed: 0.693 green: 0.271 blue: 0.204 alpha: 1.000];
                            endingColor = [NSColor colorWithCalibratedRed: 0.693 green: 0.271 blue: 0.204 alpha: 1.000];
                        } else {
                            textColor = darkTextColor;
                            if ([workDate isEqual: selectedDate]) {
                                startingColor = [NSColor whiteColor];
                                endingColor = [NSColor whiteColor];
                            } else {
                                textColor = [NSColor whiteColor];
                                startingColor = [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000];
                                endingColor = [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: 1.000];
                            }
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
                textColor = nil;
            }

            if (textColor != nil) {
                NSString     *text = [NSString stringWithFormat: @"%i", workDate.day];
                NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                             NSForegroundColorAttributeName: textColor,
                                             NSFontAttributeName: numberFont};

                NSRect drawRect = dayRect;
                CGSize size = [text sizeWithAttributes: attributes];
                drawRect.origin.y -= (dayRect.size.height - size.height) / 2;

                [text drawInRect: drawRect withAttributes: attributes];
            }
            dayRect.origin.x += cellWidth;
            workDate = [workDate dateByAddingUnits: 1 byUnit: NSCalendarUnitDay];
        }

        dayRect.origin.y += cellHeight;
    }
}

@end

//--------------------------------------------------------------------------------------------------

@interface BandEndView : NSView

@property (nonatomic, assign) BOOL isTop;

@end

@implementation BandEndView

@synthesize isTop;

- (id)initWithFrame: (NSRect)frameRect isTop: (BOOL)top
{
    LogEnter;

    self = [super initWithFrame: frameRect];
    if (self != nil) {
        isTop = top;

        self.wantsLayer = YES;
        CGColorRef color = CGColorCreateFromNSColor([NSColor blackColor]);
        self.layer.shadowColor = color;
        CGColorRelease(color);

        self.layer.shadowRadius = 2;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowOpacity = 0.5;
    }

    LogLeave;

    return self;
}

- (void)drawRect: (NSRect)dirtyRect
{
    NSRect frame = self.bounds;
    frame.size.height -= 8;
    
    [[NSColor colorWithCalibratedRed: 0.945 green: 0.927 blue: 0.883 alpha: 1.000] setFill];

    if (!isTop) {
        frame.origin.y += 4;
    } else {
        frame.origin.y += 5;
    }
    NSRectFill(frame);
}

- (void)resizeWithOldSuperviewSize: (NSSize)oldSize
{
    LogEnter;

    [super resizeWithOldSuperviewSize: oldSize];

    NSRect bounds = NSInsetRect(self.bounds, 2, 0);
    if (isTop) {
        bounds.origin.y = 3;
    } else {
        bounds.origin.y = NSHeight(self.bounds) - 8;
    }
    bounds.size.height = 5;

    NSBezierPath *shadowPath = [NSBezierPath bezierPathWithOvalInRect: bounds];
    self.layer.shadowPath = shadowPath.cgPath;

    LogLeave;
}

@end

//--------------------------------------------------------------------------------------------------

#define CALENDAR_HEIGHT 160

@interface BandView : NSView <NSAnimationDelegate>
{
    NextTransfersCard *owner;

    NSDateFormatter *dateFormatter;
    NSMutableDictionary *monthAttributes;
    NSDictionary *yearAttributes;
    CGFloat yearLabelOffset;

    NSInteger offsetAccumulator;
    BOOL ignoreMomentumChange;

    BandEndView *startEnd;
    NSArrayController *standingOrders;
}

@property BOOL listMode; // If YES use a list otherwise calendar view.
@property NSUInteger contentWidth; // The usable width for content (right aligned).
@property (nonatomic) NSInteger scrollOffset; // Vertical scroll position (scrolling goes endless).

@end

@implementation BandView

@synthesize contentWidth;
@synthesize scrollOffset;

- (id)animationForKey: (NSString *)key
{
    LogEnter;

    if ([key isEqualToString: @"scrollOffset"]) {
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
        animation.speed = 1;
        return animation;
    } else {
        return [super animationForKey:key];
    }

    LogLeave;
}

- (id)initWithFrame: (NSRect)frameRect startingEnd: (BandEndView *)view card: (NextTransfersCard *)card
{
    LogEnter;

    self = [super initWithFrame: frameRect];
    if (self != nil) {
        [self setWantsLayer: YES];

        owner = card;
        startEnd = view;
        startEnd.layer.shadowOpacity = 0;
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;
        dateFormatter.dateFormat = @"MMMM";

        monthAttributes = [NSMutableDictionary dictionaryWithCapacity: 2];
        monthAttributes[NSFontAttributeName] = [NSFont fontWithName: @"HelveticaNeue-Bold" size: 13];

        yearLabelOffset = 20;
        NSFont *font = [NSFont fontWithName: @"Haettenschweiler" size: 130];
        if (font == nil) {
            yearLabelOffset = 40;
            font = [NSFont fontWithName: @"Impact" size: 100]; // Fallback.
        }
        yearAttributes = @{NSFontAttributeName: font,
                           NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite: 0 alpha: 0.05]};

        standingOrders = [[NSArrayController alloc] init];
        standingOrders.managedObjectContext = MOAssistant.assistant.context;
        standingOrders.entityName = @"StandingOrder";
        standingOrders.automaticallyRearrangesObjects = YES;

        // At most 3 calendars can be visible.
        NextTransfersCalendar *calendar = [[NextTransfersCalendar alloc] initWithFrame: NSMakeRect(0, 0, 100, 100) owner: card];
        [self addSubview: calendar];
        calendar = [[NextTransfersCalendar alloc] initWithFrame: NSMakeRect(0, 0, 100, 100) owner: card];
        [self addSubview: calendar];
        calendar = [[NextTransfersCalendar alloc] initWithFrame: NSMakeRect(0, 0, 100, 100) owner: card];
        [self addSubview: calendar];
        [self updateCalendarsWithFetch: YES];
    }

    LogLeave;

    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect: (NSRect)dirtyRect
{
    if (self.listMode) {

    } else {
        NSInteger height = NSHeight(self.bounds);
        NSUInteger monthDistance = self.scrollOffset / CALENDAR_HEIGHT;
        CGFloat currentOffset = height - 30.5 + self.scrollOffset % CALENDAR_HEIGHT;
        if (currentOffset > height) {
            currentOffset -= CALENDAR_HEIGHT;
            monthDistance++;
        }
        ShortDate *date = [[ShortDate currentDate] dateByAddingUnits: monthDistance
                                                              byUnit: NSCalendarUnitMonth];

        NSString *year = [NSString stringWithFormat: @"%i", date.year];
        NSAffineTransform *transform = [[NSAffineTransform alloc] init];

        [transform translateXBy: -yearLabelOffset yBy: height - 80];
        [transform rotateByDegrees: -90];
        [transform concat];
        [year drawAtPoint: NSMakePoint(0, 0) withAttributes: yearAttributes];
        transform = [[NSAffineTransform alloc] init];
        [transform rotateByDegrees: 90]; // Revert context transformations.
        [transform translateXBy: yearLabelOffset yBy: - (height - 80)];
        [transform concat];

        NSUInteger lineLength = NSWidth(self.bounds) - self.contentWidth - 10;
        while (currentOffset > 0) {
            NSInteger delta = height / 2;
            if (height - currentOffset < 30)
                delta = height - currentOffset;
            if (currentOffset < 41) // 30px + text height
                delta = currentOffset - 10;
            if (delta < 0)
                delta = 0;
            if (delta > 30)
                delta = 30;
            NSColor *color = [NSColor colorWithCalibratedRed: 0.497 green: 0.488 blue: 0.461 alpha: delta / 30.0];
            monthAttributes[NSForegroundColorAttributeName] = color;
            [color set];

            NSBezierPath *line = [NSBezierPath bezierPath];
            line.lineWidth = 1;
            [line moveToPoint: NSMakePoint(10, currentOffset)];
            [line lineToPoint: NSMakePoint(lineLength, currentOffset)];
            [line stroke];

            NSString *month = [dateFormatter stringFromDate: date.lowDate];
            [month drawAtPoint: NSMakePoint(10, currentOffset - 19) withAttributes: monthAttributes];
            date = [date dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth];
            currentOffset -= CALENDAR_HEIGHT;
        }
    }
}

- (void)scrollWheel: (NSEvent *)event
{
    switch (event.phase) {
        case NSEventPhaseBegan: // Trackpad with no momentum scrolling. Fingers moved on trackpad.
            offsetAccumulator = scrollOffset;
            // Fall through.
        case NSEventPhaseChanged:
            if (offsetAccumulator >= 0) {
                offsetAccumulator += event.scrollingDeltaY / 5;
            } else {
                offsetAccumulator += event.scrollingDeltaY / 2.0 * exp(offsetAccumulator / 75.0);
            }
            [self setScrollOffset: offsetAccumulator];
            break;

        case NSEventPhaseEnded:
            if (scrollOffset < 0) {
                [self.animator setScrollOffset: 0];
            }
            offsetAccumulator = scrollOffset;
            break;

        case NSEventPhaseNone:
            if (event.momentumPhase == NSEventPhaseNone)
            {
                // Mouse wheel.
                if ([event hasPreciseScrollingDeltas]) {
                    offsetAccumulator += event.scrollingDeltaY;
                    if (offsetAccumulator < 0) {
                        offsetAccumulator = 0;
                    }
                    [self setScrollOffset: offsetAccumulator];

                } else {
                    offsetAccumulator += 10 * event.scrollingDeltaY;
                    if (offsetAccumulator < 0) {
                        offsetAccumulator = 0;
                    }
                    [self.animator setScrollOffset: offsetAccumulator];
                }
            }

            break;
    }

    switch (event.momentumPhase) {
        case NSEventPhaseBegan: // Trackpad with momentum scrolling. User just lifted fingers.
            ignoreMomentumChange = NO;
            offsetAccumulator = scrollOffset;
            break;

        case NSEventPhaseChanged:
            if (!ignoreMomentumChange) {
                if (offsetAccumulator >= -50) {
                    offsetAccumulator += event.scrollingDeltaY / 5;
                    [self setScrollOffset: offsetAccumulator];
                } else {
                    // If we scrolled beyond the acceptable bound ignore any further
                    // (automatically generated) change events and animate back to 0 position.
                    ignoreMomentumChange = YES;
                    offsetAccumulator = 0;
                    [self.animator setScrollOffset: offsetAccumulator];
                }
            }
            break;

        case NSEventPhaseEnded:
            break;
    }
}

- (void)setScrollOffset: (NSInteger)value
{
    if (scrollOffset != value) {
        scrollOffset = value;
        [self updateCalendarsWithFetch: NO];
        [self resizeWithOldSuperviewSize: self.bounds.size];

        if (scrollOffset >= 10) {
            if (scrollOffset > 20) {
                startEnd.layer.shadowOpacity = 0.5;
            } else {
                startEnd.layer.shadowOpacity = 0.5 * (scrollOffset - 10) / 10.0;
            }
        } else {
            startEnd.layer.shadowOpacity = 0;
        }

        [self setNeedsDisplay: YES];
    }
}

- (void)updateCalendarsWithFetch: (BOOL)fetch
{
    LogEnter;

    NSUInteger monthDistance = self.scrollOffset / CALENDAR_HEIGHT;
    ShortDate *date = [[ShortDate currentDate] dateByAddingUnits: monthDistance
                                                          byUnit: NSCalendarUnitMonth];

    if (fetch) {
        NSError *error = nil;
        if (![standingOrders fetchWithRequest: nil merge: NO error: &error]) {
            // It's not a critical error if fetching the standing orders failed.
            // We just show empty calendars then.
            [NSAlert alertWithError: error];
        }
    }

    // We have added 3 calendars, so we just update their values here.
    for (NSUInteger i = 0; i < 3; ++i) {
        NextTransfersCalendar *calendar = self.subviews[i];
        if (fetch || calendar.month != date.month || calendar.year != date.year) {
            [owner cancelPopover];

            calendar.month = date.month;
            calendar.year = date.year;

            // We need 2 separate loops, one for weeks and one for months.
            NSMutableDictionary *values = [NSMutableDictionary dictionary];
            ShortDate *firstDay = [ShortDate dateWithYear: date.year month: date.month day: 1];
            ShortDate *lastDay = [ShortDate dateWithYear: date.year month: date.month + 1 day: 0];

            // Month loop.
            for (StandingOrder *order in standingOrders.arrangedObjects) {
                ShortDate *firstExecution = [ShortDate dateWithDate: order.firstExecDate];
                ShortDate *lastExecution = order.lastExecDate == nil ? lastDay : [ShortDate dateWithDate: order.lastExecDate];
                if ([firstExecution compare: lastDay] != NSOrderedDescending &&
                    [lastExecution compare: firstDay] != NSOrderedAscending) {

                    if (order.period.intValue== stord_monthly)
                    {
                        int delta = (int)date.month - (int)firstExecution.month;
                        if (delta < 0) {
                            delta += 12;
                        }
                        if (delta % order.cycle.intValue == 0) {
                            ShortDate *executionDay;
                            int day = order.executionDay.intValue;
                            switch (day) {
                                case 99: // Ultimo
                                    executionDay = [ShortDate dateWithYear: date.year month: date.month + 1 day: 0];
                                    break;
                                case 98: // Ultimo - 1
                                    executionDay = [ShortDate dateWithYear: date.year month: date.month + 1 day: -1];
                                    break;
                                case 97:  // Ultimo - 2
                                    executionDay = [ShortDate dateWithYear: date.year month: date.month + 1 day: -2];
                                    break;
                                default:
                                    executionDay = [ShortDate dateWithYear: date.year month: date.month day: day];
                                    break;
                            }
                            NSMutableArray *entries = values[executionDay];
                            if (entries == nil) {
                                entries = [NSMutableArray array];
                            }
                            [entries addObject: order];
                            values[executionDay] = entries;
                        }
                    }
                }
            }

            // Week loop.
            for (StandingOrder *order in standingOrders.arrangedObjects) {
                ShortDate *firstExecution = [ShortDate dateWithDate: order.firstExecDate];
                ShortDate *lastExecution = order.lastExecDate == nil ? lastDay : [ShortDate dateWithDate: order.lastExecDate];
                if (order.period.intValue == stord_weekly)
                {
                    int endWeek = lastDay.week;
                    if (endWeek < (int)firstDay.week)
                        endWeek += 52;
                    for (int week = firstDay.week; week <= endWeek; ++week) {

                        int delta = week - firstExecution.week;
                        if (delta < 0) {
                            delta += 52;
                        }
                        if (delta % order.cycle.intValue == 0) {
                            int day = order.executionDay.intValue;
                            ShortDate *executionDay = [ShortDate dateWithYear: date.year
                                                                         week: week
                                                                    dayInWeek: day];

                            if ([firstExecution compare: executionDay] != NSOrderedDescending &&
                                [lastExecution compare: executionDay] != NSOrderedAscending) {
                                
                                NSMutableArray *entries = values[executionDay];
                                if (entries == nil) {
                                    entries = [NSMutableArray array];
                                }
                                [entries addObject: order];
                                values[executionDay] = entries;
                            }
                        }
                    }
                }
            }

            calendar.values = values;
            [calendar setNeedsDisplay: YES];
        }
        date = [date dateByAddingUnits: 1 byUnit: NSCalendarUnitMonth];
    }

    LogLeave;
}

- (void)resizeWithOldSuperviewSize: (NSSize)oldSize
{
    LogEnter;

    NSRect frame = self.bounds;
    frame.origin.x = frame.size.width - contentWidth + 15;
    frame.size.width = contentWidth - 50;
    frame.origin.y = frame.size.height - 20 - CALENDAR_HEIGHT + self.scrollOffset % CALENDAR_HEIGHT;
    frame.size.height = CALENDAR_HEIGHT - 10;
    for (NextTransfersCalendar *calendar in self.subviews) {
        calendar.frame = frame;
        frame.origin.y -= CALENDAR_HEIGHT;
    }

    LogLeave;
}

@end

@implementation OrderTableCellView
@end

@interface NextTransfersCard ()
{
    BandView *bandView;

    IBOutlet NSPopover  *ordersPopover;
    IBOutlet NSTableView *ordersPopupList;
    IBOutlet NSArrayController *popoverDataController;
}

@property (strong) NSArray *popoverData;

@end

@implementation NextTransfersCard

- (id)initWithFrame: (NSRect)frame
{
    LogEnter;

    self = [super initWithFrame: frame];
    if (self) {
        if (![NSBundle loadNibNamed: @"HomeScreenNextTransfers" owner: self]) {
            [[MessageLog log] addMessage: @"Internal error: home screen next transfers view loading failed" withLevel: LogLevel_Error];
        }

        [self loadData];
        [NSNotificationCenter.defaultCenter addObserver: self
                                               selector: @selector(handleDataModelChange:)
                                                   name: NSManagedObjectContextDidSaveNotification
                                                 object: MOAssistant.assistant.context];

        
    }

    LogLeave;

    return self;
}

- (void)dealloc
{
    LogEnter;

    [NSNotificationCenter.defaultCenter removeObserver: self];

    LogLeave;
}

- (void)handleDataModelChange: (NSNotification *)notification
{
    LogEnter;

    @try {
        if (BankingController.controller.shuttingDown) {
            return;
        }

        [bandView updateCalendarsWithFetch: YES];
    }
    @catch (NSException *error) {
        LogError(@"%@", error.debugDescription);
    }

    LogLeave;
}

- (void)loadData
{
    LogEnter;

    // View sizes are just dummy values. Layout is done below.
    BandEndView *startView = [[BandEndView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100) isTop: NO];
    bandView = [[BandView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10) startingEnd: startView card: self];
    bandView.listMode = NO;
    [self addSubview: bandView];

    BandEndView *endView = [[BandEndView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100) isTop: YES];
    [self addSubview: endView];
    [self addSubview: startView];

    //ordersPopupList.dataSource = self;
    ordersPopupList.delegate = self;
    popoverDataController.managedObjectContext = MOAssistant.assistant.context;

    LogLeave;
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize
{
    LogEnter;

   NSRect frame = self.bounds;
    frame.origin.x = NSWidth(frame) / 3.0 - 15;
    frame.size.width = 2 * NSWidth(frame) / 3.0 - 10;
    frame.size.height = 20;

    for (id child in self.subviews) {
        if ([child isKindOfClass: BandEndView.class]) {
            BandEndView *view = child;
            if ([view isTop]) {
                frame.origin.y = 40;
            } else {
                frame.origin.y = NSMaxY(self.bounds) - NSHeight(frame) - 30;
            }
            view.frame = frame;
        } else {
            BandView *view = child;
            NSRect bandFrame = NSInsetRect(self.bounds, 15, 40);
            bandFrame.origin.y += 5;
            view.frame = bandFrame;
            view.contentWidth = NSWidth(frame); // Content is drawn with the same width as the band end size.
        }
        [child resizeWithOldSuperviewSize: oldSize];
    }

    LogLeave;
}

- (void)showValuePopupForDate: (ShortDate *)date
                       values: (NSArray *)values
               relativeToRect: (NSRect)area
                      forView: (NSView *)view
{
    LogEnter;

    self.popoverData = values;
    popoverDataController.content = values;

    NSRect frame = ordersPopupList.frame;
    frame.origin = NSMakePoint(2, 2);
    if (values.count < 6) {
        frame.size.height = MAX(values.count, 1) * 51;
    } else {
        frame.size.height = 5 * 51;
    }

    NSSize contentSize = frame.size;
    //contentSize.width += 4; // Border left/right.
    contentSize.height += 4; // Ditto for top/bottom.
    ordersPopupList.frame = frame;
    ordersPopover.contentSize = contentSize;

    [ordersPopupList reloadData];

    [ordersPopover showRelativeToRect: area ofView: view preferredEdge: NSMaxXEdge];
    ordersPopupList.frameOrigin = frame.origin; // Set the origin again, as NSPopover messes this up.

    LogLeave;
}

- (void)cancelPopover
{
    [ordersPopover close];
}

#pragma mark - NSTableViewDataSource protocol

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.popoverData.count;
}

- (NSView *)tableView: (NSTableView *)tableView
   viewForTableColumn: (NSTableColumn *)tableColumn
                  row: (NSInteger)row
{
    if (row >= (NSInteger)self.popoverData.count) {
        return nil;
    }

    return [tableView makeViewWithIdentifier: @"OrderCell" owner: self];
}

- (NSTableRowView *)tableView: (NSTableView *)tableView rowViewForRow: (NSInteger)row
{
    NSTableRowView *view = [[NSTableRowView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
    return view;
}

- (CGFloat)tableView: (NSTableView *)tableView heightOfRow: (NSInteger)row
{
    return 50;
}

- (BOOL)tableView: (NSTableView *)tableView isGroupRow:( NSInteger)row
{
    return NO;
}

- (NSIndexSet *)tableView: (NSTableView *)tableView selectionIndexesForProposedSelection: (NSIndexSet *)proposedSelectionIndexes
{
    return nil;
}

@end
