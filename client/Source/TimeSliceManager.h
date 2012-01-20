//
//  TimeSliceManager.h
//  Pecunia
//
//  Created by Frank Emminghaus on 20.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	slice_none = -1,
	slice_year = 0,
	slice_quarter,
	slice_month,
} SliceType;

@class ShortDate;

@interface TimeSliceManager : NSObject {
    NSUInteger year;
    NSUInteger quarter;
    NSUInteger month;
    SliceType type;
    NSString *autosaveName;
    
    ShortDate *minDate;
    ShortDate *maxDate;
    ShortDate *fromDate;
    ShortDate *toDate;
    
    IBOutlet NSDatePicker *fromPicker;
    IBOutlet NSDatePicker *toPicker;
    
    IBOutlet id delegate;
    IBOutlet NSSegmentedControl *control;
    
    NSMutableArray *controls;
}

-(id)initWithYear: (int)y month: (int)m;
-(ShortDate*)lowerBounds;
-(ShortDate*)upperBounds;
-(void)stepUp;
-(void)stepDown;
-(void)stepIn: (ShortDate*)date;
-(void)setMinDate: (ShortDate*)date;
-(void)setMaxDate: (ShortDate*)date;

-(void)updateControl;
-(void)updateDelegate;
-(void)updatePickers;

-(IBAction)dateChanged: (id)sender;
-(IBAction)timeSliceChanged: (id)sender;
-(IBAction)timeSliceUpDown: (id)sender;

-(void)save;
-(NSPredicate*)predicateForField: (NSString*)field;
-(NSString*)description;

//+(void)initialize;
+(TimeSliceManager*)defaultManager;


@end


extern TimeSliceManager *timeSliceManager;
