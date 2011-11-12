//
//  PurposeSplitData.h
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankStatement;

@interface PurposeSplitData : NSObject {
	NSString	*purposeNew;
	NSString	*purposeOld;
	NSString	*remoteName;
	NSString	*remoteAccount;
	NSString	*remoteBankCode;
	BOOL		converted;
	BankStatement *statement;
}

@property (nonatomic, assign) BOOL converted;
@property (nonatomic, assign) BankStatement *statement;
@property (nonatomic, copy) NSString *purposeNew;
@property (nonatomic, copy) NSString *purposeOld;
@property (nonatomic, copy) NSString *remoteName;
@property (nonatomic, copy) NSString *remoteAccount;
@property (nonatomic, copy) NSString *remoteBankCode;


@end


