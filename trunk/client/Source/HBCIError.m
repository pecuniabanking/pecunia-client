//
//  HBCIError.m
//  Client
//
//  Created by Frank Emminghaus on 23.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "HBCIError.h"
#import "PecuniaError.h"

@implementation HBCIError

@synthesize msg;
@synthesize code;

-(void)dealloc
{
	[msg release ];
	[code release ];
	[super dealloc ];
}

-(PecuniaError*)toPecuniaError
{
	return [PecuniaError errorWithCode: [self.code intValue ] message: msg ];
}

@end
