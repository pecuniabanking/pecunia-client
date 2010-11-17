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

-(void)dealloc
{
	[description release ];
	[super dealloc ];
}


@end
