//
//  NewBankUserController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Passport;
@class BankingController;

@interface NewBankUserController : NSWindowController
{
	IBOutlet NSObjectController		*objController;
	IBOutlet NSArrayController		*passportController;
	IBOutlet NSWindow				*passportSheet;
	IBOutlet Passport				*currentPassport;
	IBOutlet NSMutableArray			*passports;
	IBOutlet NSProgressIndicator	*progressIndicator;
	BankingController				*bankController;
	NSArray							*banks;
}

-(id)initForController: (BankingController*)con;

- (IBAction)cancel:(id)sender;
- (IBAction)addEntry:(id)sender;
- (IBAction)removeEntry:(id)sender;
- (IBAction)getSystemID: (id)sender;
- (IBAction)showBanks: (id)sender;

- (BOOL)check;

+(NewBankUserController*)currentController;

@end
