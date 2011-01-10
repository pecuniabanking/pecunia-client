//
//  PurposeSplitRule.h
//  Pecunia
//
//  Created by Frank Emminghaus on 09.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PurposeSplitRule : NSObject {
	int ePos, eLen;
	int kPos, kLen;
	int bPos, bLen;
	int vPos;	
}

-(void)applyToStatement:(BankStatement*)stat;

@end
