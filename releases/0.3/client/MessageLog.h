//
//  MessageLog.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	LogLevel_None,
	LogLevel_Error,
	LogLevel_Warning,
	LogLevel_Notice,
	LogLevel_Info,
	LogLevel_Debug,
	LogLevel_Verbous
} LogLevel;

@protocol MessageLogUI

-(void)addMessage:(NSString*)msg withLevel:(LogLevel)level;

@end


@interface MessageLog : NSObject {
	id<MessageLogUI>	logUI;
	NSDateFormatter		*formatter;
	BOOL				forceConsole;
	LogLevel			currentLevel;
}

@property (nonatomic, assign) BOOL forceConsole;
@property (nonatomic, readonly, assign) LogLevel currentLevel;

-(void)registerLogUI:(id<MessageLogUI>)ui;
-(void)unregisterLogUI;
-(void)addMessage:(NSString*)msg withLevel:(LogLevel)level;
-(void)setLevel:(LogLevel)level;

+(MessageLog*)log;


@end
