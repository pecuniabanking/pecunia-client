//
//  NumberExtensions.m
//  Pecunia
//
//  Created by Mike Lischke on 29.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "NumberExtensions.h"


@implementation NSDecimalNumber(PecuniaAdditions)

- (NSDecimalNumber*)abs
{
    NSDecimal value = [self decimalValue];
    value._isNegative = 0;
    return [NSDecimalNumber decimalNumberWithDecimal: value];
}

- (int)numberOfDigits
{
    NSDecimal zero = [[NSNumber numberWithInt: 0] decimalValue];

    NSDecimal value = [self decimalValue];
    value._isNegative = 0;
    if (NSDecimalCompare(&value, &zero) == NSOrderedAscending) {
        return 1;
    }
    
    int result = 0;
    NSDecimal one = [[NSNumber numberWithInt: 1] decimalValue];
    while (NSDecimalCompare(&value, &one) != NSOrderedAscending)
    {
        result++;
        NSDecimalMultiplyByPowerOf10(&value, &value, -1, NSRoundDown);
}

    return result;
}

- (NSDecimalNumber*)roundToUpperOuter
{
    int digits = [self numberOfDigits];
    
    NSDecimal value = [self decimalValue];
    bool isNegative = value._isNegative != 0;
    value._isNegative = 0;

    NSDecimal second = value;
    
    // First determine the most significant digit. That forms our base. But only if the overall
    // value is >= 10.
    NSDecimal ten = [[NSNumber numberWithInt: 10] decimalValue];
    NSDecimal five = [[NSNumber numberWithInt: 5] decimalValue];
    if (NSDecimalCompare(&second, &ten) == NSOrderedAscending) {
        NSDecimalRound(&value, &value, 1, NSRoundUp);
    } else {
        NSDecimalRound(&value, &value, -digits + 1, NSRoundDown);

        // Get the second MSD as this is used to determine where we round to.
        // If the MSD is however 5 or more then we just round that up.
        NSDecimalSubtract(&second, &second, &value, NSRoundDown);
        NSDecimalMultiplyByPowerOf10(&second, &second, -digits + 2, NSRoundDown);
    
        NSDecimal first;
        NSDecimalMultiplyByPowerOf10(&first, &value, -digits + 1, NSRoundDown);
        BOOL msdIs5Orlarger = NSDecimalCompare(&first, &five) != NSOrderedAscending;

        // See if the second MSD is below or above 5. In the latter case increase the MSD by one
        // and return this as the rounded value.
        if (msdIs5Orlarger || NSDecimalCompare(&second, &five) == NSOrderedDescending) {
            NSDecimal offset = [[NSNumber numberWithInt: 1] decimalValue];
            NSDecimalMultiplyByPowerOf10(&offset, &offset, digits - 1, NSRoundDown);
            NSDecimalAdd(&value, &value, &offset, NSRoundDown);
        } else {
            // The second MSD is < 5, so we round it up to 5 and add this to the overall value.
            NSDecimal offset = [[NSNumber numberWithInt: 5] decimalValue];
            NSDecimalMultiplyByPowerOf10(&offset, &offset, digits - 2, NSRoundDown);
            NSDecimalAdd(&value, &value, &offset, NSRoundDown);
        }
    }
    
    value._isNegative = isNegative ? 1 : 0;
    
    return [NSDecimalNumber decimalNumberWithDecimal: value];
}

@end
