/**
 * Copyright (c) 2011, 2016, Pecunia Project. All rights reserved.
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

#import "ValueTransformers.h"

#import "NSString+PecuniaAdditions.h"
#import "NSColor+PecuniaAdditions.h"

@implementation CurrencyValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

// Shared instance.
static NSNumberFormatter   *formatter;
static NSMutableDictionary *cache;

- (id)transformedValue: (id)value
{
    if (value == nil) {
        return nil;
    }

    if (formatter == nil) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];

        cache = [[NSMutableDictionary alloc] init];
    }

    id result = [cache valueForKey: value];
    if (result == nil) {
        [formatter setFormat: @"0.00¤"];
        [formatter setCurrencyCode: value];
        NSString *symbol = [formatter stringFromNumber: @0];

        result = [symbol substringFromIndex: [symbol length] - 1];
        [cache setValue: result forKey: value];
    }

    return result;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation MoreThanOneToBoolValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if ([value count] > 1) {
        return @YES;
    }
    return @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation OneOrLessToBoolValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if ([value count] <= 1) {
        return @YES;
    }
    return @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation ExactlyOneToBoolValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if ([value respondsToSelector: @selector(count)] && [value count] == 1) {
        return @YES;
    }
    return @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation ZeroCountToBoolValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if ([value count] == 0) {
        return @YES;
    }
    return @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation NonZeroCountToBoolValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if ([value count] > 0) {
        return @YES;
    }
    return @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation RemoveWhitespaceTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)reverseTransformedValue: (id)value
{
    if (value == nil) {
        return nil;
    }
    NSString *result = @"";
    NSArray  *components = [value componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *s in components) {
        result = [result stringByAppendingString: s];
    }
    return result;
}

- (id)transformedValue: (id)value
{
    return value;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation StringCasingTransformer

+ (void)initialize
{
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if (![NSUserDefaults.standardUserDefaults boolForKey: @"autoCasing"]) {
        return value;
    }

    return [value stringWithNaturalText];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation PercentTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue: (id)value
{
    return [NSNumber numberWithDouble: 100 * [value doubleValue]];
}

- (id)reverseTransformedValue: (id)value
{
    return [NSNumber numberWithDouble: [value doubleValue] / 100];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation ObjectToStringTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    return [value description];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation ZeroValueToBoolTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    return ([value integerValue] == 0) ? @YES : @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation ValueToColorTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    return ([value doubleValue] < 0) ? [NSColor applicationColorForKey: @"Negative Cash"] : [NSColor applicationColorForKey: @"Positive Cash"];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation DayFromDateTransformer

static NSDateFormatter *dateToDayFormatter = nil;

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if (dateToDayFormatter == nil) {
        dateToDayFormatter = [NSDateFormatter new];
        dateToDayFormatter.locale = NSLocale.currentLocale;
        dateToDayFormatter.dateStyle = kCFDateFormatterFullStyle;
        dateToDayFormatter.timeStyle = NSDateFormatterNoStyle;
        dateToDayFormatter.dateFormat = @"d";
    }
    return [dateToDayFormatter stringFromDate: value];
}

@end

//----------------------------------------------------------------------------------------------------------------------

@implementation MonthFromDateTransformer

static NSDateFormatter *monthToDayFormatter = nil;

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue: (id)value
{
    if (monthToDayFormatter == nil) {
        monthToDayFormatter = [NSDateFormatter new];
        monthToDayFormatter.locale = NSLocale.currentLocale;
        monthToDayFormatter.dateStyle = kCFDateFormatterFullStyle;
        monthToDayFormatter.timeStyle = NSDateFormatterNoStyle;
        monthToDayFormatter.dateFormat = @"MMM";
    }
    return [monthToDayFormatter stringFromDate: value];
}

@end

//----------------------------------------------------------------------------------------------------------------------
