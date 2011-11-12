//
//  MCEMDecimalNumberAdditions.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.07.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "MCEMDecimalNumberAdditions.h"

static NSDecimalNumberHandler *numberHandler = nil;


@implementation NSDecimalNumber (MCEMDecimalNumberAdditions)

-(NSDecimalNumber*)abs {
    if ([self compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
        // Number is negative. Multiply by -1
        NSDecimalNumber *negativeOne = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:YES];
        return [self decimalNumberByMultiplyingBy:negativeOne];
    } else {
        return self;
    }
}

-(NSDecimalNumber*)rounded
{
	if (numberHandler == nil) {
		numberHandler = [[NSDecimalNumberHandler alloc ] initWithRoundingMode:NSRoundPlain 
																		scale:2
															 raiseOnExactness:YES 
															  raiseOnOverflow:YES 
															 raiseOnUnderflow:YES 
														  raiseOnDivideByZero:YES ];
	}
	
	return [self decimalNumberByRoundingAccordingToBehavior:numberHandler ];	
}

@end
