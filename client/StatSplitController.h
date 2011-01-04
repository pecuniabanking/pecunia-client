//
//  StatSplitController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.02.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankStatement;

@interface StatSplitController : NSWindowController {
	IBOutlet NSTableView		*splitView;
	IBOutlet NSArrayController	*splitStatController;
	IBOutlet NSArrayController	*catController;
	IBOutlet NSObjectController *currentStat;
	
	NSManagedObjectContext		*managedObjectContext;
	BankStatement				*statement;
	NSDecimalNumber				*residualAmount;

}

-(id)initWithStatement: (BankStatement*)stat;

-(IBAction)manageAssignments:(id)sender;

@end
