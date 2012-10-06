//
//  StandingOrder.m
//  Pecunia
//
//  Created by Frank Emminghaus on 21.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "StandingOrder.h"

@implementation StandingOrder (CoreDataGeneratedAccessors)
@dynamic changeDate;
@dynamic currency;
@dynamic cycle;
@dynamic executionDay;
@dynamic firstExecDate;
@dynamic toDelete;
@dynamic isSent;
@dynamic lastExecDate;
@dynamic nextExecDate;
@dynamic orderKey;
@dynamic period;
@dynamic purpose1;
@dynamic purpose2;
@dynamic purpose3;
@dynamic purpose4;
@dynamic remoteAccount;
@dynamic remoteBankCode;
@dynamic remoteBankName;
@dynamic remoteName;
@dynamic remoteSuffix;
@dynamic status;
@dynamic subType;
@dynamic type;
@dynamic isChanged;
@dynamic value;
@dynamic account;
@end


@implementation StandingOrder

-(NSString*)purpose
{
	NSMutableString* s = [NSMutableString stringWithCapacity: 100 ];
	if(self.purpose1) { [s appendString: self.purpose1 ]; }
	if(self.purpose2) { [s appendString: @" " ]; [s appendString: self.purpose2 ]; }
	if(self.purpose3) { [s appendString: @" " ]; [s appendString: self.purpose3 ]; }
	if(self.purpose4) { [s appendString: @" " ]; [s appendString: self.purpose4 ]; }
	
	return s;
}

-(void)setJobId: (unsigned int) jid { jobId = jid; }
-(unsigned int)jobId { return jobId; };

@end
