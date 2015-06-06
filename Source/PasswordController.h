/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

@class BWGradientBox;

@interface PasswordController : NSWindowController {
    IBOutlet NSTextField *inputText;
    IBOutlet NSTextField *inputField;
    IBOutlet NSButton    *savePasswordButton;

    NSString               *text;
    NSString               *title;
    NSString               *result;
    IBOutlet BWGradientBox *topGradient;
    IBOutlet BWGradientBox *backgroundGradient;
    NSTimer                *shakeTimer;

    BOOL savePassword;
    BOOL active;
    BOOL hidePasswortSave;
    BOOL retry;

    int shakeCount;
}

- (id)initWithText: (NSString *)x title: (NSString *)y;
- (void)controlTextDidEndEditing: (NSNotification *)aNotification;
- (void)windowWillClose: (NSNotification *)aNotification;
- (void)windowDidLoad;
- (void)closeWindow;
- (NSString *)result;
- (BOOL)shouldSavePassword;
- (void)retry;
- (void)disablePasswordSave;

@end
