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

#import "ResultWindowController.h"
#import "NSString+PecuniaAdditions.h"

@implementation ResultWindowController

@synthesize forceHidden;

- (id)init
{
    self = [super initWithWindowNibName: @"ResultWindow"];
    messageLog = [MessageLog log];
    [messageLog registerLogUI: self];
    hasErrors = NO;
    logString = [[NSMutableAttributedString alloc] initWithString: @""];
    return self;
}

- (void)awakeFromNib
{
    [[logView textStorage] appendAttributedString: logString];
}

- (NSColor *)colorForLevel: (HBCILogLevel)level
{
    /*
    switch (level) {
        case LogLevel_Error: return [NSColor redColor]; break;
            
        case LogLevel_Warning: return [NSColor colorWithDeviceRed: 1.0 green: 0.73 blue: 0.0 alpha: 1.0]; break;
            
        case LogLevel_Notice: return [NSColor colorWithDeviceRed: 0.0 green: 0.54 blue: 0.0 alpha: 1.0]; break;
            
        case LogLevel_Info: return [NSColor blackColor]; break;
            
        case LogLevel_Debug:
        case LogLevel_Verbous: return [NSColor darkGrayColor]; break;
            
        default:
            break;
    }
     */
    return [NSColor blackColor];
}

- (void)addMessage: (NSString *)info withLevel: (HBCILogLevel)level
{
    /*
    if (info == nil || [info length] == 0) {
        return;
    }
    if (level > LogLevel_Warning) {
        return;
    }
    
    if (level <= LogLevel_Error) {
        hasErrors = YES;
    }
    
    if ([info hasSubstring:@"org.kapott"]) {
        return;
    }
    
    if (![info hasPrefix:@"HBCI Error"] && level > LogLevel_Error) {
        return;
    }
    
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", info]];
    [s addAttribute: NSForegroundColorAttributeName
              value: [self colorForLevel: level]
              range: NSMakeRange(0, [s length])];
    
    if (logView == nil) {
        [logString appendAttributedString: s];
    } else {
        [[logView textStorage] appendAttributedString: s];
        [logView moveToEndOfDocument: self];
    }
    //[logView display];
     */
}

- (void)showOnError
{
    if (hasErrors) {
        [self showWindow: nil];
    }
}

- (void)dealloc
{
    [messageLog unregisterLogUI: self];
}

- (void)close: (id)sender
{
    [[self window] close];
}

@end
