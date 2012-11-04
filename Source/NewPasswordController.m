//
//  NewPasswordController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.12.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "NewPasswordController.h"


@implementation NewPasswordController

-(id)init
{
	self = [super initWithWindowNibName:@"NewPasswordWindow"];
	return self;
}

-(id)initWithText: (NSString *)x title: (NSString *)y
{
	self = [super initWithWindowNibName:@"NewPasswordWindow"];
    text = [x copy];
	title = [y copy];
	return self;
}


-(void)windowWillClose:(NSNotification *)aNotification
{
	if(result == nil) [NSApp stopModalWithCode:1];
}

-(void)windowDidLoad
{
	[passwordText setStringValue: text];
	[[self window] setTitle: title];
}

-(IBAction)ok:(id)sender
{
	result = [passwordField1 stringValue];
	[NSApp stopModalWithCode:0];
	[[self window ] close ];
}

-(IBAction)cancel:(id)sender
{
	[[self window ] close ];
}

-(NSString*)result
{
	return result;
}

-(void)controlTextDidChange:(NSNotification *)aNotification
{
	NSString *pw1 = [passwordField1 stringValue];
	NSString *pw2 = [passwordField2 stringValue];
	if(pw1 && pw2 && [pw1 isEqualToString: pw2 ] && [pw1 length ]>4) [okButton setEnabled: YES ]; else [okButton setEnabled: NO ];
}



@end
