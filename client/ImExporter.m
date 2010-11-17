//
//  ImExporter.m
//  Pecunia
//
//  Created by Frank Emminghaus on 17.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ImExporter.h"


@implementation ImExporter

@synthesize profiles;
@synthesize name;
@synthesize description;
@synthesize longDescription;

- (void)dealloc
{
	[name release], name = nil;
	[description release], description = nil;
	[longDescription release], longDescription = nil;
	[profiles release], profiles = nil;

	[super dealloc];
}

@end


