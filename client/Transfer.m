//
//  Transfer.m
//  MacBanking
//
//  Created by Frank Emminghaus on 21.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "Transfer.h"
#import "TransferTemplate.h"
#import "TransactionLimits.h"

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
	if(self.purpose1) { [s appendString: self.purpose1 ]; }
	if(self.purpose2) { [s appendString: @" " ]; [s appendString: self.purpose2 ]; }
	if(self.purpose3) { [s appendString: @" " ]; [s appendString: self.purpose3 ]; }
	if(self.purpose4) { [s appendString: @" " ]; [s appendString: self.purpose4 ]; }
	
	return s;
}

-(void) copyFromTemplate:(TransferTemplate*)t withLimits:(TransactionLimits*)limits
{
	NSString *s;
	int maxLen = [limits maxLenRemoteName ] * [limits maxLinesRemoteName ];
	s = t.remoteName;
	if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
	self.remoteName = s;
	
	maxLen = [limits maxLenPurpose ];
	int num = [limits maxLinesPurpose ];
	
	s = t.purpose1;
	if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
	self.purpose1 = s;
	
	if (num > 1) {
		s = t.purpose2;
		if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
		self.purpose2 = s;
	}
	
	if (num > 2) {
		s = t.purpose3;
		if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
		self.purpose3 = s;
	}
	
	if (num > 3) {
		s = t.purpose4;
		if ([s length ] > maxLen) s = [s substringToIndex:maxLen ];
		self.purpose4 = s;
	}
	
	self.remoteAccount = t.remoteAccount;
	self.remoteBankCode = t.remoteBankCode;
//	self.remoteBankName = t.remoteBankName;
	self.remoteIBAN = t.remoteIBAN;
	self.remoteBIC = t.remoteBIC;
}

-(void)setJobId: (unsigned int) jid { jobId = jid; }
-(unsigned int)jobId { return jobId; };

@end
