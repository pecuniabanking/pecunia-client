//
//  NewBankUserController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class User;
@class BankingController;
@class InstitutesController;

@interface NewBankUserController : NSWindowController
{
	IBOutlet NSObjectController		*objController;
	IBOutlet NSArrayController		*bankUserController;
	IBOutlet NSArrayController		*tanMethods;
	IBOutlet NSArrayController		*hbciVersions;
	IBOutlet NSWindow				*userSheet;
    IBOutlet User					*currentUser;
	IBOutlet NSMutableDictionary	*bankUserInfo;
	IBOutlet NSMutableArray			*bankUsers;
    
    @private
	BankingController* bankController;
    InstitutesController* institutesController;
	NSMutableArray* banks;
    NSWindow* selectBankUrlSheet;
}

- (id)initForController: (BankingController*)con;

- (IBAction)close:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)addEntry:(id)sender;
- (IBAction)selectBankUrl: (id)sender;
- (IBAction)removeEntry:(id)sender;
- (IBAction)updateBankParameter: (id)sender;
- (IBAction)getUserAccounts: (id)sender;
- (IBAction)changePinTanMethod: (id)sender;
- (IBAction)printBankParameter: (id)sender;

@end
