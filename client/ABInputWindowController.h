//
//  ABInputWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 23.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//
#ifdef AQBANKING

#import <Cocoa/Cocoa.h>


@interface ABInputWindowController : NSWindowController {
	
//	NSPanel					*inputPanel;
	IBOutlet NSTextField	*inputText;
	IBOutlet NSTextField	*inputField;
	
	NSString	*text;
	NSString	*title;
	NSString	*result;
	
}
-(id)initWithText: (NSString* )x title: (NSString *)y;
-(void)controlTextDidEndEditing:(NSNotification *)aNotification;
-(void)windowWillClose:(NSNotification *)aNotification;
-(void)windowDidLoad;
-(NSString*)result;

@end

#endif