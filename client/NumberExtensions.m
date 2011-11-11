//
//  NumberExtensions.m
//  Pecunia
//
//  Created by Mike Lischke on 29.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "NumberExtensions.h"


@implementation NSDecimalNumber(PecuniaAdditions)

static NSDecimalNumber* ten;
static NSDecimalNumber* negativeOne;

- (NSDecimalNumber*)abs
{
    if (negativeOne == nil)
        negativeOne = [[NSDecimalNumber decimalNumberWithString: @"-1"] retain];
    
    if ([self compare:[NSDecimalNumber zero]] == NSOrderedAscending)
    {
        return [self decimalNumberByMultiplyingBy: negativeOne];
    }
    else
    {
        return self;
    }
}

-(NSDecimalNumber*)roundToUpperOuter
{
    if (ten == nil)
        ten = [[NSDecimalNumber decimalNumberWithString: @"10"] retain];
    
    short scale = 0;
    NSComparisonResult comparisonResult = [self compare: [NSDecimalNumber zero]];
    if (comparisonResult != NSOrderedSame)
    {
        NSDecimalNumber* current = [self abs];
        while ([current compare: [NSDecimalNumber one]] != NSOrderedDescending)
        {
            scale++;
            current = [current decimalNumberByMultiplyingBy: ten];
        }
        while ([current compare: ten] == NSOrderedDescending)
        {
            scale--;
            current = [current decimalNumberByDividingBy: ten];
        }
    }
    NSDecimalNumberHandler* roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundBankers
                                                                                                      scale: scale
                                                                                           raiseOnExactness: NO
                                                                                            raiseOnOverflow: NO
                                                                                           raiseOnUnderflow: NO
                                                                                        raiseOnDivideByZero: NO];
    return [self decimalNumberByRoundingAccordingToBehavior: roundingBehavior];
}

@end
