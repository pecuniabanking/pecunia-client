//
//  ABInfoBoxController.m
//  MacBanking
//
//  Created by Frank Emminghaus on 30.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import "ABInfoBoxController.h"


@implementation ABInfoBoxController

-(id)init
{
	self = [super initWithWindowNibName:@"ABInfoBox"];
	return self;
}

-(id)initWithText: (NSString *)x title: (NSString *)y
{
	self = [super initWithWindowNibName:@"ABInfoBox"];
    infoText = [x copy];
	infoTitle = [y copy];
	return self;
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp stopModalWithCode:0];
}

-(void)windowDidLoad
{
	[infoView setString: infoText];
	[[self window] setTitle: infoTitle];
}

-(void)closeWindow
{
	[[self window] close];
}

@end
