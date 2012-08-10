//
//  User.m
//  MacBanking
//
//  Created by Frank Emminghaus on 17.03.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "User.h"
#import "TanMethodOld.h"
#import "HBCIClient.h"

@implementation User

@synthesize tanMethodList;
@synthesize forceSSL3;
@synthesize noBase64;
@synthesize hbciVersion;
@synthesize tanMethodNumber;
@synthesize tanMethodDescription;
@synthesize name;
@synthesize country;
@synthesize bankCode;
@synthesize userId;
@synthesize customerId;
@synthesize mediumId;
@synthesize bankURL;
@synthesize bankName;
@synthesize checkCert;
@synthesize port;
@synthesize chipCardId;

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;
	return self;
}


-(BOOL)isEqual: (User*)obj
{
	return ([self.userId isEqualToString: obj->userId ] && 
			[self.bankCode isEqualToString:obj->bankCode ] &&
			[self.customerId isEqualToString: obj->customerId ] );
}

-(TanMethodOld*)tanMethod
{ 
	TanMethodOld *method;
	for(method in tanMethodList) {
		if([method.function intValue ] == [tanMethodNumber intValue ]) return method;
	}
	return [tanMethodList objectAtIndex:0 ];
}

-(void)setTanMethod: (TanMethodOld*)tm
{
	self.tanMethodNumber = tm.function;
//todo	[[HBCIClient hbciClient ] changePinTanMethodForUser:self method:tanMethodNumber ];
}


-(void)dealloc
{
	[tanMethodList release ];
	[tanMethodDescription release ];
	[name release], name = nil;
	[country release], country = nil;
	[bankCode release], bankCode = nil;
	[userId release], userId = nil;
	[customerId release], customerId = nil;
	[mediumId release], mediumId = nil;
	[bankURL release], bankURL = nil;
	[bankName release], bankName = nil;
	[tanMethodList release], tanMethodList = nil;
	[tanMethodNumber release ], tanMethodNumber = nil;
	[hbciVersion release ], hbciVersion = nil;
	[port release ], port = nil;
    [chipCardId release ], chipCardId = nil;
	[super dealloc ];
}

@end

