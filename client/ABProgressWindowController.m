//
//  ABProgressWindowController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 31.12.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import "ABProgressWindowController.h"


@implementation ABProgressWindowController

-(id)initWithText: (NSString *)x title: (NSString *)y
{
	self = [super initWithWindowNibName:@"ABProgressWindow"];
    info = [x copy];
	title = [y copy];
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	hideWindow = [defaults boolForKey: @"hideProgressWindow" ];
	messages = [[NSMutableArray arrayWithCapacity: 100 ] retain ];	
	keepOpen = NO;
	aborted = NO;
	maxLevel = GWEN_LoggerLevel_Verbous;
	return self;
}

-(void)windowDidLoad
{
	[infoField setStringValue: info];
	[[self window] setTitle: title];
	[progressIndicator setUsesThreadedAnimation: YES];
	[progressIndicator startAnimation: self];
}

-(void)setProgressMaxValue: (double)max
{
	if(max < 2.0) { 
		[progressIndicator setIndeterminate: YES];
		[progressIndicator setUsesThreadedAnimation: YES];
		[progressIndicator startAnimation: self];
	}
    else [progressIndicator setMaxValue: max];
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

-(void)setProgressCurrentValue: (double)val
{
	[progressIndicator setDoubleValue: val];
}

-(void)addLog: (NSString *)log withLevel: (GWEN_LOGGER_LEVEL)level
{
	if(log == nil || [log length ] == 0) return;
	if(level > GWEN_LoggerLevel_Notice) return;
	NSMutableAttributedString* s = [NSMutableAttributedString alloc ];
	[s initWithString: log ];
	[s addAttribute: NSForegroundColorAttributeName
			  value: [self colorForLevel: level ]
			  range: NSMakeRange(0, [s length ]) ];
	
	[messages addObject: s ];
	
	if(level <= GWEN_LoggerLevel_Error) {
		if(hideWindow) {
			[self showWindow: self ];
			[[self window ] makeKeyAndOrderFront: self ];
			hideWindow = NO;
		}
	}
	
	if(hideWindow == NO) {
		[logTable reloadData ];
		[logTable scrollRowToVisible: [messages count ]-1 ];
		[logTable display ];
	}
	
	if (level < maxLevel) maxLevel = level;
	
	[s release ];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [messages count ];
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [messages objectAtIndex: rowIndex ];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

-(void)closeWindow
{
	[[self window] close];
	[messages removeAllObjects ];
}

-(BOOL)stop
{
	[progressIndicator stopAnimation: self];
	if(keepOpen == NO && !hideWindow) {
		[self closeWindow ];
		return FALSE;
	}
	if (maxLevel > GWEN_LoggerLevel_Error && !hideWindow) {
		[self closeWindow ];
		return FALSE;
	}
	[closeButton setTitle: NSLocalizedString(@"close", @"close") ];
	[closeButton setKeyEquivalent:@"\r"];
	[closeButton setAction:@selector(close:) ];
	if(!hideWindow)	[[self window ] makeKeyAndOrderFront: self ];
	else return FALSE;
	return TRUE;
}

-(BOOL)isAborted
{
	return aborted;
}


-(IBAction)close: (id)sender
{
	[self closeWindow];
}

-(IBAction)abort: (id)sender
{
	aborted = YES;
	[self closeWindow ];
}

-(void)setKeepOpen: (BOOL)b
{
	keepOpen = b;
}

-(void)hideProgressIndicator
{
	[progressIndicator setHidden: TRUE ];
}

-(void)dealloc
{
	[title release ];
	[info release ];
	[messages release ];
	[super dealloc ];
}

-(void)hideLog
{
	NSRect frame;
	[logTable setHidden: TRUE ];
	frame = [[self window ] frame ];
	frame.size.height -= 290.0;
	[[self window ] setFrame: frame display: FALSE ];
}

@end
