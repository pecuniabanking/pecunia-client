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
	MessageLog				*messageLog;
}

-(IBAction)writeConsole:(id)sender;
-(IBAction)logLevelChanged: (id)sender;
-(IBAction)clearLog: (id)sender;
-(IBAction)saveLog: (id)sender;

+(LogController*)logController;

@end
