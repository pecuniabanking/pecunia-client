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

/*
-(id)initWithAB: (AB_BANKINFO*)bi
{
	const char* c;
	
	self = [super init ];
	if(self == nil) return nil;

	name		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetBankName(bi)) ? c: ""] retain];
	country		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetCountry(bi)) ? c: ""] retain];
	branch		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetBranchId(bi)) ? c: ""] retain];
	bankCode	= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetBankId(bi)) ? c: ""] retain];
	bic			= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetBic(bi)) ? c: ""] retain];
	location	= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetLocation(bi)) ? c: ""] retain];
	street		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetStreet(bi)) ? c: ""] retain];
	city		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetCity(bi)) ? c: ""] retain];
	region		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetRegion(bi)) ? c: ""] retain];
	phone		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetPhone(bi)) ? c: ""] retain];
	email		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetEmail(bi)) ? c: ""] retain];
	website		= [[NSString stringWithUTF8String: (c = AB_BankInfo_GetWebsite(bi)) ? c: ""] retain];
 
	return self;
}
*/

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
