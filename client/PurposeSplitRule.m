//
//  PurposeSplitRule.m
//  Pecunia
//
//  Created by Frank Emminghaus on 09.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PurposeSplitRule.h"
#import "BankStatement.h"

@implementation PurposeSplitRule

-(id)initWithString:(NSString*)rule
{
	self = [super init ];
	if (self == nil) return nil;
	
	NSArray *tokens = [rule componentsSeparatedByString:@":" ];
	if ([tokens count ] != 2) return nil;
	
	// first part is version info, skip
	NSString *s = [tokens objectAtIndex:1 ];
	tokens = [s componentsSeparatedByString:@"," ];
	if ([tokens count ] != 7) return nil;
	ePos = [[tokens objectAtIndex:0 ] intValue ];
	eLen = [[tokens objectAtIndex:1 ] intValue ];
	kPos = [[tokens objectAtIndex:2 ] intValue ];
	kLen = [[tokens objectAtIndex:3 ] intValue ];
	bPos = [[tokens objectAtIndex:4 ] intValue ];
	bLen = [[tokens objectAtIndex:5 ] intValue ];
	vPos = [[tokens objectAtIndex:6 ] intValue ];
	return self;
}

-(void)applyToStatement:(BankStatement*)stat
{
	NSRange eRange;
	NSRange kRange;
	NSRange bRange;
	
	eRange.location = ePos;
	eRange.length = eLen;
	kRange.location = kPos;
	kRange.length = kLen;
	bRange.location = bPos;
	bRange.length = bLen;
	
	stat.additional = stat.purpose;
	if (eRange.length) {
		stat.remoteName = [[stat.purpose substringWithRange:eRange ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
	}
	if (kRange.length) {
		stat.remoteAccount = [[stat.purpose substringWithRange:kRange ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
	}
	if (bRange.length) {
		stat.remoteBankCode = [[stat.purpose substringWithRange:bRange ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
	}
	if(vPos) stat.purpose = [[stat.purpose substringFromIndex:vPos ] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet ]];
}

@end
