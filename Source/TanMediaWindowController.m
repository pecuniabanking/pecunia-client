/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "TanMediaWindowController.h"

@implementation TanMediaWindowController

@synthesize message;
@synthesize tanMedia;
@synthesize userId;
@synthesize bankCode;


- (id)initWithUser: (NSString *)usrId bankCode: (NSString *)code message: (NSString *)msg
{
    self = [super initWithWindowNibName: @"TanMediaWindow"];
    if (self == nil) {
        return nil;
    }
    self.message = msg;
    self.userId = usrId;
    self.bankCode = code;
    return self;
}

- (void)awakeFromNib
{
    [messageField setStringValue: self.message];
    active = YES;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString       *userMediaId = [NSString stringWithFormat: @"TanMediaList_%@_%@", self.bankCode, self.userId];
    NSArray        *mediaList = [defaults objectForKey: userMediaId];
    if (mediaList) {
        for (NSString *media in mediaList) {
            [tanMediaCombo addItemWithObjectValue: media];
        }
        // pick last media id
        [tanMediaCombo setStringValue: [mediaList lastObject]];
    }
}

- (void)saveTanMedia
{
    NSMutableArray *mediaList;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString       *userMediaId = [NSString stringWithFormat: @"TanMediaList_%@_%@", self.bankCode, self.userId];
    NSArray        *mList = [defaults objectForKey: userMediaId];
    if (mList) {
        mediaList = [mList mutableCopy];
        [mediaList removeObject: self.tanMedia];
        [mediaList addObject: self.tanMedia];
    } else {
        mediaList = [NSMutableArray arrayWithCapacity: 1];
        [mediaList addObject: self.tanMedia];
    }
    [defaults setObject: mediaList forKey: userMediaId];
}

- (void)closeWindow
{
    [[self window] close];
}

- (void)controlTextDidEndEditing: (NSNotification *)aNotification
{
    self.tanMedia = [tanMediaCombo stringValue];
    if ([self.tanMedia length] == 0) {
        NSBeep();
    } else {
        [self saveTanMedia];
        active = NO;
        [self closeWindow];
        [NSApp stopModalWithCode: 0];
    }
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    if (active) {
        self.tanMedia = [tanMediaCombo stringValue];
        if ([self.tanMedia length] == 0) {
            [NSApp stopModalWithCode: 1];
        } else {[NSApp stopModalWithCode: 0]; }
    }
}

- (void)dealloc
{
    message = nil;
    tanMedia = nil;
    userId = nil;
    bankCode = nil;

}

@end
