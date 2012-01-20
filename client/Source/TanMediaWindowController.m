//
//  TanMediaWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 08.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "TanMediaWindowController.h"
#import "User.h"

@implementation TanMediaWindowController

@synthesize message;
@synthesize tanMedia;
@synthesize userId;
@synthesize bankCode;


-(id)initWithUser:(NSString*)usrId bankCode:(NSString*)code message:(NSString*)msg
{
	self = [super initWithWindowNibName:@"TanMediaWindow"];
	if (self == nil) return nil;
	self.message = msg;
	self.userId = usrId;
	self.bankCode = code;
	return self;
}

-(void)awakeFromNib
{
	[messageField setStringValue:self.message ];
	active = YES;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSString *userMediaId = [NSString stringWithFormat:@"TanMediaList_%@_%@", self.bankCode, self.userId ];
	NSArray *mediaList = [defaults objectForKey:userMediaId ];
	if (mediaList) {
		for (NSString *media in mediaList) {
			[tanMediaCombo addItemWithObjectValue:media ];
		}
		// pick last media id
		[tanMediaCombo setStringValue:[mediaList lastObject ] ];
	}
}

-(void)saveTanMedia
{
	NSMutableArray *mediaList;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];
	NSString *userMediaId = [NSString stringWithFormat:@"TanMediaList_%@_%@", self.bankCode, self.userId ];
	NSArray *mList = [defaults objectForKey:userMediaId ];
	if (mList) {
		mediaList = [[mList mutableCopy] autorelease];
		[mediaList removeObject:self.tanMedia ];
		[mediaList addObject:self.tanMedia ];
	} else {
		mediaList = [NSMutableArray arrayWithCapacity:1 ];
		[mediaList addObject:self.tanMedia ];
	}
	[defaults setObject:mediaList forKey:userMediaId ];
}

-(void)closeWindow
{
	[[self window ] close ];
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	self.tanMedia = [tanMediaCombo stringValue ];
	if([self.tanMedia length] == 0) NSBeep();
	else {
		[self saveTanMedia ];
		active = NO;
		[self closeWindow ];
		[NSApp stopModalWithCode:0];
	}
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	if(active) {
		self.tanMedia = [tanMediaCombo stringValue];
		if([self.tanMedia length] == 0) [NSApp stopModalWithCode:1];
		else [NSApp stopModalWithCode:0];
	}
}

- (void)dealloc
{
	[message release], message = nil;
	[tanMedia release], tanMedia = nil;
	[userId release], userId = nil;
	[bankCode release], bankCode = nil;
	
	[super dealloc];
}

@end

