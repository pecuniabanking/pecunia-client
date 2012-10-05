//
//  PecuniaPlotTimeFormatter.m
//  Pecunia
//
//  Created by Mike Lischke on 25.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "PecuniaPlotTimeFormatter.h"
#import "ShortDate.h"

@implementation PecuniaPlotTimeFormatter

- (id)initWithDateFormatter: (NSDateFormatter*)aDateFormatter calendarUnit: (int)unit
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
- (NSString*)stringForObjectValue: (NSDecimalNumber*)coordinateValue
{
    NSString* result = @"?";
    ShortDate* date = [ShortDate dateWithDate: self.referenceDate];
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
