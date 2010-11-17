//
//  TransferTemplateController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TransferTemplate;

@interface TransferTemplateController : NSWindowController {
	NSManagedObjectContext		*context;
	IBOutlet NSArrayController	*templateController;
	IBOutlet NSArrayController	*countryController;
	IBOutlet NSView				*standardView;
	IBOutlet NSView				*euView;
	IBOutlet NSView				*boxView;
	IBOutlet NSTableView		*tableView;
	IBOutlet NSSegmentedControl	*segmentView;
	IBOutlet NSView				*scrollView;
	
	NSView						*currentView;
    NSPoint						subViewPos;
	BOOL						editMode;
}

-(IBAction)segButtonPressed:(id)sender;
-(IBAction)finished:(id)sender;
-(IBAction)countryChanged:(id)sender;

@end
