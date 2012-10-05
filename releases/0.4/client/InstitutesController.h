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
	NSPoint						origin;
}

-(void)setBankData: (NSArray*)data;
-(void)setPosition: (NSPoint)xy;
-(NSDictionary*)selectedBank;

-(IBAction)cancel:(id)sender;
-(IBAction)select:(id)sender;
-(IBAction)doSearch: (id)sender;

@end
