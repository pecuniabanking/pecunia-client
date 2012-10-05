//
//  TimeSliceManager.m
//  Pecunia
//
//  Created by Frank Emminghaus on 20.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "TimeSliceManager.h"
#import "ShortDate.h"
#import "Category.h"

TimeSliceManager *timeSliceManager = nil;

@interface NSObject(TimeSliceManager)
-(NSString*)autosaveNameForTimeSlicer: (TimeSliceManager*)tsm;
-(void)timeSliceManager: (TimeSliceManager*)tsm changedIntervalFrom: (ShortDate*)from to: (ShortDate*)to;
@end



@implementation TimeSliceManager

@synthesize _minDate;
@synthesize _maxDate;
@synthesize fromDate;
@synthesize toDate;
@synthesize autosaveName;


-(void)awakeFromNib
{
	BOOL savedValues = NO;
	
	if([delegate respondsToSelector: @selector(autosaveNameForTimeSlicer:) ]) {
		self.autosaveName = [delegate autosaveNameForTimeSlicer: self ];
	}
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
	
//	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:5 ];
	if(autosaveName) {
		NSDictionary *values = [userDefaults objectForKey: autosaveName ];
		if(values) {
			type = [[values objectForKey: @"type" ] intValue ];
			year = [[values objectForKey: @"year" ] intValue ];
			month = [[values objectForKey: @"month" ] intValue ];
			self.fromDate = [ShortDate dateWithDate: [values objectForKey: @"fromDate" ] ];
			self.toDate = [ShortDate dateWithDate: [values objectForKey:@"toDate" ] ];
			quarter = (month-1) / 3;
			savedValues = YES;
		}
	}
	if(!savedValues) {
		ShortDate *date = [ShortDate dateWithDate: [NSDate date ] ];
		year = [date year ];
		type = slice_month;
		month = [date month ];
		quarter = (month-1) / 3;
	}
	
	// updateControl?
	[self updateControl ];
	[self updatePickers ];
	[self updateDelegate ];
	
	if(type >=0) [control setSelected: YES forSegment: type ];
}

-(id)initWithYear: (int)y month: (int)m
{
	self = [super init ];
	year = y;
	type = slice_month;
	month = m;
	quarter = (m-1) / 3;
	
	return self;
}

-(void)save
{
	if(!autosaveName) return;
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:5 ];
	[values setValue: [NSNumber numberWithInt: type ] forKey: @"type" ];
	[values setValue: [NSNumber numberWithInt: year ] forKey: @"year" ];
	[values setValue: [NSNumber numberWithInt: month ] forKey: @"month" ];
	[values setValue: [fromDate lowDate] forKey: @"fromDate" ];
	[values setValue: [toDate highDate ] forKey: @"toDate" ];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
	[userDefaults setObject: values forKey: autosaveName ];
}

-(id)initWithCoder:(NSCoder*)coder
{
	[super init ];
	type = [coder decodeIntForKey: @"type" ];
	year = [coder decodeIntForKey: @"year" ];
	quarter = [coder decodeIntForKey: @"quarter" ];
	month = [coder decodeIntForKey: @"month" ];
	self.fromDate = [coder decodeObjectForKey: @"fromDate" ];
	self.toDate = [coder decodeObjectForKey: @"toDate" ];
	return self;
}
	
-(void)encodeWithCoder:(NSCoder*)coder
{
	[coder encodeInt: type forKey: @"type" ];
	[coder encodeInt: year forKey: @"year" ];
	[coder encodeInt: quarter forKey: @"quarter" ];
	[coder encodeInt: month forKey: @"month" ];
	[coder encodeObject:fromDate forKey: @"fromDate" ];
	[coder encodeObject:toDate forKey: @"toDate" ];
}

-(ShortDate*)lowerBounds
{
	ShortDate *date;
	switch(type) {
		case slice_year: date = [ShortDate dateWithYear: year month: 1 day: 1 ]; break;
		case slice_quarter: date = [ShortDate dateWithYear: year month: quarter*3+1 day: 1 ]; break;
		case slice_month: date = [ShortDate dateWithYear: year month: month day: 1 ]; break;
		case slice_none: date = fromDate;
	}
	if(_minDate) {
		if([_minDate compare: date ] == NSOrderedDescending) return _minDate; else return date;
	} else return date;
}

-(ShortDate*)upperBounds
{
	ShortDate *date;
	switch(type) {
		case slice_year: date = [ShortDate dateWithYear: year month: 12 day: 31 ]; break;
		case slice_quarter: {
			int day = (quarter == 0 || quarter == 3) ? 31:30;
			date = [ShortDate dateWithYear: year month: quarter*3+3 day: day ];
			break;
		}
		case slice_month: {
			ShortDate *tdate = [ShortDate dateWithYear: year month: month day: 1 ];
			int day = [tdate daysInMonth ];
			date = [ShortDate dateWithYear: year month: month day: day ];
			break;
		}
		case slice_none: date = toDate;
	}
	if(_maxDate) {
		if([_maxDate compare: date ] == NSOrderedAscending) return _maxDate; else return date;
	} else return date;
}

-(void)stepUp
{
	switch(type) {
		case slice_year: year++; break;
		case slice_quarter: {
			quarter++;
			if(quarter > 3) { quarter = 0; year++; }
			int l = quarter*3+1;
			int u = quarter*3+3;
			if(month<l || month>u) month = l;
			break;
		}
		case slice_month: {
			month++;
			if(month > 12) { month = 1; year++; }
			quarter = (month-1) / 3;
			break;
		}
	}
	if(_maxDate) {
		if(year > [_maxDate year ]) year = [_maxDate year ];
		if(year == [_maxDate year ] && month > [_maxDate month ]) month = [_maxDate month ];
		quarter = (month-1) / 3;
	}
}

