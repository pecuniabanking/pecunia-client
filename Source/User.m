/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

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
@synthesize accounts;

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
    [accounts release ], accounts = nil;
	[super dealloc ];
}

@end

