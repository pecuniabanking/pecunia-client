//
//  GenericImportController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 23.01.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ImExporter;
@class BankAccount;


@interface GenericImportController : NSWindowController {
	IBOutlet NSArrayController *moduleController;
	IBOutlet NSArrayController *profileController;
	IBOutlet NSArrayController *accountsController;
	IBOutlet NSTextField	*dataFileField;
	NSManagedObjectContext *managedObjectContext;
	BOOL isOk;
}

-(IBAction)import:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)choseDataFile:(id)sender;


@end
