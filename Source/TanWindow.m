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

#import "TanWindow.h"


@implementation TanWindow

- (id)init
{
    self = [super initWithWindowNibName: @"TanWindow"];
    active = YES;
    return self;
}

- (id)initWithText: (NSString *)x;
{
    self = [super initWithWindowNibName: @"TanWindow"];

    NSString *s = [x stringByReplacingOccurrencesOfString: @"\n" withString: @"<br>"];
    NSData   *d = [s dataUsingEncoding: NSISOLatin1StringEncoding];
    text = [[NSAttributedString alloc] initWithHTML: d documentAttributes: NULL];
    active = YES;
    return self;
}

- (void)awakeFromNib
{
    NSRect boundingRect = [text boundingRectWithSize: NSMakeSize(400, 800) options: NSStringDrawingUsesLineFragmentOrigin];

    if (boundingRect.size.height > 97) {
        NSRect frame = [[self window] frame];
        frame.size.height += boundingRect.size.height - 97;
        [[self window] setFrame: frame display: YES];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL           showTAN = [defaults boolForKey: @"showTAN"];
    if (showTAN) {
        [[self window] makeFirstResponder: inputField];
    } else {
        [[self window] makeFirstResponder: secureInputField];
    }
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    if ([result length] == 0) {
        NSBeep();
    } else {
        active = NO;
        [self closeWindow];
        [NSApp stopModalWithCode: 0];
    }
}

- (void)closeWindow
{
    [[self window] close];
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    if (active) {
        if ([result length] == 0) {
            [NSApp stopModalWithCode: 1];
        } else {[NSApp stopModalWithCode: 0]; }
    }
}

- (void)windowDidLoad
{
    [inputText setAttributedStringValue: text];
}

- (NSString *)result
{
    return result;
}

@end
