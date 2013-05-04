/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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
    if ([value count] == 1) {
        return @YES;
    }
    return @NO;
}

@end

//----------------------------------------------------------------------------------------------------------------------
