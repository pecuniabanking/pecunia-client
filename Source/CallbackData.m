//
//  CallbackData.m
//  Pecunia
//
//  Created by Frank Emminghaus on 26.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CallbackData.h"


@implementation CallbackData

@synthesize bankCode;
@synthesize message;
@synthesize proposal;
@synthesize command;
@synthesize userId;



- (void)setReason: (NSString *)res
{
    reason = [res intValue];
}

- (void)setType: (NSString *)t
{
    type = [t intValue];
}

@end
