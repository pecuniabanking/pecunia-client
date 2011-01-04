//
//  PurposeSplitData.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "PurposeSplitData.h"


@implementation PurposeSplitData

@synthesize statement;
@synthesize purposeNew;
@synthesize purposeOld;
@synthesize remoteName;
@synthesize remoteAccount;
@synthesize remoteBankCode;

- (void)dealloc
{
	[remoteName release], remoteName = nil;
	[remoteAccount release], remoteAccount = nil;
	[remoteBankCode release], remoteBankCode = nil;
	[purposeNew release], purposeNew = nil;
	[purposeOld release], purposeOld = nil;
	statement = nil;
	[super dealloc];
}

@end

