//
//  BankParameter.m
//  Pecunia
//
//  Created by Frank Emminghaus on 20.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "BankParameter.h"


@implementation BankParameter

@synthesize bpd_raw;
@synthesize upd_raw;
@synthesize bpd;
@synthesize upd;

- (void)dealloc
{
	[bpd release], bpd = nil;
	[upd release], upd = nil;
	[bpd_raw release], bpd_raw = nil;
	[upd_raw release], upd_raw = nil;

	[super dealloc];
}

@end


