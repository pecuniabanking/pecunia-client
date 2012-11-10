//
//  RemoveWhitespaceTransformer.m
//  Pecunia
//
//  Created by Frank Emminghaus on 07.11.12.
//  Copyright (c) 2012 Frank Emminghaus. All rights reserved.
//

#import "RemoveWhitespaceTransformer.h"

@implementation RemoveWhitespaceTransformer

+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return YES; }

- (id)reverseTransformedValue:(id)value
{
    if (value == nil) {
        return nil;
    }
    NSString *result = @"";
    NSArray *components = [value componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *s in components) {
        result = [result stringByAppendingString:s];
    }
    return result;
}

- (id)transformedValue:(id)value
{
    return value;
}

@end
