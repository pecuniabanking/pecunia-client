//
//  LogController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageLog.h"

@interface LogController : NSWindowController <MessageLogUI>
{
    IBOutlet NSTextView		*logView;
	NSPopUpButton			*popUp;
	BOOL					isHidden;
	BOOL					withDetails;
	BOOL					writeConsole;
	LogLevel				currentLevel;
	MessageLog				*messageLog;
}

-(void)logLevelChanged: (id)sender;
-(void)clearLog: (id)sender;
-(void)saveLog: (id)sender;

+(LogController*)logController;

@end
