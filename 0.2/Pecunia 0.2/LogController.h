//
//  LogController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <gwenhywfar/gui_be.h>

@interface LogController : NSWindowController
{
    IBOutlet NSTextView		*logView;
	IBOutlet NSTableView	*logTable;
	GWEN_GUI_LOG_HOOK_FN	oldFN;
	NSPopUpButton			*popUp;
	BOOL					withDetails;
	NSMutableArray*			messages;
}

-(void)addLog: (NSString*)info withLevel: (GWEN_LOGGER_LEVEL)level;
-(void)logLevelChanged: (id)sender;
-(void)clearLog: (id)sender;
-(void)saveLog: (id)sender;

@end
