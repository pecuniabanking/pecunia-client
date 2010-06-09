//
//  TransactionLimits.m
//  MacBanking
//
//  Created by Frank Emminghaus on 26.01.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "TransactionLimits.h"

@implementation TransactionLimits

/*
-(id)initWithAB: (const AB_TRANSACTION_LIMITS*)t
{
	self = 	[super init ];
	if(self == nil) return self;
	
	maxLenRemoteName = AB_TransactionLimits_GetMaxLenRemoteName(t);
	maxLinesRemoteName = AB_TransactionLimits_GetMaxLinesRemoteName(t);
	maxLenPurpose = AB_TransactionLimits_GetMaxLenPurpose(t);
	maxLinesPurpose = AB_TransactionLimits_GetMaxLinesPurpose(t);
	minSetupTime = AB_TransactionLimits_GetMinValueSetupTime(t);
	maxSetupTime = AB_TransactionLimits_GetMaxValueSetupTime(t);
	
	GWEN_STRINGLIST* sl = AB_TransactionLimits_GetValuesTextKey(t);
	if(sl) {
		const char*	c;
		NSString*	s;

		[allowedTextKeys release ];
		allowedTextKeys = [[NSMutableArray arrayWithCapacity: 5 ] retain ];
		GWEN_STRINGLISTENTRY* sle; 

		sle = GWEN_StringList_FirstEntry(sl);
		while(sle) {
			c = GWEN_StringListEntry_Data(sle);
			if(c) {
				s = [NSString stringWithUTF8String: c ];
				[allowedTextKeys addObject: s ];
			}
			sle = GWEN_StringListEntry_Next(sle);
		}
	}
	localLimit = foreignLimit = 0.0;
	return self;
}

-(id)initWithEUInfo: (const AB_EUTRANSFER_INFO*)t
{
	self = [self initWithAB: AB_EuTransferInfo_GetFieldLimits(t) ];
	const AB_VALUE*	val = AB_EuTransferInfo_GetLimitLocalValue(t);
	if(val) localLimit = AB_Value_GetValueAsDouble(val); else localLimit = 0.0;
	val = AB_EuTransferInfo_GetLimitForeignValue(t);
	if(val) foreignLimit = AB_Value_GetValueAsDouble(val); else foreignLimit = 0.0;
	return self;
}
*/

-(int)maxLenRemoteName { return maxLenRemoteName; }
-(int)maxLinesRemoteName { return maxLinesRemoteName; }
-(int)maxLenPurpose { return maxLenPurpose; }
-(int)maxLinesPurpose { return maxLinesPurpose; }
-(double)localLimit { return localLimit; }
-(double)foreignLimit { return foreignLimit; }
-(NSArray*)allowedTextKeys { return allowedTextKeys; }
-(int)minSetupTime { return minSetupTime; }
-(int)maxSetupTime { return maxSetupTime; }

-(void)dealloc
{
	if(allowedTextKeys) [allowedTextKeys release ];

	[super dealloc ];
}


@end
