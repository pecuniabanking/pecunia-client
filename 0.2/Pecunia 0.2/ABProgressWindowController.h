//
//  ABProgressWindowController.h
//  MacBanking
//
//  Created by Frank Emminghaus on 31.12.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <gwenhywfar/gui_be.h>


@interface ABProgressWindowController : NSWindowController {
	IBOutlet NSTextField			*infoField;
	IBOutlet NSProgressIndicator	*progressIndicator;
	IBOutlet NSButton               *closeButton; 
	IBOutlet NSTableView			*logTable;
	
	NSString					*title;
	NSString					*info;
	NSMutableArray				*messages;
	
	int			progress;
	BOOL		keepOpen;
	BOOL		hideWindow;
	BOOL		aborted;
}

-(id)initWithText: (NSString* )x title: (NSString *)y;
//	-(void)windowWillClose:(NSNotification *)aNotification;
-(void)windowDidLoad;
-(void)closeWindow;
-(void)setProgressMaxValue: (double)max;
-(void)setProgressCurrentValue: (double)val;
-(void)addLog: (NSString *)log withLevel: (GWEN_LOGGER_LEVEL)level;
-(BOOL)stop;
-(void)setKeepOpen: (BOOL)b;
-(void)hideProgressIndicator;
-(void)hideLog;
-(BOOL)isAborted;

-(IBAction)close: (id)sender;
-(IBAction)abort: (id)sender;
@end
