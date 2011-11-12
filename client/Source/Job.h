//
//  job.h
//  MacBanking
//
//  Created by Frank Emminghaus on 08.04.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <aqbanking/banking.h> 

/*
#define _Id				@"Id"
#define _CreatedBy		@"CreatedBy"
#define _Status			@"Status"
#define _Type			@"Type"
#define _Result			@"Result"
#define _Account		@"Account"
#define _BankCode		@"BankCode"
#define _StatusChange	@"StatChange"
*/

@interface Job : NSObject {
	unsigned int	iD;
	NSString		*createdBy;
	NSString		*status;
	NSString		*type;
	NSString		*resultText;
	NSString		*accountNumber;
	NSString		*bankCode;
	NSCalendarDate	*statusChange;
	AB_JOB			*ab_job;
}

-(id)initWithAB: (const AB_JOB*)job;
-(BOOL)isEqual: (Job*)job;
-(AB_JOB*)abJob;
@end
