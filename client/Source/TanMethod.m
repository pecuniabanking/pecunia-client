//
//  TanMethod.m
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "TanMethod.h"

@implementation TanMethod

@synthesize identifier;
@synthesize process;
@synthesize zkaMethodName;
@synthesize zkaMethodVersion;
@synthesize name;
@synthesize inputInfo;
@synthesize maxTanLength;
@synthesize needTanMedia;
@synthesize function;
@synthesize description;

-(id)initDefault: (NSNumber*) func
{
	self = [super init ];
	if(self == nil) return nil;
	self.function = func;
	self.description = NSLocalizedString(@"AP83", @"");
	return self;
}

-(void)dealloc
{
	[description release ];
	[function release ];
	[identifier release], identifier = nil;
	[process release], process = nil;
	[zkaMethodName release], zkaMethodName = nil;
	[zkaMethodVersion release], zkaMethodVersion = nil;
	[name release], name = nil;
	[inputInfo release], inputInfo = nil;
	[maxTanLength release], maxTanLength = nil;
	[needTanMedia release], needTanMedia = nil;

	[super dealloc ];
}


@end

