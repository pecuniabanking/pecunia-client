//
//  TanMethodOld.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "TanMethodOld.h"


@implementation TanMethodOld

@synthesize function;
@synthesize description;

- (void)dealloc
{
	[function release], function = nil;
	[description release], description = nil;

	[super dealloc];
}

-(id)initDefault: (NSNumber*) func
{
	self = [super init ];
	if(self == nil) return nil;
	self.function = func;
	self.description = NSLocalizedString(@"AP83", @"");
	return self;
}




@end

