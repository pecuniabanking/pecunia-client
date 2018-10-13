/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
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

#import "TimeSliceManager.h"
#import "ShortDate.h"
#import "BankingCategory.h"

@interface NSObject (TimeSliceManager)

- (NSString *)autosaveNameForTimeSlicer: (TimeSliceManager *)tsm;
- (void)timeSliceManager: (TimeSliceManager *)tsm changedIntervalFrom: (ShortDate *)from to: (ShortDate *)to;

@end

@implementation TimeSliceManager

@synthesize minDate;
@synthesize maxDate;
@synthesize fromDate;
@synthesize toDate;
@synthesize autosaveName;

- (id)initWithYear: (int)y month: (int)m {
    self = [super init];
    if (self != nil) {
        year = y;
        type = slice_month;
        lastType = slice_month;
        month = m;
        quarter = (m - 1) / 3;
    }
    return self;
}

- (id)initWithCoder: (NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        type = [coder decodeIntForKey: @"type"];
        year = [coder decodeIntForKey: @"year"];
        quarter = [coder decodeIntForKey: @"quarter"];
        month = [coder decodeIntForKey: @"month"];
        fromDate = [coder decodeObjectForKey: @"fromDate"];
        toDate = [coder decodeObjectForKey: @"toDate"];
    }
    return self;
}

- (void)encodeWithCoder: (NSCoder *)coder {
    [coder encodeInt: type forKey: @"type"];
    [coder encodeInt: year forKey: @"year"];
    [coder encodeInt: quarter forKey: @"quarter"];
    [coder encodeInt: month forKey: @"month"];
    [coder encodeObject: fromDate forKey: @"fromDate"];
    [coder encodeObject: toDate forKey: @"toDate"];
}

- (void)awakeFromNib {
    BOOL savedValues = NO;

    if ([delegate respondsToSelector: @selector(autosaveNameForTimeSlicer:)]) {
        self.autosaveName = [delegate autosaveNameForTimeSlicer: self];
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (autosaveName) {
        NSDictionary *values = [userDefaults objectForKey: autosaveName];
        if (values) {
            type = [values[@"type"] intValue];
            year = [values[@"year"] intValue];
            month = [values[@"month"] intValue];
            fromDate = [ShortDate dateWithDate: values[@"fromDate"]];
            toDate = [ShortDate dateWithDate: values[@"toDate"]];
            quarter = (month - 1) / 3;
            savedValues = YES;
        }
    }

    if (!savedValues) {
        ShortDate *date = [ShortDate dateWithDate: [NSDate date]];
        year = date.year;
        type = slice_month;
        month = date.month;
        quarter = (month - 1) / 3;
    }

    lastType = type;

    [self updateControl];
    [self updatePickers];
    [self updateDelegate];

    if (type >= 0) {
        [control setSelected: YES forSegment: type];
    }
}

- (void)save {
    if (autosaveName == nil) {
        return;
    }

    NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity: 5];
    [values setValue: @((int)type) forKey: @"type"];
    [values setValue: @((int)year) forKey: @"year"];
    [values setValue: @((int)month) forKey: @"month"];
    [values setValue: [fromDate lowDate] forKey: @"fromDate"];
    [values setValue: [toDate highDate] forKey: @"toDate"];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject: values forKey: autosaveName];
}

- (ShortDate *)lowerBounds {
    ShortDate *date;
    switch (type) {
        case slice_year:
            date = [ShortDate dateWithYear: year month: 1 day: 1];
            break;

        case slice_quarter:
            date = [ShortDate dateWithYear: year month: quarter * 3 + 1 day: 1];
            break;

        case slice_month:
            date = [ShortDate dateWithYear: year month: month day: 1];
            break;

        case slice_none:
            date = fromDate;
            break;

        case slice_all:
            date = [ShortDate dateWithDate: [NSDate distantPast]];
            break;
    }

    if (minDate) {
        if ([minDate compare: date] == NSOrderedDescending) {
            return minDate;
        } else {
            return date;
        }
    } else {
        return date;
    }
}

- (ShortDate *)upperBounds {
    ShortDate *date;
    switch (type) {
        case slice_year:
            date = [ShortDate dateWithYear: year month: 12 day: 31];
            break;

        case slice_quarter: {
            int day = (quarter == 0 || quarter == 3) ? 31 : 30;
            date = [ShortDate dateWithYear: year month: quarter * 3 + 3 day: day];
            break;
        }

        case slice_month: {
            ShortDate *tdate = [ShortDate dateWithYear: year month: month day: 1];
            int       day = tdate.daysInMonth;
            date = [ShortDate dateWithYear: year month: month day: day];
            break;
        }

        case slice_none:
            date = toDate;
            break;

        case slice_all:
            date = [ShortDate dateWithDate: [NSDate distantFuture]];
            break;
    }

    if (maxDate) {
        if ([maxDate compare: date] == NSOrderedAscending) {
            return maxDate;
        } else {
            return date;
        }
    } else {
        return date;
    }
}

