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
	info_userid = nil;
	info_customerid = nil;
	pinlen_min = nil;
	pinlen_max = nil;
	tanlen_max = nil;

}

@end

