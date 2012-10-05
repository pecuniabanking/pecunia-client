//
//  ABInputWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 23.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import "ABInputWindowController.h"


@implementation ABInputWindowController

-(id)init
{
	self = [super initWithWindowNibName:@"ABInputWindow"];
	return self;
}

-(id)initWithText: (NSString *)x title: (NSString *)y
{
	self = [super initWithWindowNibName:@"ABInputWindow"];
    text = [x copy];
	title = [y copy];
	return self;
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
//	[NSApp stopModalWithCode:0];
	[self close];
	
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	result = [inputField stringValue];
	if([result length] == 0)	[NSApp stopModalWithCode:1];
	else [NSApp stopModalWithCode:0];
}

-(void)windowDidLoad
{
	[inputText setStringValue: text];
	[[self window] setTitle: title];
}

-(NSString*)result
{
	return result;
}

@end
