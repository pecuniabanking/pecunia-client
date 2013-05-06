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

#import "DonationMessageController.h"

@implementation DonationMessageController

- (id)init
{
    self = [super initWithWindowNibName: @"Donation"];
    donate = YES;
    return self;
}

- (BOOL)run
{
    [[self window] center];
    int res = [NSApp runModalForWindow: [self window]];
    if (res == 0) {
        return YES;
    } else {return NO; }
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    if (donate) {
        [NSApp stopModalWithCode: 0];
    } else {[NSApp stopModalWithCode: 1]; }
}

- (IBAction)donate: (id)sender
{
    [self close];
}

- (IBAction)later: (id)sender
{
    donate = NO;
    [self close];
}

@end
