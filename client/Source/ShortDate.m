//
//  SimpleDate.m
//  Pecunia
//
//  Created by Frank Emminghaus on 15.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "ShortDate.h"

NSCalendar *calendar = nil;

@implementation ShortDate

-(id)initWithDate: (NSDate*)date
{
    self = [super init];
    if (self != nil) {
        // The computation for quaters seems to be non-existant. We use months instead to compute that.
        components = [[[ShortDate calendar] components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit
                                              fromDate: date]
                      retain];
    }        
    return self;
}

- (id)initWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d
{
    self = [super init];
    if (self != nil) {
        // Create an NSDate first from the components and then retrieve those that are not specified.
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        comps.year = y;
        comps.month = m;
        comps.day = d;
        NSDate *date = [[ShortDate calendar] dateFromComponents: comps];
        [comps release];
        
        components = [[calendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit
                                  fromDate: date]
                      retain];
    }
    return self;
}

- (id)initWithCoder: (NSCoder*)coder
{
    self = [super init];
    if (self != nil) {
        // TODO: retain needed?
        components = [[coder decodeObjectForKey: @"components"] retain];
    }
    return self;
}

- (void)dealloc
{
    [components release];
    [super dealloc];
}

- (void)encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: components forKey: @"components"];
}


- (id)copyWithZone: (NSZone *)zone
{
    return [self retain];
}

- (NSDate*)lowDate
{
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    return [[ShortDate calendar] dateFromComponents: components];
}

- (NSDate*)highDate
{
    components.hour = 23;
    components.minute = 59;
    components.second = 59;
    return [[ShortDate calendar] dateFromComponents: components];
}


- (NSComparisonResult)compare: (ShortDate*)date
{
    if (components.year < date.year) return NSOrderedAscending;
    if (components.year > date.year) return NSOrderedDescending;
    if (components.month < date.month) return NSOrderedAscending;
    if (components.month > date.month) return NSOrderedDescending;
    if (components.day < date.day) return NSOrderedAscending;
    if (components.day > date.day) return NSOrderedDescending;
    return NSOrderedSame;
}

-(BOOL)isBetween: (ShortDate*)fromDate and: (ShortDate*)toDate
{
    unsigned fy = fromDate.year;
    unsigned ty = toDate.year;
    unsigned fm = fromDate.month;
    unsigned tm = toDate.month;
    
    if (components.year < fy || components.year > ty) {
        return NO;
    }
    if (components.year == fy) {
        if ((components.month < fm) || (components.month == fm) && (components.day < fromDate.day)) {
            return NO;
        }
    }
    if (components.year == ty) {
        if ((components.month > tm) || (components.month == tm) && (components.day > toDate.day)) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqual: (ShortDate*)date
{
    return (components.year == date.year) && (components.month == date.month) && (components.day == date.day);
}

- (NSUInteger)hash
{
    // TODO: Shouldn't the magic numbers be prime numbers actually?
    return components.year * 372 + components.month * 31 + components.day;
}


- (int)daysToDate: (ShortDate*)toDate
{
    NSDateComponents *comps = [calendar components:NSDayCalendarUnit fromDate: self.lowDate toDate: toDate.lowDate  options: 0];
    return [comps day];
}

- (int)monthsToDate: (ShortDate*)toDate
{
    NSDateComponents *comps = [calendar components: NSMonthCalendarUnit fromDate: self.lowDate toDate: toDate.lowDate options: 0];
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
- (int)unitsToDate: (ShortDate*)toDate byUnit: (int)calendarUnit
{
    switch (calendarUnit) {
        case NSYearCalendarUnit:
            return toDate.year - components.year;
        case NSMonthCalendarUnit:
            return 12 * (toDate.year - components.year) + (toDate.month - components.month);
        case NSDayCalendarUnit: {
            NSDateComponents *comps = [calendar components: NSDayCalendarUnit fromDate: self.lowDate toDate: toDate.lowDate  options: 0];
            return comps.day;
        }
        case NSWeekCalendarUnit:
            return 52 * (toDate.year - components.year) + (toDate.week - components.week);
        case NSQuarterCalendarUnit:
            return 4 * (toDate.year - components.year) + (toDate.quarter - self.quarter);
        default:
            return 0;
    }
}

-(ShortDate*)dateByAddingDays: (int)days
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:days ];
    NSDate *date = [calendar dateByAddingComponents:comps toDate:[self lowDate] options:0 ];
    [comps release];
    return [ShortDate dateWithDate: date ];
}

-(ShortDate*)dateByAddingMonths: (int)months
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:months ];
    NSDate *date = [calendar dateByAddingComponents:comps toDate:[self lowDate] options:0 ];
    [comps release];
    return [ShortDate dateWithDate: date ];
}

