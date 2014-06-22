/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
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

#import "MessageLog.h"
#import "ShortDate.h"

NSCalendar *calendar = nil;

@interface ShortDate ()
{
    NSString *shortMonthName;
}
@end

@implementation ShortDate

- (id)initWithDate: (NSDate *)date {
    self = [super init];
    if (self != nil) {
        if (date == nil) {
            date = NSDate.date;
        }
        components = [[ShortDate calendar] components: NSCalendarUnitYear | NSCalendarUnitMonth |
                      NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday
                                             fromDate: date];

        // Make a copy of the given date set to noon (not midnight as this can produce timezone problems).
        // We need that for various computations.
        components.hour = 12;
        components.minute = 0;
        components.second = 0;
        inner = [calendar dateFromComponents: components];
    }
    return self;
}

- (id)initWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d {
    self = [super init];
    if (self != nil) {
        components = [[NSDateComponents alloc] init];
        components.year = y;
        components.month = m;
        components.day = d;
        components.hour = 12;
        components.minute = 0;
        components.second = 0;

        inner = [calendar dateFromComponents: components];
        components = [calendar components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday
                                 fromDate: inner];
    }
    return self;
}

- (id)initWithYear: (unsigned)y week: (unsigned)w dayInWeek: (unsigned)d {
    self = [super init];
    if (self != nil) {
        components = [[NSDateComponents alloc] init];
        components.yearForWeekOfYear = y;
        components.weekOfYear = w;
        components.weekday = d;
        components.hour = 12;
        components.minute = 0;
        components.second = 0;

        inner = [calendar dateFromComponents: components];
        components = [calendar components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday
                                 fromDate: inner];
    }
    return self;
}

- (id)initWithCoder: (NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        components = [coder decodeObjectForKey: @"components"];
    }
    return self;
}

- (void)encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject: components forKey: @"components"];
}

- (id)copyWithZone: (NSZone *)zone {
    return self;
}

- (NSDate *)lowDate {
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    return [[ShortDate calendar] dateFromComponents: components];
}

- (NSDate *)highDate {
    components.hour = 23;
    components.minute = 59;
    components.second = 59;
    return [[ShortDate calendar] dateFromComponents: components];
}

