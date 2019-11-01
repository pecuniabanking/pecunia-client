/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

/**
 * ShortDate is a specialization of the NSDate class which only considers full days
 * (it rounds itself to midnight 0h:0m:0s) and provides convenience methods to
 * do date arithmetics.
 */
@interface ShortDate : NSObject<NSCopying, NSCoding> {
    NSDate           *inner;
    NSDateComponents *components; // The date split into components.
}

@property (nonatomic, assign, readonly) unsigned year;
@property (nonatomic, assign, readonly) unsigned month;
@property (nonatomic, assign, readonly) unsigned day;
@property (nonatomic, assign, readonly) unsigned quarter;
@property (nonatomic, assign, readonly) unsigned week;

- (id)initWithDate: (NSDate *)date;
- (NSComparisonResult)compare: (ShortDate *)date;
- (NSComparisonResult)compareReversed: (ShortDate *)date;
- (NSDate *)lowDate;
- (NSDate *)highDate;

- (BOOL)isBetween: (ShortDate *)fromDate and: (ShortDate *)toDate;
- (int)unitsToDate: (ShortDate *)toDate byUnit: (NSCalendarUnit)calendarUnit;

- (ShortDate *)dateByAddingUnits: (int)units byUnit: (NSCalendarUnit)calendarUnit;

- (BOOL)isEqual: (ShortDate *)date;
- (NSUInteger)hash;
- (int)daysToDate: (ShortDate *)toDate;
- (int)monthsToDate: (ShortDate *)toDate;
- (int)daysInMonth;

- (NSString *)isoDate;
- (NSString *)description;
- (NSString *)shortMonthDescription; // 3 letters month name
- (NSString *)monthYearDescription;
- (NSString *)longMonthYearDescription;
- (NSString *)quarterYearDescription;
- (NSString *)yearDescription;
- (NSString *)weekYearDescription;

- (ShortDate *)firstDayInYear;
- (ShortDate *)lastDayInYear;
- (ShortDate *)firstDayInMonth;
- (ShortDate *)lastDayInMonth;
- (ShortDate *)firstDayInQuarter;
- (ShortDate *)lastDayInQuarter;
- (NSInteger)dayInWeek;
- (ShortDate *)firstDayInWeek;
- (ShortDate *)lastDayInWeek;

- (BOOL)isFirstDayInMonth;

+ (ShortDate *)dateWithDate: (NSDate *)date;
+ (ShortDate *)currentDate;
+ (ShortDate *)dateWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d;
+ (ShortDate *)dateWithYear: (unsigned)y week: (unsigned)w dayInWeek: (unsigned)d;
+ (ShortDate *)distantFuture;
+ (ShortDate *)distantPast;
+ (NSCalendar *)calendar;

@end
