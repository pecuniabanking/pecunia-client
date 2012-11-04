//
//  ImportController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 29.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankQueryResult;

@interface ImportController : NSWindowController {
	IBOutlet NSArrayController	*settingsController;
	IBOutlet NSTextField		*dataFileField;
	BankQueryResult				*importResult;
	
}

@property (nonatomic, strong) BankQueryResult *importResult;

-(IBAction)createSettings:(id)sender;
-(IBAction)changeSettings:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)start:(id)sender;
-(IBAction)choseDataFile:(id)sender;

@end

