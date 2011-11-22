//
//  SimpleDate.h
//  Pecunia
//
//  Created by Frank Emminghaus on 15.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ShortDate : NSObject {
	unsigned			year;
	unsigned			month;
	unsigned			day;
}

@property (nonatomic, assign, readonly) unsigned year;
@property (nonatomic, assign, readonly) unsigned month;
@property (nonatomic, assign, readonly) unsigned day;
@property (nonatomic, assign, readonly) unsigned quarter;

- (id)initWithDate: (NSDate*)date;
- (NSComparisonResult)compare: (ShortDate*)date;
- (NSDate*)lowDate;
- (NSDate*)highDate;
- (BOOL)isBetween: (ShortDate*)fromDate and:(ShortDate*)toDate;
- (int)daysToDate: (ShortDate*)toDate;
- (int)monthsToDate: (ShortDate*)toDate;
- (ShortDate*)dateByAddingDays: (int)days;
- (ShortDate*)dateByAddingMonths: (int)months;
- (ShortDate*)dateByAddingYears: (int)years;

- (BOOL)isEqual: (ShortDate*)date;
- (NSUInteger)hash;
- (int)daysInMonth;

- (NSString*)description;
- (NSString*)monthYearDescription;
- (NSString*)quarterYearDescription;
- (NSString*)yearDescription;

-(ShortDate*)firstDayInYear;
-(ShortDate*)lastDayInYear;
-(ShortDate*)firstDayInMonth;
-(ShortDate*)lastDayInMonth;
-(ShortDate*)firstDayInQuarter;
-(ShortDate*)lastDayInQuarter;

+(ShortDate*)dateWithDate: (NSDate*)date;
+(ShortDate*)currentDate;
+(ShortDate*)dateWithYear: (unsigned)y month: (unsigned)m day: (unsigned)d;
+(ShortDate*)distantFuture;
+(ShortDate*)distantPast;
+(NSCalendar*)calendar;

@end
