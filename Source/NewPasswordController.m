/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

#import "NewPasswordController.h"
#import "MOAssistant.h"

@implementation NewPasswordController

- (id)init
{
    self = [super initWithWindowNibName: @"NewPasswordWindow"];
    return self;
}

- (id)initWithText: (NSString *)x title: (NSString *)y
{
    self = [super initWithWindowNibName: @"NewPasswordWindow"];
    text = [x copy];
    title = [y copy];
    return self;
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    if (result == nil) {
        [NSApp stopModalWithCode: 1];
    }
}

- (void)windowDidLoad
{
    [passwordText setStringValue: text];
    if (title != nil) {
        [[self window] setTitle: title];
    }
}

- (IBAction)ok: (id)sender
{
    result = [passwordField1 stringValue];
    [NSApp stopModalWithCode: 0];
    [[self window] close];
}

- (IBAction)cancel: (id)sender
{
    [[self window] close];
}

- (NSString *)result
{
    return result;
}

- (void)controlTextDidChange: (NSNotification *)aNotification
{
    if (aNotification.object == oldPasswordField) {
        if ([MOAssistant.sharedAssistant checkDataPassword:[oldPasswordField stringValue]]) {
            [passwordField1 setEnabled:YES];
            [passwordField2 setEnabled:YES];
        }
    } else {
        NSString *pw1 = [passwordField1 stringValue];
        NSString *pw2 = [passwordField2 stringValue];
        if (pw1 && pw2 && [pw1 isEqualToString: pw2] && [pw1 length] > 7) {
            [okButton setEnabled: YES];
        } else {
            [okButton setEnabled: NO];
        }
    }
}

@end
