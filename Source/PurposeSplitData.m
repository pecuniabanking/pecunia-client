//
//  PurposeSplitData.m
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "PurposeSplitData.h"


@implementation PurposeSplitData

@synthesize converted;
@synthesize statement;
@synthesize purposeNew;
@synthesize purposeOld;
@synthesize remoteName;
@synthesize remoteAccount;
@synthesize remoteBankCode;

- (void)dealloc
{
    remoteName = nil;
    remoteAccount = nil;
    remoteBankCode = nil;
    purposeNew = nil;
    purposeOld = nil;
    statement = nil;

}

@end
