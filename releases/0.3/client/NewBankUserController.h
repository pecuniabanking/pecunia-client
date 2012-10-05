//
//  NewBankUserController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ABUser;
@class BankingController;

@interface NewBankUserController : NSWindowController
{
	IBOutlet NSObjectController		*objController;
	IBOutlet NSArrayController		*bankUserController;
	IBOutlet NSArrayController		*tanMethods;
	IBOutlet NSWindow				*userSheet;
	IBOutlet ABUser					*currentUser;
	IBOutlet NSMutableDictionary	*bankUserInfo;
	IBOutlet NSArray				*bankUsers;
	BankingController				*bankController;
	NSArray							*hbciVersions;
	NSMutableArray					*banks;
}

-(id)initForController: (BankingController*)con;

- (IBAction)cancel:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)addEntry:(id)sender;
- (IBAction)removeEntry:(id)sender;
- (IBAction)getSystemID: (id)sender;
- (IBAction)showBanks: (id)sender;
- (IBAction)getUserAccounts: (id)sender;

- (BOOL)check;
- (void)readBanks;

@end
