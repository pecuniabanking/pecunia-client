//
//  NSNumberFormatter+Additions.m
//  Pecunia
//
//  Created by Mike Lischke on 24.10.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "CurrencyValueTransformer.h"


@implementation CurrencyValueTransformer

+ (BOOL)allowsReverseTransformation
{
  return NO;
}

// Shared instance.
static NSNumberFormatter* formatter;
static NSMutableDictionary* cache;

- (id)transformedValue: (id)value
{
  if (value == nil)
    return nil;
  
  if (formatter == nil)
  {
    formatter = [[[NSNumberFormatter alloc] init] retain];
    [formatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    
    cache = [[[NSMutableDictionary alloc] init] retain];
  }
  
  id result = [cache valueForKey: value];
  if (result == nil)
  {
    [formatter setFormat: @"0.00¤"];
    [formatter setCurrencyCode: value];
    NSString* symbol = [formatter stringFromNumber: [NSNumber numberWithInt: 0]];
    
    result = [symbol substringFromIndex: [symbol length] - 1];
    [cache setValue: result forKey: value];
  }
  
  return result;
}

@end
