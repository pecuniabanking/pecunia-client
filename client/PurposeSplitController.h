//
//  PurposeSplitController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface PurposeSplitController : NSWindowController {
	NSManagedObjectContext		*context;
	IBOutlet NSTableView		*purposeView;
	IBOutlet NSArrayController	*purposeController;
	IBOutlet NSArrayController	*accountsController;
	IBOutlet NSTextField		*ePosField;
	IBOutlet NSTextField		*eLenField;
	IBOutlet NSTextField		*kPosField;
	IBOutlet NSTextField		*kLenField;
	IBOutlet NSTextField		*bPosField;
	IBOutlet NSTextField		*bLenField;
	IBOutlet NSTextField		*vPosField;
	IBOutlet NSComboBox			*comboBox;
	
	int							actionResult;
	BankAccount					*account;

}

-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)calculate:(id)sender;
-(IBAction)comboChanged:(id)sender;


-(void)getStatements;

@end


