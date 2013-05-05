/**
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "NotificationWindowController.h"

@implementation NotificationWindowController

@synthesize message;
@synthesize title;

- (id)initWithMessage: (NSString *)msg title: (NSString *)header
{
    self = [super initWithWindowNibName: @"NotificationWindow"];
    if (self == nil) {
        return nil;
    }

    self.message = msg;
    self.title = header;
    return self;
}

- (void)awakeFromNib
{
    [messageField setStringValue: message];
    [[self window] setTitle: title];
    //    [[self window ] makeKeyAndOrderFront:self ];
}

- (IBAction)ok: (id)sender
{
    [[self window] close];
}

- (void)dealloc
{
    message = nil;
    title = nil;
}

@end
