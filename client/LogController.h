//
//  LogController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	log_error = 1,
	log_warning,
	log_info,
	log_debug,
	log_all,
	log_messages
} LogLevel;

@interface LogController : NSWindowController
{
    IBOutlet NSTextView		*logView;
	NSPopUpButton			*popUp;
	BOOL					isHidden;
	LogLevel				currentLevel;
}

-(void)addLog: (NSString*)info withLevel: (LogLevel)level;
-(void)logLevelChanged: (id)sender;
-(void)clearLog: (id)sender;
-(void)saveLog: (id)sender;
-(void)logMessage: (NSString*)msg withLevel: (int)level;

+(LogController*)logController;

@end
