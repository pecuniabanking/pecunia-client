//
//  BankSetupInfo.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "BankSetupInfo.h"


@implementation BankSetupInfo

@synthesize info_userid;
@synthesize info_customerid;
@synthesize pinlen_min;
@synthesize pinlen_max;
@synthesize tanlen_max;

- (void)dealloc
{
	[info_userid release], info_userid = nil;
	[info_customerid release], info_customerid = nil;
	[pinlen_min release], pinlen_min = nil;
	[pinlen_max release], pinlen_max = nil;
	[tanlen_max release], tanlen_max = nil;

	[super dealloc];
}

@end

