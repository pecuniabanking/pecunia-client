//
//  SimpleDate.h
//  Pecunia
//
//  Created by Frank Emminghaus on 15.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * ShortDate is a specialization of the NSDate class which only considers full days
 * (it rounds itself to midnight 0h:0m:0s) and provides convenience methods to
 * do date arithmetics.
 */
@interface ShortDate : NSObject {
    NSDate* inner;
    NSDateComponents* components; // The date split into components.
}

@property (nonatomic, assign, readonly) unsigned year;
@property (nonatomic, assign, readonly) unsigned month;
@property (nonatomic, assign, readonly) unsigned day;
@property (nonatomic, assign, readonly) unsigned quarter;
@property (nonatomic, assign, readonly) unsigned week;

- (id)initWithDate: (NSDate*)date;
- (NSComparisonResult)compare: (ShortDate*)date;
- (NSDate*)lowDate;
- (NSDate*)highDate;

- (BOOL)isBetween: (ShortDate*)fromDate and:(ShortDate*)toDate;
- (int)unitsToDate: (ShortDate*)toDate byUnit: (int)calendarUnit;

- (ShortDate*)dateByAddingUnits: (int)units byUnit: (int)calendarUnit;

- (BOOL)isEqual: (ShortDate*)date;
- (NSUInteger)hash;
- (int)daysInMonth;

- (NSString*)description;
- (NSString*)monthYearDescription;
- (NSString*)quarterYearDescription;
- (NSString*)yearDescription;
- (NSString*)weekYearDescription;

- (ShortDate*)firstDayInYear;
- (ShortDate*)lastDayInYear;
- (ShortDate*)firstDayInMonth;
- (ShortDate*)lastDayInMonth;
- (ShortDate*)firstDayInQuarter;
- (ShortDate*)lastDayInQuarter;
- (ShortDate*)firstDayInWeek;
- (ShortDate*)lastDayInWeek;

+ (ShortDate*)dateWithDate: (NSDate*)date;
+ (ShortDate*)currentDate;
+ (ShortDate*)dateWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d;
+ (ShortDate*)distantFuture;
+ (ShortDate*)distantPast;
+ (NSCalendar*)calendar;

@end
