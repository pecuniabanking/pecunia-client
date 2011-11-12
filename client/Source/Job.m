//
//  job.m
//  MacBanking
//
//  Created by Frank Emminghaus on 08.04.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import "job.h"


@implementation Job

-(id)initWithAB: (const AB_JOB*)job
{
	const char*			c;
	AB_JOB_STATUS		ab_status;
	AB_JOB_TYPE			ab_type;
	const GWEN_TIME*	d;
	AB_ACCOUNT*			acc;
	
	[super init ];
	iD = AB_Job_GetJobId(job);
	createdBy = [[NSString stringWithUTF8String: (c = AB_Job_GetCreatedBy (job)) ? c: ""] retain];
	
	ab_status = AB_Job_GetStatus(job);
	status = [[NSString stringWithUTF8String: (c = AB_Job_Status2Char(ab_status)) ? c: ""] retain];
	
	ab_type = AB_Job_GetType(job);
	type = [[NSString stringWithUTF8String: (c = AB_Job_Type2LocalChar(ab_type)) ? c: ""] retain];
	
	resultText = [[NSString stringWithUTF8String: (c = AB_Job_GetResultText(job)) ? c: ""] retain];

	d = AB_Job_GetLastStatusChange(job);
	statusChange = [[NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ] retain];
	
	acc = AB_Job_GetAccount(job);
	accountNumber	= [[NSString stringWithUTF8String: (c = AB_Account_GetAccountNumber(acc)) ? c: ""] retain];
	bankCode		= [[NSString stringWithUTF8String: (c = AB_Account_GetBankCode(acc)) ? c: ""] retain];

	ab_job = (AB_JOB*)job;
	return self;
}

-(BOOL)isEqual: (Job*)job
{
	return iD == job->iD;
}

-(AB_JOB*)abJob { return ab_job; }

-(void)dealloc
{
	[createdBy release];
	[status release];
	[type release];
	[resultText release];
	[accountNumber release];
	[bankCode release];
	[statusChange release];
	
	[super dealloc ];
}

@end
