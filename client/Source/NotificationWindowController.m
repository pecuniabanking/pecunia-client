//
//  NotificationWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.08.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "NotificationWindowController.h"


@implementation NotificationWindowController

@synthesize message;
@synthesize title;

-(id)initWithMessage:(NSString*)msg title:(NSString*)header
{
	self = [super initWithWindowNibName: @"NotificationWindow" ];
	if(self == nil) return nil;
	
	self.message = msg;
    self.title = header;
	return self;
}

-(void)awakeFromNib 
{
    [messageField setStringValue:message ];
    [[self window ] setTitle:title ];
//    [[self window ] makeKeyAndOrderFront:self ];
}

-(IBAction)ok:(id)sender
{
    [[self window ] close ];
}

- (void)dealloc
{
	[message release], message = nil;
	[title release], title = nil;
	[super dealloc];
}

@end

