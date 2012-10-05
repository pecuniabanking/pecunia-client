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
 * Rounds the receiver such that for positive values the result is the smallest value that
 * is greater than the receiver and has only zero digits except for the highest digit.
 * For negative values the result is similar but is the largest value that is smaller than the receiver.
 * Example: 12345.67 => 20000, -98 => -100, 0.00394 => 0.004
 */
-(NSDecimalNumber*)roundToUpperOuter;

/**
 * Returns the receiver value without a sign (i.e. as a positive value).
 */
- (NSDecimalNumber*)abs;

@end
