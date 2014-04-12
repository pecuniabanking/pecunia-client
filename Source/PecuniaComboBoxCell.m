//
//  PecuniaComboBoxCell.m
//  Pecunia
//
//  Created by Frank Emminghaus on 12.04.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

#import "PecuniaComboBoxCell.h"

@implementation PecuniaComboBoxCell

- (NSString *)completedString:(NSString *)string
{
    NSString *result = nil;
    
    if (string == nil)
        return result;
    
    for (NSString *item in self.objectValues) { 
        NSString *truncatedString = [item substringToIndex:MIN(item.length, string.length)];
        if ([truncatedString caseInsensitiveCompare:string] == NSOrderedSame) {
            result = item;
            break;
        }
    }
    
    return result;
}

@end
