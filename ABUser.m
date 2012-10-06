//
//  ABUser.m
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#ifdef AQBANKING
#import "ABUser.h"
#import "TanMethod.h"
#import "HBCIClient.h"

@implementation ABUser

@synthesize uid;
@synthesize tanMethodList;
@synthesize forceSSL3;
@synthesize noBase64;
@synthesize hbciVersion;
@synthesize tanMethodNumber;
@synthesize name;
@synthesize country;
@synthesize bankCode;
@synthesize userId;
@synthesize customerId;
@synthesize mediumId;
@synthesize bankURL;
@synthesize bankName;

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;
	return self;
}


-(BOOL)isEqual: (ABUser*)obj
{
	return (uid == obj->uid);
}

-(TanMethod*)tanMethod
{ 
	TanMethod *method;
	for(method in tanMethodList) {
		if(method.function == tanMethodNumber) return method;
	}
	return [tanMethodList objectAtIndex:0 ];
}

-(void)setTanMethod: (TanMethod*)tm
{
	tanMethodNumber = tm.function;
	[[HBCIClient hbciClient ] changePinTanMethodForUser:self method:tanMethodNumber ];
}


-(void)dealloc
{
	[tanMethodList release ];
	[name release], name = nil;
	[country release], country = nil;
	[bankCode release], bankCode = nil;
	[userId release], userId = nil;
	[customerId release], customerId = nil;
	[mediumId release], mediumId = nil;
	[bankURL release], bankURL = nil;
	[bankName release], bankName = nil;
	[tanMethodList release], tanMethodList = nil;
	[super dealloc ];
}

@end

#endif

