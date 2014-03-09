/**
 * Copyright (c) 2011, 2014, Pecunia Project. All rights reserved.
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

#import "ProgressWindowController.h"

@implementation ProgressWindowController

@synthesize forceHidden;

- (id)init
{
    self = [super initWithWindowNibName: @"ProgressWindow"];
    messageLog = [MessageLog log];
    forceHidden = NO;
    return self;
}

- (void)windowDidBecomeKey: (NSNotification *)notification
{
    [messageLog registerLogUI: self];
}

- (void)windowWillClose: (NSNotification *)notification
{
    isHidden = YES;
    [messageLog unregisterLogUI: self];
}

- (void)start
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [messageLog registerLogUI: self];
    isHidden = [defaults boolForKey: @"hideProgressWindow"];
    if (forceHidden) {
        isHidden = YES;
    }
    if (!isHidden) {
        [self showWindow: self];
        [[self window] orderFront: self];
        [progressIndicator setUsesThreadedAnimation: YES];
        [progressIndicator startAnimation: self];
    }
}

- (void)showWindow: (id)sender
{
    isHidden = NO;
    [super showWindow: sender];
}

- (NSColor *)colorForLevel: (HBCILogLevel)level
{
    switch (level) {
        case HBCILogError: return [NSColor redColor]; break;

        case HBCILogWarning: return [NSColor colorWithDeviceRed: 1.0 green: 0.73 blue: 0.0 alpha: 1.0]; break;

        case HBCILogInfo: return [NSColor colorWithDeviceRed: 0.0 green: 0.54 blue: 0.0 alpha: 1.0]; break;

        case HBCILogDebug: return [NSColor blackColor]; break;

        case HBCILogDebug2:
        case HBCILogIntern: return [NSColor darkGrayColor]; break;

        default:
            break;
    }
    return [NSColor blackColor];
}

- (void)addMessage: (NSString *)info withLevel: (HBCILogLevel)level
{
    if (info == nil || [info length] == 0) {
        return;
    }
    if (level > HBCILogInfo) {
        return;
    }/*
    if (level < maxLevel) {
        maxLevel = level;
    }
    if (isHidden == YES) {
        if (level <= LogLevel_Error) {
            [self showWindow: self];
            [[self window] orderFront: self];
        } else {return; }
    }

    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", info]];
    [s addAttribute: NSForegroundColorAttributeName
              value: [self colorForLevel: level]
              range: NSMakeRange(0, [s length])];
    [[logView textStorage] appendAttributedString: s];

    [logView moveToEndOfDocument: self];
    [logView display];
      */
}

- (void)stop
{
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //BOOL           closeWindow = [defaults boolForKey: @"closeProgressOnSuccess"];

    [messageLog unregisterLogUI: self];
    self.forceHidden = NO;

    if (isHidden == NO) {
        [progressIndicator stopAnimation: self];
    }
    /*
    if (maxLevel > LogLevel_Error && closeWindow == YES) {
        [[self window] close];
        return;
    }
    if (isHidden == NO) {
        [[self window] makeKeyAndOrderFront: self];
    }
     */
}

- (void)cancel: (id)sender
{
    [[self window] close];
}

@end
