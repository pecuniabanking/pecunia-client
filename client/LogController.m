//
//  LogController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "LogController.h"
#import "HBCIClient.h"
#import "MessageLog.h"

static LogController	*_logController = nil;

@implementation LogController

-(id)init
{
	self = [super initWithWindowNibName:@"LogController"];
	_logController = self;
	messageLog = [MessageLog log ];
	isHidden = YES;
	return self;
}

+(LogController*)logController
{
	if (_logController == nil) {
		_logController = [[LogController alloc ] init ];
	}
	return _logController;
}


-(void)windowDidLoad
{
//	[popUp selectItemAtIndex:1 ];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[messageLog registerLogUI:self ];
	[self logLevelChanged:self ];
}


- (void)windowWillClose:(NSNotification *)notification
{
	isHidden = YES;
	[messageLog unregisterLogUI ];
}

-(void)showWindow:(id)sender
{
	isHidden = NO;
	[super showWindow:sender ];
}

-(NSColor*)colorForLevel: (LogLevel)level
{
	switch(level) {
		case LogLevel_Error: return [NSColor redColor ]; break;
		case LogLevel_Warning: return [NSColor colorWithDeviceRed: 1.0 green: 0.73 blue: 0.0 alpha: 1.0 ]; break;
		case LogLevel_Notice: return [NSColor colorWithDeviceRed: 0.0 green: 0.54 blue: 0.0 alpha: 1.0 ]; break;
		case LogLevel_Info: return [NSColor blackColor ]; break;
		case LogLevel_Debug: 
		case LogLevel_Verbous: return [NSColor darkGrayColor ]; break;
	}
	return [NSColor blackColor ];
}

-(void)addMessage:(NSString*)info withLevel:(LogLevel)level
{
	if(info == nil || [info length ] == 0) return;
	if (isHidden == YES) {
		if (level <= 1) {
			[self showWindow:self ];
			[[self window ] orderFront:self ]; 
		} else return;
	}
	
	NSMutableAttributedString* s = [NSMutableAttributedString alloc ];
	[s initWithString: [NSString stringWithFormat: @"%@\n", info ] ];
	[s addAttribute: NSForegroundColorAttributeName
			  value: [self colorForLevel: level ]
			  range: NSMakeRange(0, [s length ]) ];
	[[logView textStorage ] appendAttributedString: s ];
	[s release ];
	
	[logView moveToEndOfDocument: self ];
	[logView display];
}

-(void)logLevelChanged: (id)sender
{
	LogLevel	level;
	
	int idx = [popUp indexOfSelectedItem ];
	if(idx < 0) return;
	switch(idx) {
		case 0: level = LogLevel_Error; break;
		case 1:	level = LogLevel_Warning; break;
		case 2: level = LogLevel_Notice; break;
		case 3: level = LogLevel_Info; break;
		case 4: level = LogLevel_Debug; break;
		case 5: level = LogLevel_Verbous; break;
		default: level = LogLevel_Warning; 
	}
	[messageLog setLevel:level ];
	
	// workaround: GWEN/Aq sends messages to console...
	[[HBCIClient hbciClient ] setLogLevel:level ];
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
		if([[[logView textStorage ] mutableString ] writeToFile: [sp filename ] atomically: NO encoding: NSUTF8StringEncoding error: &error ] == NO) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return;
		};
	}
}

-(void)clearLog: (id)sender
{
	[[logView textStorage ] setAttributedString: [[NSAttributedString alloc ] initWithString: @"" ] ];
}

-(void)dealloc
{
	_logController = nil;
	[super dealloc ];
}

@end
