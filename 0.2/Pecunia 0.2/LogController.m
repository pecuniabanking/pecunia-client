//
//  LogController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "LogController.h"
#include <gwenhywfar/logger.h>
#include <aqhbci/aqhbci.h>
#include <aqbanking/banking.h>

#define MAX_MSG_SIZE 500

static LogController	*_logController;

int LogHook(GWEN_GUI *gui, const char *logDomain, GWEN_LOGGER_LEVEL priority, const char *str)
{
//	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSString *s = [NSString stringWithUTF8String: str ];
	if(!s) return 1;
	NSDate *date = [NSDate date ];
	NSDateFormatter *formatter = [[[NSDateFormatter alloc ] init ] autorelease ];
	[formatter setDateFormat:@"HH:mm:ss.SSS"];
	
	[_logController addLog: [NSString stringWithFormat: @"<%@> %@\n", [formatter stringFromDate:date ] , s ] withLevel: priority ];
//	[_logController addLog: [s stringByAppendingString: @"\n"] withLevel: priority ];
//	[pool release];
	return 1;
}


@implementation LogController

-(id)init
{
	self = [super initWithWindowNibName:@"LogController"];
	_logController = self;
	messages = [[NSMutableArray arrayWithCapacity: 1000 ] retain ];	
	return self;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	if(oldFN == NULL) {
		oldFN = GWEN_Gui_SetLogHookFn(GWEN_Gui_GetGui(), LogHook);
		[self logLevelChanged: self ];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	if(oldFN) {
		GWEN_Gui_SetLogHookFn(GWEN_Gui_GetGui(), oldFN);
		oldFN = NULL;
	}
	GWEN_Logger_SetLevel(AQHBCI_LOGDOMAIN, GWEN_LoggerLevel_Error);
	GWEN_Logger_SetLevel(AQBANKING_LOGDOMAIN, GWEN_LoggerLevel_Error);
	GWEN_Logger_SetLevel(GWEN_LOGDOMAIN, GWEN_LoggerLevel_Error);
}

-(NSColor*)colorForLevel: (GWEN_LOGGER_LEVEL)level
{
	switch(level) {
		case GWEN_LoggerLevel_Alert:
		case GWEN_LoggerLevel_Error: return [NSColor redColor ]; break;
		case GWEN_LoggerLevel_Warning: return [NSColor colorWithDeviceRed: 1.0 green: 0.73 blue: 0.0 alpha: 1.0 ]; break;
		case GWEN_LoggerLevel_Notice: return [NSColor colorWithDeviceRed: 0.0 green: 0.54 blue: 0.0 alpha: 1.0 ]; break;
		case GWEN_LoggerLevel_Info: return [NSColor blackColor ]; break;
		case GWEN_LoggerLevel_Debug:
		case GWEN_LoggerLevel_Verbous: return [NSColor darkGrayColor ]; break;
	}
	return [NSColor blackColor ];
}

-(void)addLog: (NSString*)info withLevel: (GWEN_LOGGER_LEVEL)level
{
	if(info == nil || [info length ] == 0) return;
	NSMutableAttributedString* s = [NSMutableAttributedString alloc ];
	[s initWithString: info ];
	[s addAttribute: NSForegroundColorAttributeName
			  value: [self colorForLevel: level ]
			  range: NSMakeRange(0, [s length ]) ];
	
	[messages addObject: s ];
	
	[logTable reloadData ];
	[logTable scrollRowToVisible: [messages count ]-1 ];
	[logTable display ];
}

-(void)logLevelChanged: (id)sender
{
	GWEN_LOGGER_LEVEL	level;
	
	int idx = [popUp indexOfSelectedItem ];
	if(idx < 0) return;
	switch(idx) {
		case 0:	level = GWEN_LoggerLevel_Alert; break;
		case 1: level = GWEN_LoggerLevel_Error; break;
		case 2: level = GWEN_LoggerLevel_Warning; break;
		case 3: level = GWEN_LoggerLevel_Notice; break;
		case 4: level = GWEN_LoggerLevel_Info; break;
		case 5: level = GWEN_LoggerLevel_Debug; break;
		case 6: level = GWEN_LoggerLevel_Verbous; break;
		default: level = GWEN_LoggerLevel_Warning; 
	}
	GWEN_Logger_SetLevel(AQHBCI_LOGDOMAIN, level);
	GWEN_Logger_SetLevel(AQBANKING_LOGDOMAIN, level);
	if(withDetails)	GWEN_Logger_SetLevel(GWEN_LOGDOMAIN, level); else GWEN_Logger_SetLevel(GWEN_LOGDOMAIN, GWEN_LoggerLevel_Error);
}

-(void)saveLog: (id)sender
{
	NSSavePanel *sp;
	NSError		*error = nil;
	int			runResult;
	
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	
	/* set up new attributes */
	[sp setTitle: @"Logdatei wählen" ];
	//	[sp setRequiredFileType:@"txt"];
	
	/* display the NSSavePanel */
	runResult = [sp runModalForDirectory:NSHomeDirectory() file: @""];
	
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {
		NSMutableString *s = [[NSMutableString alloc ] init ];
		NSAttributedString *str;
		for(str in messages) [s appendString: [str string ] ];
		
		if([s writeToFile: [sp filename ] atomically: NO encoding: NSUTF8StringEncoding error: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			[s release ];
			return;
		};
		[s release ];
	}
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [messages count ];
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [messages objectAtIndex: rowIndex ];
}

-(void)clearLog: (id)sender
{
	[messages removeAllObjects ];
	[logTable reloadData ];
	[logTable display ];
}

-(void)dealloc
{
	_logController = nil;
	[messages release ];
	[super dealloc ];
}

@end
