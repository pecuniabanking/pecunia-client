//
//  CategoryReportingNode.m
//  Pecunia
//
//  Created by Frank Emminghaus on 09.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "CategoryReportingNode.h"


@implementation CategoryReportingNode

@synthesize name;
@synthesize children;
@synthesize values;
@synthesize periodValues;

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;
	self.children = [NSMutableSet setWithCapacity:5 ];
	self.values = [NSMutableDictionary dictionaryWithCapacity:20 ];
	self.periodValues = [NSMutableDictionary dictionaryWithCapacity:20 ];
	return self;
}

- (void)dealloc
{
	[name release], name = nil;
	[children release], children = nil;
	[values release], values = nil;
	[periodValues release ], periodValues = nil;
	[super dealloc];
}

@end

