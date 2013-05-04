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

- (id)initWithDateFormatter: (NSDateFormatter *)aDateFormatter calendarUnit: (int)unit
{
    self = [super initWithDateFormatter: aDateFormatter];
    if (self != nil) {
        calendarUnit = unit;
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
        case NSDayCalendarUnit:
            result = [date description];
            break;

        case NSWeekCalendarUnit:
            result = [date weekYearDescription];
            break;

        case NSMonthCalendarUnit:
            result = [date monthYearDescription];
            break;

        case NSQuarterCalendarUnit:
            result = [date quarterYearDescription];
            break;

        case NSYearCalendarUnit:
            result = [date yearDescription];
            break;
    }
    return result;
}

@end
