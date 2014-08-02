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

#import "ResultWindowController.h"
#import "NSString+PecuniaAdditions.h"

@implementation ResultWindowController

@synthesize forceHidden;

- (id)init
{
    self = [super initWithWindowNibName: @"ResultWindow"];
    hasErrors = NO;
    logString = [[NSMutableAttributedString alloc] initWithString: @""];
    return self;
}

- (void)awakeFromNib
{
    [[logView textStorage] appendAttributedString: logString];
}

- (void)addMessage: (NSString *)info
{
    if (info == nil || [info length] == 0) {
        return;
    }
    hasErrors = YES;

    /*
    if ([info hasSubstring:@"org.kapott"]) {
        return;
    }
    */
    
    if (![info hasPrefix:@"HBCI error"] ) {
        return;
    }
    
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", info]];
    [s addAttribute: NSForegroundColorAttributeName
              value: [NSColor redColor]
              range: NSMakeRange(0, [s length])];
    
    if (logView == nil) {
        [logString appendAttributedString: s];
    } else {
        [[logView textStorage] appendAttributedString: s];
        [logView moveToEndOfDocument: self];
    }
    //[logView display];
}

- (void)showOnError
{
    if (hasErrors) {
        [self showWindow: nil];
    }
}

- (void)clear
{
    hasErrors = NO;
    logString = [[NSMutableAttributedString alloc] initWithString: @""];
    [[logView textStorage] setAttributedString: [[NSAttributedString alloc] initWithString: @""]];
}

- (void)close: (id)sender
{
    [[self window] close];
}

@end
