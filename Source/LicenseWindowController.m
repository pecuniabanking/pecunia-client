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

#import "LicenseWindowController.h"

@implementation LicenseWindowController

- (void)awakeFromNib
{
    NSURL              *url = [[NSBundle mainBundle] URLForResource: @"gpl-2.0-standalone" withExtension: @"html"];
    NSAttributedString *as = [[NSAttributedString alloc] initWithURL: url documentAttributes: NULL];
    [[licenseView textStorage] appendAttributedString: as];

    //NSString *path = [[NSBundle mainBundle] pathForResource: @"gpl-2.0-standalone" ofType: @"html"];

}

- (IBAction)accept: (id)sender
{
    [window close];
    [NSApp stopModalWithCode: 0];
}

- (IBAction)decline: (id)sender
{
    [window close];
    [NSApp stopModalWithCode: 1];
}

- (void)windowWillClose: (NSNotification *)aNotification
{
    [NSApp stopModalWithCode: 1];
}

@end
