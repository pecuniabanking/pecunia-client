//
//  ImportSettingsController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 27.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ImportSettings;

@interface ImportSettingsController : NSWindowController {
	IBOutlet NSArrayController	*fieldController;
	IBOutlet NSArrayController	*accountsController;
	IBOutlet NSTableView		*fieldTable;
	IBOutlet NSObjectController *settingsController;
	ImportSettings				*settings;
	NSArray						*importFields;
	BOOL						isNew;
	NSManagedObjectContext		*managedObjectContext;
	
}

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;

-(id)initWitSettings:(ImportSettings*)is;
-(IBAction)choseDataFile:(id)sender;

@end
