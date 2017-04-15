/**
 * Copyright (c) 2014, 2015, Pecunia Project. All rights reserved.
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

#import "AboutWindowController.h"

@interface AboutWindowController ()

@end

@implementation AboutWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource: @"Credits" ofType: @"rtf"];
    [aboutText readRTFDFromFile: path];

    // Countering a display problem:
    [aboutText pageDown: aboutText];
    [aboutText pageUp: aboutText];

    [versionText setStringValue: [NSString stringWithFormat: @"Version %@ (%@)",
                                  [mainBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"],[mainBundle objectForInfoDictionaryKey: @"CFBundleVersion"]
                                  ]];
    [copyrightText setStringValue: [mainBundle objectForInfoDictionaryKey: @"NSHumanReadableCopyright"]];
}

+ (void)showAboutBox
{
    static AboutWindowController *aboutBox;
    if (aboutBox == nil) {
        aboutBox = [[AboutWindowController alloc] initWithWindowNibName: @"About"];
    }

    [aboutBox showWindow: self];
}

@end
