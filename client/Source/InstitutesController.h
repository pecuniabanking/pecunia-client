//
//  InstitutesController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 12.06.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InstitutesController : NSWindowController {
	IBOutlet NSTableView		*bankView;
	IBOutlet NSSearchField		*bankSearch;
	IBOutlet NSArrayController	*bankController;
	
	NSArray						*banks;
	NSDictionary				*selectedBank;
}

- (void)setBankData: (NSArray*)data;
- (NSDictionary*)selectedBank;

- (IBAction)cancelSheet: (id)sender;
- (IBAction)endSheet: (id)sender;
- (IBAction)doSearch: (id)sender;

@end
