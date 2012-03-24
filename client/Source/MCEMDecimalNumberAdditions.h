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

#import <Cocoa/Cocoa.h>

@interface NSDecimalNumber (PecuniaAdditions)

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

/** Standard rounding with scale 2 */
- (NSDecimalNumber*)rounded;

@end
