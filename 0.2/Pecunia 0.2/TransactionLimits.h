//
//  TransactionLimits.h
//  MacBanking
//
//  Created by Frank Emminghaus on 26.01.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <aqbanking/eutransferinfo.h>

@interface TransactionLimits : NSObject {
	int		maxLenRemoteName;
	int		maxLinesRemoteName;
	int		maxLenPurpose;
	int		maxLinesPurpose;
	double	localLimit, foreignLimit;
	int		minSetupTime;
	int		maxSetupTime;
	
	NSMutableArray*	allowedTextKeys;
}

-(id)initWithAB: (const AB_TRANSACTION_LIMITS*)t;
-(id)initWithEUInfo: (const AB_EUTRANSFER_INFO*)t;

-(int)maxLenRemoteName;
-(int)maxLinesRemoteName;
-(int)maxLenPurpose;
-(int)maxLinesPurpose;
-(double)localLimit;
-(double)foreignLimit;
-(int)minSetupTime;
-(int)maxSetupTime;

-(NSArray*)allowedTextKeys;

@end