-(void)stepDown
{
	switch(type) {
		case slice_year: year--; break;
		case slice_quarter: {
			quarter--;
			if(quarter<0) { quarter = 3; year--; }
			int l = quarter*3+1;
			int u = quarter*3+3;
			if(month<l || month>u) month = l;
			break;
		}
		case slice_month: {
			month--;
			if(month<=0) { month = 12; year--; }
			quarter = (month-1) / 3;
			break;
		}
	}
	if(_minDate) {
		if(year < [_minDate year ]) year = [_minDate year ];
		if(year == [_minDate year ] && month < [_minDate month ]) month = [_minDate month ];
		quarter = (month-1) / 3;
	}
}

-(void)stepIn: (ShortDate*)date
{
	BOOL stepped = NO;
	
	if(_maxDate && [date compare: _maxDate ] == NSOrderedDescending) return;
	while([date compare: [self upperBounds ] ] == NSOrderedDescending) {
		[self stepUp ];
		stepped = YES;
		if(_maxDate && [date compare: _maxDate ] == NSOrderedDescending) break;
	}
	if(stepped) {
		[self updateControl ];
		[self updatePickers ];
		[self updateDelegate ];
		[self save ];
	}
}

-(void)updateControl
{
	if(type == slice_none) {
		// first deactivate timeSlicer
		int idx = [control selectedSegment ];
		if(idx >=0) [control setSelected: NO forSegment: idx ];
	}
	
	// year
	[control setLabel: [[NSNumber numberWithInt: year ] description ] forSegment: 0 ];
	
	// quarter
	NSString *quarterString = [NSString stringWithFormat: @"Q%.1u", quarter+1 ];
	[control setLabel: quarterString forSegment: 1 ];
	
	// month
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSArray* months = [dateFormatter monthSymbols ];
	[control setLabel: [months objectAtIndex:month-1] forSegment: 2 ];
}

-(void)updatePickers
{
	self.fromDate = [self lowerBounds ];
	self.toDate = [self upperBounds ];
	if(fromPicker) [fromPicker setDateValue: [fromDate lowDate ] ];
	if(toPicker) [toPicker setDateValue: [toDate highDate ] ];
	
}

-(void)updateDelegate
{
	if([delegate respondsToSelector: @selector(timeSliceManager:changedIntervalFrom:to:) ]) {
		[delegate timeSliceManager: self changedIntervalFrom: [self lowerBounds ] to: [self upperBounds ] ];
	}
}

-(void)setMinDate: (ShortDate*)date
{
	self._minDate = date;
	if(fromPicker) [fromPicker setMinDate: [date lowDate ] ];
}

-(void)setMaxDate: (ShortDate*)date
{
	self._maxDate = date;
	if(toPicker) [toPicker setMaxDate: [date highDate ] ];
}

-(IBAction)dateChanged: (id)sender
{
	type = slice_none;
	if(sender == fromPicker) self.fromDate = [ShortDate dateWithDate: [sender dateValue ] ];
	else self.toDate = [ShortDate dateWithDate: [sender dateValue ] ];
	[self updateControl ];
	[self updateDelegate ];
	[self save ];
}

-(IBAction)timeSliceChanged: (id)sender
{
	SliceType t = [sender selectedSegment];
	switch(t) {
		case slice_year: break;
		case slice_month: break;
		case slice_quarter: {
			int l = quarter*3+1;
			int u = quarter*3+3;
			if(month<l || month>u) month = l;
			break;
		}
	}
	type = t;
	
	[self updatePickers ];
	[self updateDelegate ];
	[self save ];
}

-(IBAction)timeSliceUpDown: (id)sender
{
	if(type != slice_none) {
		if([sender selectedSegment] == 0) [self stepDown ]; else [self stepUp ];
		[self updateControl ];
		[self updatePickers ];
		[self updateDelegate ];
		[self save ];
	}
}

-(NSPredicate*)predicateForField: (NSString*)field
{
	NSPredicate *pred = [NSPredicate predicateWithFormat: @"(statement.%K => %@) AND (statement.%K <= %@)", field, [[self lowerBounds ] lowDate ], field, [[self upperBounds ] highDate ] ];
	return pred;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"%@ - %@", [self lowerBounds ],  [self upperBounds ] ];
}

-(void)dealloc
{
	[controls release ];
	[_minDate release ];
	[_maxDate release ];
    [fromDate release ];
    [toDate release ];
	[autosaveName release ];
	[super dealloc ];
}

/*
+(void)initialize
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
	timeSliceManager = [userDefaults objectForKey: @"TimeSlice" ];
	if(timeSliceManager == nil) {
		ShortDate *date = [ShortDate dateWithDate: [NSDate date ] ];
		timeSliceManager = [[TimeSliceManager alloc ] initWithYear: [date year ] month: [date month ]];
	}
}
*/


+(TimeSliceManager*)defaultManager
{
	if(timeSliceManager == nil) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults ];
		timeSliceManager = [userDefaults objectForKey: @"CategoryTimeSlice" ];
		if(timeSliceManager == nil) {
			ShortDate *date = [ShortDate dateWithDate: [NSDate date ] ];
			timeSliceManager = [[TimeSliceManager alloc ] initWithYear: [date year ] month: [date month ]];
		}
	}
	return timeSliceManager;
}

@end
