//
//  Transfer.m
//  Pecunia
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
@dynamic remoteSuffix;
@dynamic status;
@dynamic subType;
@dynamic type;
@dynamic usedTAN;
@dynamic value;
@dynamic valutaDate;
@dynamic account;

@synthesize changeState;

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
	NSUInteger maxLen = [limits maxLenRemoteName ] * [limits maxLinesRemoteName ];
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
	self.value = t.value;
}

- (void)copyFromTransfer: (Transfer*)other withLimits: (TransactionLimits*)limits
{
	NSString *s;
	NSUInteger maxLen = limits.maxLenRemoteName * limits.maxLinesRemoteName;
	s = other.remoteName;
	if (s.length > maxLen) {
        s = [s substringToIndex: maxLen];
    }
	self.remoteName = s;
	
	maxLen = [limits maxLenPurpose];
	int num = [limits maxLinesPurpose];
	
	s = other.purpose1;
	if (s.length > maxLen) {
        s = [s substringToIndex: maxLen];
    }
	self.purpose1 = s;
	
	if (num > 1) {
		s = other.purpose2;
		if (s.length > maxLen) {
            s = [s substringToIndex: maxLen];   
        }
		self.purpose2 = s;
	}
	
	if (num > 2) {
		s = other.purpose3;
		if (s.length > maxLen) {
            s = [s substringToIndex: maxLen];   
        }
		self.purpose3 = s;
	}
	
	if (num > 3) {
		s = other.purpose4;
		if (s.length > maxLen) {
            s = [s substringToIndex: maxLen];   
        }
		self.purpose4 = s;
	}
	
	self.remoteAccount = other.remoteAccount;
	self.remoteBankCode = other.remoteBankCode;
	self.remoteIBAN = other.remoteIBAN;
	self.remoteBIC = other.remoteBIC;
	self.value = other.value;
}

-(void)setJobId: (unsigned int) jid { jobId = jid; }
-(unsigned int)jobId { return jobId; };

@end
