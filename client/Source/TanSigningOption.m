//
//  TanSigningOptions.m
//  Pecunia
//
//  Created by Frank Emminghaus on 07.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "TanSigningOption.h"


@implementation TanSigningOption

@synthesize tanMethod;
@synthesize tanMethodName;
@synthesize tanMediumName;
@synthesize mobileNumber;

- (void)dealloc
{
	[tanMethod release], tanMethod = nil;
	[tanMethodName release], tanMethodName = nil;
	[tanMediumName release], tanMediumName = nil;
	[mobileNumber release], mobileNumber = nil;

	[super dealloc];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ (%@)", tanMethodName, tanMediumName ];
}

@end

