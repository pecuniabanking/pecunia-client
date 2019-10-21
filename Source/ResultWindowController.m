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
@synthesize dateFormatter;
@synthesize logFont;

- (id)init
{
    self = [super initWithWindowNibName: @"ResultWindow"];
    hasErrors = NO;
    logString = [[NSMutableAttributedString alloc] initWithString: @""];
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd  HH:mm:ss:SSS";
    logFont = [NSFont fontWithName:@"LucidaGrande-Bold" size:14];
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

    NSString *logString = [NSString stringWithFormat:@"[%@]    %@", [dateFormatter stringFromDate:[NSDate date]], info ];
    
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", logString]];
    [s addAttribute: NSForegroundColorAttributeName
              value: [NSColor redColor]
              range: NSMakeRange(0, [s length])];
    [s addAttribute: NSFontAttributeName
              value: logFont
              range: NSMakeRange(0, [s length])];
    
    [[logView textStorage] appendAttributedString: s];
    [logView moveToEndOfDocument: self];
    [logView display];
    [self showWindow:nil];
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
