//
//  LogController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LogLevel.h"

@interface LogController : NSWindowController <MessageLog>
{
    IBOutlet NSTextView		*logView;
	NSPopUpButton			*popUp;
	BOOL					isHidden;
	BOOL					withDetails;
	BOOL					writeConsole;
	LogLevel				currentLevel;
}

//-(void)addLog: (NSString*)info withLevel: (LogLevel)level;
-(void)logLevelChanged: (id)sender;
-(void)clearLog: (id)sender;
-(void)saveLog: (id)sender;
-(void)logMessage: (NSString*)msg withLevel: (int)level;

+(LogController*)logController;

@end
