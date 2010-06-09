//
//  Transfer.m
//  MacBanking
//
//  Created by Frank Emminghaus on 21.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "Transfer.h"


@implementation Transfer

@dynamic chargedBy;
@dynamic currency;
@dynamic date;
@dynamic isSent;
@dynamic isTemplate;
@dynamic purpose1;
@dynamic purpose2;
@dynamic purpose3;
@dynamic purpose4;
@dynamic remoteAccount;
@dynamic remoteAddrCity;
@dynamic remoteAddrPhone;
@dynamic remoteAddrStreet;
@dynamic remoteAddrZip;
@dynamic remoteBankCode;
@dynamic remoteBankName;
@dynamic remoteBIC;
@dynamic remoteCountry;
@dynamic remoteIBAN;
@dynamic remoteName;
@dynamic status;
@dynamic subType;
@dynamic type;
@dynamic usedTAN;
@dynamic value;
@dynamic valutaDate;
@dynamic account;

-(NSString*)purpose
{
	NSMutableString* s = [NSMutableString stringWithCapacity: 100 ];
	if([self valueForKey: @"purpose1" ]) { [s appendString: [self valueForKey: @"purpose1" ] ]; }
	if([self valueForKey: @"purpose2" ]) { [s appendString: @" " ]; [s appendString: [self valueForKey: @"purpose2" ] ]; }
	if([self valueForKey: @"purpose3" ]) { [s appendString: @" " ]; [s appendString: [self valueForKey: @"purpose3" ] ]; }
	if([self valueForKey: @"purpose4" ]) { [s appendString: @" " ]; [s appendString: [self valueForKey: @"purpose4" ] ]; }
	
	return s;
}

-(void) copyFromTemplate: (Transfer*)t
{
	[self setValue: [[t valueForKey: @"remoteName" ] copy ] forKey: @"remoteName" ];
	[self setValue: [[t valueForKey: @"remoteAccount" ] copy ] forKey: @"remoteAccount" ];
	[self setValue: [[t valueForKey: @"remoteBankCode" ] copy ] forKey: @"remoteBankCode" ];
	[self setValue: [[t valueForKey: @"remoteBankName" ] copy ] forKey: @"remoteBankName" ];
	[self setValue: [[t valueForKey: @"remoteIBAN" ] copy ] forKey: @"remoteIBAN" ];
	[self setValue: [[t valueForKey: @"remoteBIC" ] copy ] forKey: @"remoteBIC" ];
	[self setValue: [[t valueForKey: @"purpose1" ] copy ] forKey: @"purpose1" ];
	[self setValue: [[t valueForKey: @"purpose2" ] copy ] forKey: @"purpose2" ];
	[self setValue: [[t valueForKey: @"purpose3" ] copy ] forKey: @"purpose3" ];
	[self setValue: [[t valueForKey: @"purpose4" ] copy ] forKey: @"purpose4" ];
}

-(void)setJobId: (unsigned int) jid { jobId = jid; }
-(unsigned int)jobId { return jobId; };

@end
