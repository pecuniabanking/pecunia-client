//
//  IBANFormatter.m
//  Pecunia
//
//  Created by Frank Emminghaus on 13.03.24.
//  Copyright © 2024 Frank Emminghaus. All rights reserved.
//

#import "IBANFormatter.h"

@implementation IBANFormatter

+ (NSString *)formatIBAN:(NSString *)s
{
    NSString *result = @"";
    
    s = [s uppercaseString];
    
    // format the IBAN into groups of 4 digits
    s = [s stringByRemovingWhitespaces:s ];
    
    int n = (int)[s length];
    int count = 0;
    while (count < n) {
        if ([s length] < 4) {
            result = [result stringByAppendingString:s];
        } else {
            NSString *x = [s substringToIndex:4];
            s = [s substringFromIndex:4];
            if ([s length] > 0) {
                result = [result stringByAppendingFormat:@"%@ ", x];
            } else {
                result = [result stringByAppendingString:x];
            }
        }
        count += 4;
    }
    return result;
}

- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *s = (NSString*)anObject;
    return [IBANFormatter formatIBAN:s];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    *obj = [string stringByRemovingWhitespaces:string];
    return true;
}





@end
