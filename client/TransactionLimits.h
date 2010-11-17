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
}

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


