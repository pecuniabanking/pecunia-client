//
//  BankInfo.m
//  Pecunia
//
//  Created by Frank Emminghaus on 26.01.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "BankInfo.h"


@implementation BankInfo

@synthesize country;
@synthesize branch;
@synthesize bankCode;
@synthesize bic;
@synthesize name;
@synthesize location;
@synthesize street;
@synthesize city;
@synthesize region;
@synthesize phone;
@synthesize email;
@synthesize host;
@synthesize pinTanURL;
@synthesize pinTanVersion;
@synthesize website;

-(void)dealloc
{
	[country release ];
	[branch release ];
	[bankCode release ];
	[bic release ];
	[name release ];
	[location release ];
	[street release ];
	[city release ];
	[region release ];
	[phone release ];
	[email release ];
	[host release ];
	[pinTanURL release ];
	[pinTanVersion release ];

	[super dealloc ];
}

@end
