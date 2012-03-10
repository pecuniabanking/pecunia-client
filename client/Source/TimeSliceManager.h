/**
 * Copyright (c) 2009, 2012, Pecunia Project. All rights reserved.
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

typedef enum {
	slice_none = -1,
	slice_year = 0,
	slice_quarter,
	slice_month,
} SliceType;

@class ShortDate;

@interface TimeSliceManager : NSObject {
    NSUInteger year;
    NSInteger quarter;
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
