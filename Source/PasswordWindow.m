/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

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
    text = x;
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
    if (active) {
        [[self window ] close ];
    }
}

-(void)windowWillClose:(NSNotification *)aNotification
{
	if(active) {
		result = [inputField stringValue];
		if([result length] == 0) [NSApp stopModalWithCode:1];
		else [NSApp stopModalWithCode:0];
        active = NO;
	}
}

-(void)windowDidLoad
{
	[inputText setStringValue: text];
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
