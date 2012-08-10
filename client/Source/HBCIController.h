//
//  HBCIController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 24.07.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageLog.h"
#import "HBCIBackend.h"


@class HBCIBridge;
@class PecuniaError;
@class ProgressWindowController;
@class SigningOption;

@interface HBCIController : NSObject <HBCIBackend> {
	
	HBCIBridge                  *bridge;
    ProgressWindowController    *progressController;
	NSMutableDictionary         *bankInfo;
	NSMutableDictionary         *countries;
	NSArray                     *bankQueryResults;
	int                         currentQuery;	
}

-(void)readCountryInfos;

-(void)asyncCommandCompletedWithResult:(id)result error:(PecuniaError*)err;
-(BOOL)registerBankUser:(BankUser*)user error:(PecuniaError**)err;
-(SigningOption*)signingOptionForAccount:(BankAccount*)account;


@end
