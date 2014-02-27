/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "MessageLog.h"

@interface LogController : NSWindowController <MessageLogUI>
{
    IBOutlet NSTextView *logView;
    NSPopUpButton       *popUp;
    BOOL                isHidden;
    BOOL                withDetails;
    MessageLog          *messageLog;
    LogLevel            currentLevel;
}

- (IBAction)writeConsole: (id)sender;
- (IBAction)clearLog: (id)sender;
- (IBAction)saveLog: (id)sender;
- (IBAction)sendMail: (id)sender;
- (IBAction)close: (id)sender;

+ (LogController *)logController;

@end
