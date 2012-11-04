//
//  PasswordWindow.m
//  Pecunia
//
//  Created by Frank Emminghaus on 23.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "PasswordWindow.h"
#import "BWGradientBox.h"

@implementation PasswordWindow

-(id)init
{
	self = [super initWithWindowNibName:@"PasswordWindow"];
	active = YES;
    hidePasswortSave = NO;
	return self;
}

-(id)initWithText: (NSString *)x title: (NSString *)y
{
	self = [super initWithWindowNibName:@"PasswordWindow"];
    
    NSString *s = [x stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>" ];
    NSData *d = [s dataUsingEncoding:NSISOLatin1StringEncoding ];
    text = [[NSAttributedString alloc ] initWithHTML:d documentAttributes:NULL ];
	title = y;
	active = YES;
	return self;
}

-(void)awakeFromNib
{
    if (hidePasswortSave) {
        [savePasswordButton setHidden:YES ];
    }
    
    // Manually set up properties which cannot be set via user defined runtime attributes (Color is not available pre XCode 4).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];
}

-(void)controlTextDidEndEditing:(NSNotification *)aNotification
{
//	[self close];
	result = [inputField stringValue];
	if([result length] == 0) NSBeep();
	else {
		active = NO;
		//[self closeWindow ];
		[NSApp stopModalWithCode:0];
	}
}

-(void)retry
{
	[self showWindow:self ];
	active = YES;
	NSBeep();
	[inputField setStringValue: @"" ];
    
    shakeCount = 0;
    while (shakeCount < 10) {
        NSRect frame = [[self window] frame];
        if ((shakeCount % 2) == 1) {
            frame.origin.x -= 10;
            [[self window] setFrame:frame display:YES];
            usleep(50000);
        } else {
            frame.origin.x += 10;
            [[self window] setFrame:frame display:YES];
            usleep(50000);
        }
        shakeCount++;
    }
}


-(void)closeWindow
{
	[[self window ] close ];
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	if(active) {
		result = [inputField stringValue];
		if([result length] == 0) [NSApp stopModalWithCode:1];
		else [NSApp stopModalWithCode:0];
	}
}

-(void)windowDidLoad
{
	[inputText setAttributedStringValue: text];
	[[self window] setTitle: title];
}

-(NSString*)result
{
	return result;
}

-(BOOL)shouldSavePassword
{
	return savePassword;
}

-(void)disablePasswordSave
{
    hidePasswortSave = YES;
}


@end
