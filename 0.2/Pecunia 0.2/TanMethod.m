//
//  TanMethod.m
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "TanMethod.h"

@implementation TanMethod

-(id)initWithAB: (const AH_TAN_METHOD*)tm
{
	const char* c;
	
	self = [super init ];
	if(self == nil) return nil;
	
	function	= AH_TanMethod_GetFunction(tm);
	description	= [[NSString stringWithUTF8String: (c = AH_TanMethod_GetMethodName(tm)) ? c: ""] retain];
	
	return self;
}

-(id)initDefault: (int) func
{
	self = [super init ];
	if(self == nil) return nil;
	function = func;
	description = NSLocalizedString(@"AP83", @"");
	return self;
}


- (int)function {
    return function;
}

- (NSString *)description {
    return [[description retain] autorelease];
}

-(void)dealloc
{
	[description release ];

	[super dealloc ];
}


@end
