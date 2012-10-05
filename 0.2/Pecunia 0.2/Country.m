//
//  Country.m
//  Pecunia
//
//  Created by Frank Emminghaus on 15.11.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "Country.h"


@implementation Country

-(id)initWithAB: (const AB_COUNTRY*)cnty
{
	const char	*c;
	
	[super init ];
	name =		[[NSString stringWithUTF8String: (c = AB_Country_GetLocalName(cnty)) ? c: ""] retain];
	code =		[[NSString stringWithUTF8String: (c = AB_Country_GetCode(cnty)) ? c: ""] retain];
	currency =	[[NSString stringWithUTF8String: (c = AB_Country_GetCurrencyCode(cnty)) ? c: ""] retain];
	return self;
}

-(NSString*)name { return name; }
-(NSString*)currency { return currency; }
-(NSString*)code { return code; }

-(void)dealloc
{
	[name release ];
	[currency release ];
	[code release ];

	[super dealloc ];
}

@end
