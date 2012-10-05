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
	formatter = [[NSDateFormatter alloc ] init ];
	[formatter setDateFormat:@"HH:mm:ss.SSS"];
    logUIs = [[NSMutableSet alloc ] initWithCapacity:5];
	return self;
}

-(void)registerLogUI:(id<MessageLogUI>)ui
{
    [logUIs addObject:ui ];
}

-(void)unregisterLogUI:(id<MessageLogUI>)ui
{
    [logUIs removeObject: ui ];
}

-(void)addMessage:(NSString*)msg withLevel:(LogLevel)level
{
//	if (level > currentLevel) return;
	if ([logUIs count ] == 0 && forceConsole == NO) return;
	NSDate *date = [NSDate date ];
	NSString *message= [NSString stringWithFormat: @"<%@> %@\n", [formatter stringFromDate:date ] , msg ];
	if (forceConsole) {
		NSLog(@"%@", message);
	}
    for(id<MessageLogUI> logUI in logUIs) {
		[logUI addMessage:message withLevel:level ];
	}
}

-(void)addMessageFromDict:(NSDictionary*)data
{
	LogLevel level = (LogLevel)[[data objectForKey:@"level" ] intValue ];
	[self addMessage:[data objectForKey:@"message" ] withLevel: level ];
	[data release ];
}

-(void)setLevel:(LogLevel)level
{
	currentLevel = level;
	// todo
}


-(void)dealloc
{
	[formatter release ];
    [logUIs release ];
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
