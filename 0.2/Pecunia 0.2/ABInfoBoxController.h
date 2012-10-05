//
//  ABInfoBoxController.h
//  MacBanking
//
//  Created by Frank Emminghaus on 30.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ABInfoBoxController : NSWindowController {

//	NSPanel					*infoBox;
	IBOutlet NSTextView		*infoView;
	
	NSString	*infoText;
	NSString	*infoTitle;
	
}

-(id)initWithText: (NSString* )x title: (NSString *)y;
-(void)windowWillClose:(NSNotification *)aNotification;
-(void)windowDidLoad;
-(void)closeWindow;

@end