-(ShortDate*)dateByAddingYears: (int)years
{
    return [ShortDate dateWithYear: components.year + years month: components.month day: components.day];
}

- (ShortDate*)dateByAddingUnits: (int)units byUnit: (int)calendarUnit
{
    NSDateComponents* comps = [components copy];
    
    switch (calendarUnit) {
        case NSYearCalendarUnit:
            comps.year += units;
            break;
        case NSMonthCalendarUnit:
            comps.month += units;
            break;
        case NSDayCalendarUnit:
            comps.day += units;
            break;
        case NSWeekCalendarUnit:
            comps.day += 7 * units;
            break;
        case NSQuarterCalendarUnit:
            comps.month += 3 * units;
            break;
    }
    comps.hour = NSUndefinedDateComponent;
    comps.minute = NSUndefinedDateComponent;
    comps.second = NSUndefinedDateComponent;
    NSDate* date = [calendar dateFromComponents: comps];
    [comps release];
    
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

- (unsigned)quarter
{
    return (components.month - 1) / 3 + 1;
}

- (unsigned)week
{
    return components.week;
}

-(int)daysInMonth
{
    NSRange r = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate: [self lowDate ] ];
    return r.length;
}

- (NSString*)description
{
    NSDateFormatter *df = [[NSDateFormatter alloc ] init ];
    [df setDateStyle:NSDateFormatterMediumStyle ];
    [df setTimeStyle:NSDateFormatterNoStyle ];
    
    return [df stringFromDate:[self lowDate ] ];
}

- (NSString*)monthYearDescription
{
    return [NSString stringWithFormat: @"%d/%d", components.month, components.year];
}

- (NSString*)quarterYearDescription
{
    return [NSString stringWithFormat: @"Q%d/%d", self.quarter, components.year];
}

- (NSString*)yearDescription
{
    return [NSString stringWithFormat: @"%d", components.year];
}

- (NSString*)weekYearDescription
{
    // TODO: localization?
    return [NSString stringWithFormat: @"KW %d/%d", components.week, components.year]; 
}

-(ShortDate*)firstDayInYear
{
    return [ShortDate dateWithYear: components.year month: 1 day: 1];
}

-(ShortDate*)lastDayInYear
{
    return [ShortDate dateWithYear: components.year month: 12 day: 31];
}

-(ShortDate*)firstDayInMonth
{
    return [ShortDate dateWithYear: components.year month: components.month day: 1];
}

-(ShortDate*)lastDayInMonth
{
    return [ShortDate dateWithYear: components.year month: components.month day: [self daysInMonth]];
}

-(ShortDate*)firstDayInQuarter
{
    return [ShortDate dateWithYear: components.year month: (self.quarter - 1) * 3 + 1 day: 1];
}

-(ShortDate*)lastDayInQuarter
{
    ShortDate *lastMonth = [ShortDate dateWithYear: components.year month: (self.quarter) * 3 day: 1];
    return [lastMonth lastDayInMonth ];
}

- (ShortDate*)firstDayInWeek
{
    NSDateComponents *comps = [calendar components: NSWeekdayCalendarUnit fromDate: [self lowDate]];
    
    return [self dateByAddingUnits: (calendar.firstWeekday - [comps weekday]) byUnit: NSWeekdayCalendarUnit];
}

- (ShortDate*)lastDayInWeek
{
    NSDateComponents *comps = [calendar components: NSWeekdayCalendarUnit fromDate: [self lowDate]];
    
    return [self dateByAddingUnits: (7 - [comps weekday]) byUnit: NSWeekdayCalendarUnit];
}

+(ShortDate*)dateWithDate: (NSDate*)date
{
    ShortDate *res = [[ShortDate alloc ] initWithDate: date ];
    return [res autorelease ];
}

+(ShortDate*)currentDate
{
    return [ShortDate dateWithDate:[NSDate date ] ];
}


+(ShortDate*)dateWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d
{
    ShortDate *res = [[ShortDate alloc ] initWithYear: y month: m day: d ];
    return [res autorelease ];
}

+(ShortDate*)distantFuture
{
    return [ShortDate dateWithYear: 9999 month:12 day:31 ];
}

+(ShortDate*)distantPast
{
    return [ShortDate dateWithYear: 2000 month:1 day:1 ];
}

+(NSCalendar*)calendar
{
    if (calendar == nil) {
        calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:  NSGregorianCalendar] retain];
        calendar.firstWeekday = 1; // Set monday as first day of week.
    }
    return calendar;
}

@end
