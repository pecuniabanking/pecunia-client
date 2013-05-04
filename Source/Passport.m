//
//  Passport.m
//  Client
//
//  Created by Frank Emminghaus on 10.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Passport.h"

@implementation Passport

@synthesize name;
@synthesize bankCode;
@synthesize bankName;
@synthesize userId;
@synthesize customerId;
@synthesize host;
//@synthesize filter;
@synthesize version;
@synthesize tanMethod;
@synthesize port;
@synthesize tanMethods;
@synthesize base64;
@synthesize checkCert;


- (BOOL)isEqual: (id)obj
{
    if ([bankCode isEqual: ((Passport *)obj)->bankCode] && [userId isEqual: ((Passport *)obj)->userId]) {
        return YES;
    } else {return NO; }
}

- (void)setFilter: (NSString *)filter
{
    if ([filter isEqualToString: @"Base64"]) {
        base64 = YES;
    } else {base64 = NO; }
}

@end
