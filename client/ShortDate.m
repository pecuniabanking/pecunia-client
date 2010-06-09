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
	self = [super init ];
	if(self == nil) return nil;
	if(calendar == nil) calendar = [[NSCalendar alloc ] initWithCalendarIdentifier: NSGregorianCalendar ];
	NSDateComponents *comps = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate: date ];
	year = [comps year ];
	month = [comps month ];
	day = [comps day ];
	return self;
}

-(id)initWithYear: (int)y month: (int)m day: (int)d
{
	self = [super init ];
	if(self == nil) return nil;
	if(calendar == nil) calendar = [[NSCalendar alloc ] initWithCalendarIdentifier: NSGregorianCalendar ];
	year = y;
	month = m;
	day = d;
	return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
	[super init ];
	year = [coder decodeIntForKey: @"year" ];
	day = [coder decodeIntForKey: @"day" ];
	month = [coder decodeIntForKey: @"month" ];
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
	[coder encodeInt: year forKey: @"year" ];
	[coder encodeInt: day forKey: @"day" ];
	[coder encodeInt: month forKey: @"month" ];
}


-(id)copyWithZone: (NSZone *)zone
{
	return [self retain ];
}

- (NSDate*)lowDate
{
	NSDateComponents *comps = [[[NSDateComponents alloc] init] autorelease ];
	[comps setYear: year];
	[comps setMonth: month];
	[comps setDay: day];
	[comps setHour: 0];
	[comps setMinute: 0];
	[comps setSecond: 0];
	return [calendar dateFromComponents: comps ];
}

- (NSDate*)highDate
{
	NSDateComponents *comps = [[[NSDateComponents alloc] init] autorelease ];
	[comps setYear: year];
	[comps setMonth: month];
	[comps setDay: day];
	[comps setHour: 23];
	[comps setMinute: 59];
	[comps setSecond: 59];
	return [calendar dateFromComponents: comps ];
}


-(NSComparisonResult)compare: (ShortDate*)date
{
	if(year < [date year ]) return NSOrderedAscending;
	if(year > [date year ]) return NSOrderedDescending;
	if(month < [date month ]) return NSOrderedAscending;
	if(month > [date month ]) return NSOrderedDescending;
	if(day < [date day ]) return NSOrderedAscending;
	if(day > [date day ]) return NSOrderedDescending;
	return NSOrderedSame;
}

-(BOOL)isBetween: (ShortDate*)fromDate and:(ShortDate*)toDate
{
	unsigned fy = [fromDate year ];
	unsigned ty = [toDate year ];
	unsigned fm = [fromDate month ];
	unsigned tm = [toDate month ];
	
	if(year < fy || year > ty) return NO;
	if(year == fy) if(month < fm || month == fm && day < [fromDate day ]) return NO;
	if(year == ty) if(month > tm || month == tm && day > [toDate day ]) return NO;
	return YES;
}

- (BOOL)isEqual: (ShortDate*)date
{
	return year == [date year ] && month == [date month ] && day == [date day ];
}

- (NSUInteger)hash
{
	return year*372+month*31+day;
}



-(int)daysToDate: (ShortDate*)toDate
{
	NSDateComponents *comps = [calendar components:NSDayCalendarUnit fromDate:[self lowDate ]  toDate:[toDate lowDate ]  options:0];
	return [comps day];
}

-(ShortDate*)dateByAddingDays: (int)days
{
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:days ];
	NSDate *date = [calendar dateByAddingComponents:comps toDate:[self lowDate] options:0 ];
	[comps release];
	return [ShortDate dateWithDate: date ];
}


- (unsigned)year {
    return year;
}

- (unsigned)month {
    return month;
}

- (unsigned)day {
    return day;
}

-(int)daysInMonth
{
	NSRange r = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate: [self lowDate ] ];
	return r.length;
}

+(id)dateWithDate: (NSDate*)date
{
	ShortDate *res = [[ShortDate alloc ] initWithDate: date ];
	return [res autorelease ];
}

+(id)dateWithYear: (int)y month: (int)m day: (int)d
{
	ShortDate *res = [[ShortDate alloc ] initWithYear: y month: m day: d ];
	return [res autorelease ];
}

+(id)distantFuture
{
	return [ShortDate dateWithYear: 9999 month:12 day:31 ];
}

+(id)distantPast
{
	return [ShortDate dateWithYear: 2000 month:1 day:1 ];
}

+(NSCalendar*)calendar
{
	if(calendar) return calendar;
	calendar = [[NSCalendar alloc ] initWithCalendarIdentifier: NSGregorianCalendar ];
	return calendar;
}


@end
