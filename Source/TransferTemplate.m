//
//  TransferTemplate.m
//  Pecunia
//
//  Created by Frank Emminghaus on 26.09.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "TransferTemplate.h"

@implementation TransferTemplate
@dynamic currency;
@dynamic name;
@dynamic purpose1;
@dynamic purpose2;
@dynamic purpose3;
@dynamic purpose4;
@dynamic remoteAccount;
@dynamic remoteBankCode;
@dynamic remoteBIC;
@dynamic remoteCountry;
@dynamic remoteIBAN;
@dynamic remoteName;
@dynamic remoteSuffix;
@dynamic value;
@dynamic type;

- (NSString *)purpose
{
    NSMutableString *s = [NSMutableString stringWithCapacity: 100];
    if (self.purpose1) {
        [s appendString: self.purpose1];
    }
    if (self.purpose2) {
        [s appendString: @" "]; [s appendString: self.purpose2];
    }
    if (self.purpose3) {
        [s appendString: @" "]; [s appendString: self.purpose3];
    }
    if (self.purpose4) {
        [s appendString: @" "]; [s appendString: self.purpose4];
    }

    return s;
}

@end
