/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "PecuniaPlotTimeFormatter.h"
#import "ShortDate.h"

@implementation PecuniaPlotTimeFormatter

@synthesize useMonthNames;

- (id)initWithDateFormatter: (NSDateFormatter *)aDateFormatter calendarUnit: (NSCalendarUnit)unit
{
    self = [super initWithDateFormatter: aDateFormatter];
    if (self != nil) {
        calendarUnit = unit;
        aDateFormatter.dateFormat = @"MMM";
    }
    return self;
}

/**
 * @brief Converts a decimal number for the time into a date string. The value must be given in units
 * specified by initWithDateFormatter:calendarUnit.
 **/
- (NSString *)stringForObjectValue: (NSDecimalNumber *)coordinateValue
{
    NSString  *result = @"?";
    ShortDate *date = [ShortDate dateWithDate: self.referenceDate];
    date = [date dateByAddingUnits: [coordinateValue intValue] byUnit: calendarUnit];

    switch (calendarUnit) {
        case NSCalendarUnitDay:
            result = [date description];
            break;

        case NSWeekCalendarUnit:
            result = [date weekYearDescription];
            break;

        case NSCalendarUnitMonth:
            result = useMonthNames ? [self.dateFormatter stringFromDate: date.lowDate] : [date monthYearDescription];
            break;

        case NSCalendarUnitQuarter:
            result = [date quarterYearDescription];
            break;

        case NSCalendarUnitYear:
            result = [date yearDescription];
            break;
            
        default: break;
    }
    return result;
}

@end

@interface StocksPlotTimeFormatter ()
{
    NSCalendarUnit calendarUnit;
}
@end

@implementation StocksPlotTimeFormatter

- (id)initWithDateFormatter: (NSDateFormatter *)aDateFormatter calendarUnit: (NSCalendarUnit)unit
{
    self = [super initWithDateFormatter: aDateFormatter];
    if (self != nil) {
        calendarUnit = unit;
        aDateFormatter.dateFormat = @"MMM";
    }
    return self;
}

- (NSString *)stringForObjectValue: (NSDecimalNumber *)coordinateValue
{
    NSString  *result = @"?";
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: coordinateValue.intValue];
    NSDateComponents *components = [[ShortDate calendar] components: NSCalendarUnitYear | NSCalendarUnitMonth |
                                    NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSHourCalendarUnit
                                                           fromDate: date];

    switch (calendarUnit) {
        case NSHourCalendarUnit:
        {
            NSInteger hour = components.hour;
            result = [NSString stringWithFormat: @"%ldh", hour];
            break;
        }

        case NSCalendarUnitDay:
            result = [NSString stringWithFormat: @"%ld", components.day];
            break;

        case NSCalendarUnitWeekOfYear:
            result = [NSString stringWithFormat: @"%ld", components.weekOfYear];
            break;

        case NSCalendarUnitMonth:
            result = [self.dateFormatter stringFromDate: date];
            break;

        case NSCalendarUnitQuarter:
            result = [NSString stringWithFormat: @"Q%li/%li", (components.month - 1) / 3 + 1, components.year];
            break;

        case NSCalendarUnitYear:
            result = [NSString stringWithFormat: @"%li", components.year];
            break;
            
        default: break;
    }
    return result;
}

@end
