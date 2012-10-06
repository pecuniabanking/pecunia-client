//
//  BSSelectWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 02.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BSSelectWindowController : NSWindowController {
	NSArray						*resultList;
	IBOutlet NSArrayController	*statController;
	IBOutlet NSTableView		*statementsView;
}

-(id)initWithResults: (NSArray*)list;

-(IBAction)ok: (id)sender;
-(IBAction)cancel: (id)sender;

@end
