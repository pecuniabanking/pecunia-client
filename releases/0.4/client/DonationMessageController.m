//
//  DonationMessageController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 24.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "DonationMessageController.h"


@implementation DonationMessageController

-(id)init
{
	self = [super initWithWindowNibName:@"Donation"];
	donate = YES;
	return self;
}

-(BOOL)run
{
	[[self window ] center ];
	int res = [NSApp runModalForWindow: [self window ] ];
    if(res == 0) return YES; else return NO;
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	if(donate) [NSApp stopModalWithCode:0];
	else [NSApp stopModalWithCode:1];
}


-(IBAction)donate: (id)sender
{
	[self close ];
}

-(IBAction)later: (id)sender
{
	donate = NO;
	[self close ];
}



@end
