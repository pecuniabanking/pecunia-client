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

#import "MCEMDecimalNumberAdditions.h"

static NSDecimalNumberHandler *numberHandler = nil;


@implementation NSDecimalNumber (PecuniaAdditions)

- (NSDecimalNumber*)abs
{
    NSDecimal value = [self decimalValue];
    value._isNegative = 0;
    return [NSDecimalNumber decimalNumberWithDecimal: value];
}

- (int)numberOfDigits
{
    NSDecimal zero = [@0 decimalValue];
    
    NSDecimal value = [self decimalValue];
    value._isNegative = 0;
    if (NSDecimalCompare(&value, &zero) == NSOrderedAscending) {
        return 1;
    }
    
    int result = 0;
    NSDecimal one = [@1 decimalValue];
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
    NSDecimal ten = [@10 decimalValue];
    NSDecimal five = [@5 decimalValue];
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
            NSDecimal offset = [@1 decimalValue];
            NSDecimalMultiplyByPowerOf10(&offset, &offset, digits - 1, NSRoundDown);
            NSDecimalAdd(&value, &value, &offset, NSRoundDown);
        } else {
            // The second MSD is < 5, so we round it up to 5 and add this to the overall value.
            NSDecimal offset = [@5 decimalValue];
            NSDecimalMultiplyByPowerOf10(&offset, &offset, digits - 2, NSRoundDown);
            NSDecimalAdd(&value, &value, &offset, NSRoundDown);
        }
    }
    
    value._isNegative = isNegative ? 1 : 0;
    
    return [NSDecimalNumber decimalNumberWithDecimal: value];
}

-(NSDecimalNumber*)rounded
{
	if (numberHandler == nil) {
		numberHandler = [[NSDecimalNumberHandler alloc] initWithRoundingMode: NSRoundPlain 
                                                                       scale: 2
                                                            raiseOnExactness: YES 
                                                             raiseOnOverflow: YES 
                                                            raiseOnUnderflow: YES 
                                                         raiseOnDivideByZero: YES];
	}
	
	return [self decimalNumberByRoundingAccordingToBehavior: numberHandler];	
}

@end
