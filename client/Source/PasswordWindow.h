//
//  PasswordWindow.h
//  Pecunia
//
//  Created by Frank Emminghaus on 23.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PasswordWindow : NSWindowController {

	IBOutlet NSTextField	*inputText;
	IBOutlet NSTextField	*inputField;
	
	NSString	*text;
	NSString	*title;
	NSString	*result;
	BOOL		savePassword;
	BOOL		active;
	
}
-(id)initWithText: (NSString* )x title: (NSString *)y;
-(void)controlTextDidEndEditing:(NSNotification *)aNotification;
-(void)windowWillClose:(NSNotification *)aNotification;
-(void)windowDidLoad;
-(void)closeWindow;
-(NSString*)result;
-(BOOL)shouldSavePassword;
-(void)retry;

@end
