//
//  TanMethod.m
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "TanMethod.h"

@implementation TanMethod

@synthesize function;
@synthesize description;

-(id)initDefault: (int) func
{
	self = [super init ];
	if(self == nil) return nil;
	function = func;
	description = NSLocalizedString(@"AP83", @"");
	return self;
}

-(void)dealloc
{
	[description release ];
	[super dealloc ];
}


@end
