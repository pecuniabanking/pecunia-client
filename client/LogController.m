//
//  LogController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "LogController.h"
#import "HBCIClient.h"

static LogController	*_logController = nil;

@implementation LogController

-(id)init
{
	self = [super initWithWindowNibName:@"LogController"];
	_logController = self;
	currentLevel = log_warning;
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
	[self logLevelChanged:self ];
}


- (void)windowWillClose:(NSNotification *)notification
{
	isHidden = YES;
	[[HBCIClient hbciClient ] endLog ];
}

-(void)showWindow:(id)sender
{
	isHidden = NO;
	[super showWindow:sender ];
}

-(void)logMessage: (NSString*)msg withLevel: (int)level
{
//	NSLog(@"Level: %d: %@", level, msg);
	if(level > currentLevel) return;
	if(isHidden == NO) [self addLog: msg withLevel: (LogLevel)level ];
	else {
		if (level == 1) {
			[self addLog: msg withLevel: (LogLevel)level ];
			[self showWindow:self ];
			[[self window ] orderFront:self ]; 
		}
	}
}

-(NSColor*)colorForLevel: (LogLevel)level
{
	switch(level) {
		case log_error: 
		case log_alert: return [NSColor redColor ]; break;
		case log_warning: return [NSColor colorWithDeviceRed: 1.0 green: 0.73 blue: 0.0 alpha: 1.0 ]; break;
		case log_notice: return [NSColor colorWithDeviceRed: 0.0 green: 0.54 blue: 0.0 alpha: 1.0 ]; break;
		case log_info: return [NSColor blackColor ]; break;
		case log_debug: 
		case log_all: return [NSColor darkGrayColor ]; break;
	}
	return [NSColor blackColor ];
}

-(void)addLog: (NSString*)info withLevel: (LogLevel)level
{
	if(info == nil || [info length ] == 0) return;
	if(level > currentLevel) return;
	if (isHidden == YES) {
		if (level <= 1) {
			[self showWindow:self ];
			[[self window ] orderFront:self ]; 
		} else return;
	}
	
	if (writeConsole) {
		NSLog(@"%@", info);
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
		case 0: level = log_alert; break;
		case 1:	level = log_error; break;
		case 2: level = log_warning; break;
		case 3: level = log_notice; break;
		case 4: level = log_info; break;
		case 5: level = log_debug; break;
		case 6: level = log_all; break;
		default: level = log_warning; 
	}
	currentLevel = level;
	[[HBCIClient hbciClient ] startLog:self withLevel:currentLevel withDetails:withDetails ];
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