- (void)stepUp {
    switch (type) {
        case slice_year:
            year++;
            break;

        case slice_quarter: {
            quarter++;
            if (quarter > 3) {
                quarter = 0;
                year++;
            }
            unsigned l = quarter * 3 + 1;
            unsigned u = quarter * 3 + 3;
            if (month < l || month > u) {
                month = l;
            }
            break;
        }

        case slice_month: {
            month++;
            if (month > 12) {
                month = 1;
                year++;
            }
            quarter = (month - 1) / 3;
            break;
        }

        default:
            break;
    }

    if (maxDate) {
        if (year > maxDate.year) {
            year = maxDate.year;
        }
        if (year == maxDate.year && month > maxDate.month) {
            month = maxDate.month;
        }
        quarter = (month - 1) / 3;
    }
}

- (void)stepDown {
    switch (type) {
        case slice_year:
            year--;
            break;

        case slice_quarter: {
            if (quarter == 0) {
                quarter = 3;
                year--;
            } else quarter--;
            
            unsigned l = quarter * 3 + 1;
            unsigned u = quarter * 3 + 3;
            if (month < l || month > u) {
                month = l;
            }
            break;
        }

        case slice_month: {
            month--;
            if (month <= 0) {
                month = 12;
                year--;
            }
            quarter = (month - 1) / 3;
            break;
        }

        default:
            break;
    }

    if (minDate) {
        if (year < minDate.year) {
            year = minDate.year;
        }
        if (year == minDate.year && month < minDate.month) {
            month = minDate.month;
        }
        quarter = (month - 1) / 3;
    }
}

- (void)stepIn: (ShortDate *)date {
    BOOL stepped = NO;

    if (maxDate != nil && [date compare: maxDate] == NSOrderedDescending) {
        return;
    }

    while ([date compare: [self upperBounds]] == NSOrderedDescending) {
        [self stepUp];
        stepped = YES;
        if (maxDate != nil && [date compare: maxDate] == NSOrderedDescending) {
            break;
        }
    }

    if (stepped) {
        [self updateControl];
        [self updatePickers];
        [self updateDelegate];
        [self save];
    }
}

- (void)updateControl {
    if (type == slice_none) {
        // first deactivate timeSlicer
        int idx = (int)[control selectedSegment];
        if (idx >= 0) {
            [control setSelected: NO forSegment: idx];
        }
    }

    // year
    [control setLabel: [@((int)year)description] forSegment: slice_year];

    // quarter
    NSString *quarterString = [NSString stringWithFormat: @"Q%.1lu", (unsigned long)quarter + 1];
    [control setLabel: quarterString forSegment: slice_quarter];

    // month
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSArray         *months = [dateFormatter monthSymbols];
    [control setLabel: months[month - 1] forSegment: slice_month];
}

- (void)updatePickers {
    fromDate = [self lowerBounds];
    toDate = [self upperBounds];

    if (fromPicker != nil) {
        [fromPicker setDateValue: fromDate.lowDate];
    }

    if (toPicker != nil) {
        [toPicker setDateValue: toDate.highDate];
    }
}

- (void)updateDelegate {
    if ([delegate respondsToSelector: @selector(timeSliceManager:changedIntervalFrom:to:)]) {
        [delegate timeSliceManager: self changedIntervalFrom: [self lowerBounds] to: [self upperBounds]];
    }
}

- (void)setMinDate: (ShortDate *)date {
    minDate = date;
    if (fromPicker != nil) {
        [fromPicker setMinDate: date.lowDate];
    }
}

- (void)setMaxDate: (ShortDate *)date {
    maxDate = date;
    if (toPicker != nil) {
        [toPicker setMaxDate: date.highDate];
    }
}

- (IBAction)dateChanged: (id)sender {
    type = slice_none;
    if (sender == fromPicker) {
        fromDate = [ShortDate dateWithDate: [sender dateValue]];
    } else {
        toDate = [ShortDate dateWithDate: [sender dateValue]];
    }
    [self updateControl];
    [self updateDelegate];
    [self save];
}

- (IBAction)timeSliceChanged: (id)sender {
    SliceType t = (SliceType)[sender selectedSegment];
    switch (t) {
        case slice_year: break;

        case slice_month: break;

        case slice_quarter: {
            unsigned l = quarter * 3 + 1;
            unsigned u = quarter * 3 + 3;
            if (month < l || month > u) {
                month = l;
            }
            break;
        }

        default:
            break;
    }
    type = t;

    [self updatePickers];
    [self updateDelegate];
    [self save];
}

- (IBAction)timeSliceUpDown: (id)sender {
    if (type != slice_none && type != slice_all) {
        if ([sender selectedSegment] == 0) {
            [self stepDown];
        } else {
            [self stepUp];
        }

        [self updateControl];
        [self updatePickers];
        [self updateDelegate];
        [self save];
    }
}

- (NSPredicate *)predicateForField: (NSString *)field {
    NSPredicate *pred = [NSPredicate predicateWithFormat: @"(statement.%K => %@) AND (statement.%K <= %@)", field, [[self lowerBounds] lowDate], field, [[self upperBounds] highDate]];
    return pred;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ - %@", [self lowerBounds],  [self upperBounds]];
}

- (void)showControls: (BOOL)show {
    control.hidden = !show;
    upDown.hidden = !show;
}

- (void)setYearOnlyMode: (BOOL)flag {
    if (flag) {
        lastType = type;
        type = slice_year;
    } else {
        type = lastType;
    }
    [control setSelected: YES forSegment: type];

    [control setEnabled: !flag forSegment: slice_all];
    [control setEnabled: !flag forSegment: slice_quarter];
    [control setEnabled: !flag forSegment: slice_month];

    [self updatePickers];
    [self updateDelegate];
}

@end
