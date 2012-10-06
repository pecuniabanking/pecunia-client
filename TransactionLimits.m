//
//  TransactionLimits.m
//  Pecunia
//
//  Created by Frank Emminghaus on 26.01.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "TransactionLimits.h"

@implementation TransactionLimits

@synthesize weekCycles;
@synthesize monthCycles;
@synthesize execDaysWeek;
@synthesize execDaysMonth;
@synthesize allowMonthly;
@synthesize allowWeekly;
@synthesize allowChangeRemoteName;
@synthesize allowChangeRemoteAccount;
@synthesize allowChangeValue;
@synthesize allowChangePurpose;
@synthesize allowChangeFirstExecDate;
@synthesize allowChangeLastExecDate;
@synthesize allowChangeCycle;
@synthesize allowChangePeriod;
@synthesize allowChangeExecDay;
@synthesize maxLenRemoteName;
@synthesize maxLinesRemoteName;
@synthesize maxLenPurpose;
@synthesize maxLinesPurpose;
@synthesize localLimit;
@synthesize foreignLimit;
@synthesize minSetupTime;
@synthesize maxSetupTime;
@synthesize allowedTextKeys;


-(int)maxLengthRemoteName
{
	return maxLenRemoteName * maxLinesRemoteName;
}

-(int)maxLengthPurpose
{
	return maxLenPurpose * maxLinesPurpose;
}


-(void)dealloc
{
	[allowedTextKeys release], allowedTextKeys = nil;

	[weekCycles release], weekCycles = nil;
	[monthCycles release], monthCycles = nil;
	[execDaysWeek release], execDaysWeek = nil;
	[execDaysMonth release], execDaysMonth = nil;

	[super dealloc ];
}


@end



