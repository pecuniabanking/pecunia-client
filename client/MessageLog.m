//
//  MessageLog.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MessageLog.h"

static MessageLog *_messageLog;

@implementation MessageLog

@synthesize forceConsole;
@synthesize currentLevel;

-(id)init
{
	self = [super init ];
	if (self == nil) return nil;
	formatter = [[[NSDateFormatter alloc ] init ] autorelease ];
	[formatter setDateFormat:@"HH:mm:ss.SSS"];
	return self;
}

-(void)registerLogUI:(id<MessageLogUI>)ui
{
	logUI = ui;
}

-(void)unregisterLogUI
{
	logUI = nil;
}

-(void)addMessage:(NSString*)msg withLevel:(LogLevel)level
{
	if (level > currentLevel) return;
	if (logUI == nil && forceConsole == NO) return;
	NSDate *date = [NSDate date ];
	NSString *message= [NSString stringWithFormat: @"<%@> %@\n", [formatter stringFromDate:date ] , msg ];
	if (forceConsole) {
		NSLog(message);
	}
	if (logUI) {
		[logUI addMessage:message withLevel:level ];
	}
}

-(void)setLevel:(LogLevel)level
{
	currentLevel = level;
	// todo
}


-(void)dealloc
{
	[formatter release ];
	[super dealloc ];
}


+(MessageLog*)log
{
	if (_messageLog == nil) {
		_messageLog = [[MessageLog alloc ] init ];
	}
	return _messageLog;
}


@end
