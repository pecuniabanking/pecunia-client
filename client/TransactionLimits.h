//
//  TransactionLimits.h
//  MacBanking
//
//  Created by Frank Emminghaus on 26.01.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TransactionLimits : NSObject {
	int		maxLenRemoteName;
	int		maxLinesRemoteName;
	int		maxLenPurpose;
	int		maxLinesPurpose;
	double	localLimit;
	double  foreignLimit;
	int		minSetupTime;
	int		maxSetupTime;
	
	NSArray			*allowedTextKeys;
	
	// Standing Orders
	NSArray			*weekCycles;
	NSArray			*monthCycles;
	NSArray			*execDaysWeek;
	NSArray			*execDaysMonth;
	BOOL			allowMonthly;
	BOOL			allowWeekly;
	BOOL			allowChangeRemoteName;
	BOOL			allowChangeRemoteAccount;
	BOOL			allowChangeValue;
	BOOL			allowChangePurpose;
	BOOL			allowChangeFirstExecDate;
	BOOL			allowChangeLastExecDate;
	BOOL			allowChangeCycle;
	BOOL			allowChangePeriod;
	BOOL			allowChangeExecDay;
}

@property (nonatomic, retain) NSArray *weekCycles;
@property (nonatomic, retain) NSArray *monthCycles;
@property (nonatomic, retain) NSArray *execDaysWeek;
@property (nonatomic, retain) NSArray *execDaysMonth;
@property (nonatomic, assign) BOOL allowMonthly;
@property (nonatomic, assign) BOOL allowWeekly;
@property (nonatomic, assign) BOOL allowChangeRemoteName;
@property (nonatomic, assign) BOOL allowChangeRemoteAccount;
@property (nonatomic, assign) BOOL allowChangeValue;
@property (nonatomic, assign) BOOL allowChangePurpose;
@property (nonatomic, assign) BOOL allowChangeFirstExecDate;
@property (nonatomic, assign) BOOL allowChangeLastExecDate;
@property (nonatomic, assign) BOOL allowChangeCycle;
@property (nonatomic, assign) BOOL allowChangePeriod;
@property (nonatomic, assign) BOOL allowChangeExecDay;
@property (nonatomic, assign) int maxLenRemoteName;
@property (nonatomic, assign) int maxLinesRemoteName;
@property (nonatomic, assign) int maxLenPurpose;
@property (nonatomic, assign) int maxLinesPurpose;
@property (nonatomic, assign) double localLimit;
@property (nonatomic, assign) double foreignLimit;
@property (nonatomic, assign) int minSetupTime;
@property (nonatomic, assign) int maxSetupTime;
@property (nonatomic, retain) NSArray *allowedTextKeys;

-(int)maxLengthRemoteName;
-(int)maxLengthPurpose;

@end



