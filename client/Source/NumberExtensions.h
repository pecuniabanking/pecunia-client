//
//  NumberExtensions.h
//  Pecunia
//
//  Created by Mike Lischke on 29.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDecimalNumber(PecuniaAdditions)

/**
 * Returns the number digits of this number (interpreting it in a 10-based system),
 * not counting any fractional parts.
 */
- (int)numberOfDigits;

/**
 * Returns a value whose sign is the same as that of the receiver and whose absolute value is equal
 * or larger such that only the most significant digit is not zero. If the receivers MSD and the second MSD
 * are smaller than 5 then the result is rounded towards a 5 as the second MSD instead of increasing
 * the MSD.
 * Examples: 12 => 15, 17 => 20, 45 => 50, 61 => 70, 123456 => 150000, -77000 => -80000.
 */
-(NSDecimalNumber*)roundToUpperOuter;

/**
 * Returns the receiver value without a sign (i.e. as a positive value).
 */
- (NSDecimalNumber*)abs;

@end
