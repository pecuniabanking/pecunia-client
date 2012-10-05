//
//  AccountMoveController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 19.05.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface AccountMoveController : NSWindowController {
	IBOutlet NSObjectController *newAccountController;
	
	BankAccount	*account;
	NSString	*newAccountNumber;
	NSString	*newBankCode;
	BOOL		isOk;
	
}

@property (nonatomic, copy) NSString *newAccountNumber;
@property (nonatomic, copy) NSString *newBankCode;

-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

@end

