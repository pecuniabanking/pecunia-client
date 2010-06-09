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

- (id)initWithDate: (NSDate*)date;
- (NSComparisonResult)compare: (ShortDate*)date;
- (NSDate*)lowDate;
- (NSDate*)highDate;
- (BOOL)isBetween: (ShortDate*)fromDate and:(ShortDate*)toDate;
- (int)daysToDate: (ShortDate*)toDate;
- (ShortDate*)dateByAddingDays: (int)days;
- (BOOL)isEqual: (ShortDate*)date;
- (NSUInteger)hash;
- (int)daysInMonth;

- (unsigned)year;
- (unsigned)month;
- (unsigned)day;

+(id)dateWithDate: (NSDate*)date;
+(id)dateWithYear: (int)y month: (int)m day: (int)d;
+(id)distantFuture;
+(id)distantPast;
+(NSCalendar*)calendar;

@end