- (NSComparisonResult)compare: (ShortDate *)date {
    if (components.year < date.year) {
        return NSOrderedAscending;
    }
    if (components.year > date.year) {
        return NSOrderedDescending;
    }
    if (components.month < date.month) {
        return NSOrderedAscending;
    }
    if (components.month > date.month) {
        return NSOrderedDescending;
    }
    if (components.day < date.day) {
        return NSOrderedAscending;
    }
    if (components.day > date.day) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (NSComparisonResult)compareReversed: (ShortDate *)date {
    NSComparisonResult result = [self compare: date];
    switch (result) {
        case NSOrderedAscending:
            return NSOrderedDescending;

        case NSOrderedDescending:
            return NSOrderedAscending;

        default:
            return result;
    }
}

- (BOOL)isBetween: (ShortDate *)fromDate and: (ShortDate *)toDate {
    unsigned fy = fromDate.year;
    unsigned ty = toDate.year;
    unsigned fm = fromDate.month;
    unsigned tm = toDate.month;

    if (components.year < fy || components.year > ty) {
        return NO;
    }
    if (components.year == fy) {
        if ((components.month < fm) || ((components.month == fm) && (components.day < fromDate.day))) {
            return NO;
        }
    }
    if (components.year == ty) {
        if ((components.month > tm) || ((components.month == tm) && (components.day > toDate.day))) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqual: (ShortDate *)date {
    return (components.year == date.year) && (components.month == date.month) && (components.day == date.day);
}

- (NSUInteger)hash {
    return components.year * 372 + components.month * 31 + components.day;
}

- (int)daysToDate: (ShortDate *)toDate {
    NSDateComponents *comps = [calendar components: NSCalendarUnitDay fromDate: self.lowDate toDate: toDate.lowDate options: 0];
    return [comps day];
}

- (int)monthsToDate: (ShortDate *)toDate {
    NSDateComponents *comps = [calendar components: NSCalendarUnitMonth fromDate: self.lowDate toDate: toDate.lowDate options: 0];
    return [comps month];
}

/**
 * Determines the distance between two dates for a given calendar unit.
 * Note: this implementation works in favor of grouping by date units, not by truly doing a date difference
 *       (except for days, where it does not matter and computation is the most difficult).
 *       The result is the difference given by the calendar unit, not counted in days,
 *       e.g. Dec 22, 2010 and Dec 27, 2010 are only 5 days apart (so NSCalendar considers them 0 weeks apart)
 *       however they are actually in two different calendar weeks, so their week difference is 1.
 */
- (int)unitsToDate: (ShortDate *)toDate byUnit: (int)calendarUnit {
    switch (calendarUnit) {
        case NSCalendarUnitYear:
            return toDate.year - components.year;

        case NSCalendarUnitMonth:
            return 12 * (toDate.year - components.year) + (toDate.month - components.month);

        case NSCalendarUnitDay: {
            NSDateComponents *comps = [calendar components: NSCalendarUnitDay fromDate: inner toDate: toDate.lowDate options: 0];
            return comps.day;
        }

        case NSCalendarUnitQuarter:
            return 4 * (toDate.year - components.year) + (toDate.quarter - self.quarter);

        default:
            LogError(@"Invalid calendar unit specified in ShortDate unitsToDate:byUnit:");
            return 0;
    }
}

- (ShortDate *)dateByAddingUnits: (int)units byUnit: (int)calendarUnit {
    NSDateComponents *comps = [components copy];

    // In order to avoid rounding up months to the next higher one if the original day value is beyond
    // the allowed number of days in the target month we compute using the first day in the month
    // and adjust the day afterwards.
    switch (calendarUnit) {
        case NSCalendarUnitYear:
            comps.year += units;
            break;

        case NSCalendarUnitMonth:
            comps.day = 1;
            comps.month += units;
            break;

        case NSWeekCalendarUnit: // NSWeekdayCalendarUnit is deprecated but I have not replacement
                                 // with a timeframe meaning currently.
            comps.day += 7 * units;
            break;

        case NSCalendarUnitWeekday:
        case NSCalendarUnitDay:
            comps.day += units;
            break;

        case NSCalendarUnitQuarter:
            comps.day = 1;
            comps.month += 3 * units;
            break;

        default:
            LogError(@"Invalid calendar unit specified in ShortDate dateByAddingUnits:byUnit:");
            return nil;
    }
    comps.hour = 12;
    comps.minute = 0;
    comps.second = 0;
    NSDate *date = [calendar dateFromComponents: comps];

    switch (calendarUnit) {
        case NSCalendarUnitMonth:
        case NSCalendarUnitQuarter: {
            NSRange   r = [calendar rangeOfUnit: NSCalendarUnitDay inUnit: NSCalendarUnitMonth forDate: date];
            NSInteger day = ((NSInteger)r.length < components.day) ? r.length : components.day;
            date = [date dateByAddingTimeInterval: (day - 1) * 24 * 3600];
            break;
        }
    }

    return [ShortDate dateWithDate: date];
}

- (unsigned)year {
    return components.year;
}

- (unsigned)month {
    return components.month;
}

- (unsigned)day {
    return components.day;
}

- (unsigned)quarter {
    return (components.month - 1) / 3 + 1;
}

- (unsigned)week {
    return components.weekOfYear;
}

- (int)daysInMonth {
    NSRange r = [calendar rangeOfUnit: NSCalendarUnitDay inUnit: NSCalendarUnitMonth forDate: inner];
    return r.length;
}

/**
 * Returns the content of the receiver as an ISO conformal date (YYYY-MM-DD).
 */
- (NSString *)isoDate {
    NSDateFormatter *formatter = [NSDateFormatter new];
    NSLocale        *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"];
    [formatter setLocale: enUSPOSIXLocale];
    [formatter setDateFormat: @"yyyy-MM-dd"];

    return [formatter stringFromDate: self.lowDate];
}

- (NSString *)description {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle: NSDateFormatterMediumStyle];
    [formatter setTimeStyle: NSDateFormatterNoStyle];

    return [formatter stringFromDate: self.lowDate];
}

- (NSString *)shortMonthDescription {
    if (shortMonthName == nil) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MMM";
        shortMonthName = [formatter stringFromDate: self.lowDate];
    }
    return shortMonthName;
}

- (NSString *)monthYearDescription {
    return [NSString stringWithFormat: @"%li/%li", components.month, components.year];
}

- (NSString *)longMonthYearDescription {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMMM y";

    return [formatter stringFromDate: self.lowDate];
}

- (NSString *)quarterYearDescription {
    return [NSString stringWithFormat: @"Q%i/%li", self.quarter, components.year];
}

- (NSString *)yearDescription {
    return [NSString stringWithFormat: @"%li", components.year];
}

- (NSString *)weekYearDescription {
    // TODO: localization?
    return [NSString stringWithFormat: @"KW %li/%li", components.weekOfYear, components.year];
}

- (ShortDate *)firstDayInYear {
    return [ShortDate dateWithYear: components.year month: 1 day: 1];
}

- (ShortDate *)lastDayInYear {
    return [ShortDate dateWithYear: components.year month: 12 day: 31];
}

- (ShortDate *)firstDayInMonth {
    return [ShortDate dateWithYear: components.year month: components.month day: 1];
}

- (ShortDate *)lastDayInMonth {
    return [ShortDate dateWithYear: components.year month: components.month day: [self daysInMonth]];
}

- (ShortDate *)firstDayInQuarter {
    return [ShortDate dateWithYear: components.year month: (self.quarter - 1) * 3 + 1 day: 1];
}

- (ShortDate *)lastDayInQuarter {
    ShortDate *lastMonth = [ShortDate dateWithYear: components.year month: (self.quarter) * 3 day: 1];
    return [lastMonth lastDayInMonth];
}

- (NSInteger)dayInWeek {
    return components.weekday;
}

- (ShortDate *)firstDayInWeek {
    NSDateComponents *comps = [calendar components: NSCalendarUnitWeekday fromDate: [self lowDate]];

    NSInteger offset = calendar.firstWeekday - comps.weekday;
    if (offset > 0) {
        offset -= 7;
    }
    return [self dateByAddingUnits: offset byUnit: NSCalendarUnitWeekday];
}

- (ShortDate *)lastDayInWeek {
    NSDateComponents *comps = [calendar components: NSCalendarUnitWeekday fromDate: [self lowDate]];

    return [self dateByAddingUnits: (7 - comps.weekday) byUnit: NSCalendarUnitWeekday];
}

- (BOOL)isFirstDayInMonth {
    return components.day == 1;
}

+ (ShortDate *)dateWithDate: (NSDate *)date {
    ShortDate *res = [[ShortDate alloc] initWithDate: date];
    return res;
}

+ (ShortDate *)currentDate {
    return [ShortDate dateWithDate: [NSDate date]];
}

+ (ShortDate *)dateWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d {
    ShortDate *res = [[ShortDate alloc] initWithYear: y month: m day: d];
    return res;
}

+ (ShortDate *)dateWithYear: (unsigned)y week: (unsigned)w dayInWeek: (unsigned)d {
    ShortDate *res = [[ShortDate alloc] initWithYear: y week: w dayInWeek: d + calendar.firstWeekday - 1];
    return res;
}

+ (ShortDate *)distantFuture {
    return [ShortDate dateWithYear: 2500 month: 12 day: 31];
}

+ (ShortDate *)distantPast {
    return [ShortDate dateWithYear: 2000 month: 1 day: 1];
}

+ (NSCalendar *)calendar {
    if (calendar == nil) {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:  NSGregorianCalendar];
        calendar.firstWeekday = 2; // Set monday as first day of week.
        calendar.locale = [NSLocale currentLocale];
        calendar.minimumDaysInFirstWeek = 4; // According to DIN 1355-1/ISO 8601.
        calendar.timeZone = [NSTimeZone localTimeZone];
    }
    return calendar;
}

@end
