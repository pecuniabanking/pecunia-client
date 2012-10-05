//
//  Transfer.m
//  MacBanking
//
//  Created by Frank Emminghaus on 21.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "Transfer.h"
#import "TransactionLimits.h"

@implementation Transfer

-(NSString*)purpose
{
	NSMutableString* s = [NSMutableString stringWithCapacity: 100 ];
	if([self valueForKey: @"purpose1" ]) { [s appendString: [self valueForKey: @"purpose1" ] ]; }
	if([self valueForKey: @"purpose2" ]) { [s appendString: @" " ]; [s appendString: [self valueForKey: @"purpose2" ] ]; }
	if([self valueForKey: @"purpose3" ]) { [s appendString: @" " ]; [s appendString: [self valueForKey: @"purpose3" ] ]; }
	if([self valueForKey: @"purpose4" ]) { [s appendString: @" " ]; [s appendString: [self valueForKey: @"purpose4" ] ]; }
	
	return s;
}

-(void)copyFromTemplate: (Transfer*)t withLimits:(TransactionLimits*)limits
{
    NSString *s;
	int maxLen = [limits maxLenRemoteName ] * [limits maxLinesRemoteName ];
	s = [t valueForKey: @"remoteName" ];
	if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
	[self setValue: s forKey: @"remoteName" ];

	maxLen = [limits maxLenPurpose ];
	int num = [limits maxLinesPurpose ];
	
	s = [t valueForKey: @"purpose1" ];
	if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
	[self setValue: s forKey: @"purpose1" ];
	
	if (num > 1) {
		s = [t valueForKey: @"purpose2" ];
		if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
		[self setValue: s forKey: @"purpose2" ];
	}

	if (num > 2) {
		s = [t valueForKey: @"purpose3" ];
		if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
		[self setValue: s forKey: @"purpose3" ];
	}
	
	if (num > 3) {
		s = [t valueForKey: @"purpose4" ];
		if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
		[self setValue: s forKey: @"purpose4" ];
	}
	
	[self setValue: [[t valueForKey: @"remoteName" ] copy ] forKey: @"remoteName" ];
	[self setValue: [[t valueForKey: @"remoteAccount" ] copy ] forKey: @"remoteAccount" ];
	[self setValue: [[t valueForKey: @"remoteBankCode" ] copy ] forKey: @"remoteBankCode" ];
	[self setValue: [[t valueForKey: @"remoteBankName" ] copy ] forKey: @"remoteBankName" ];
	[self setValue: [[t valueForKey: @"remoteIBAN" ] copy ] forKey: @"remoteIBAN" ];
	[self setValue: [[t valueForKey: @"remoteBIC" ] copy ] forKey: @"remoteBIC" ];
}

-(void)setJobId: (unsigned int) jid { jobId = jid; }
-(unsigned int)jobId { return jobId; };

@end
