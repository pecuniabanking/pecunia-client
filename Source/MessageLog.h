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

#import <Cocoa/Cocoa.h>

typedef enum {
    LogLevel_None = -1,
    LogLevel_Error,
    LogLevel_Warning,
    LogLevel_Notice,
    LogLevel_Info,
    LogLevel_Debug,
    LogLevel_Verbous
} LogLevel;

@protocol MessageLogUI

- (void)addMessage: (NSString *)msg withLevel: (LogLevel)level;
- (void)setLogLevel: (LogLevel)level;

@end

// Helper macros to ease function enter/exit messages.
#define LOG_ENTER [MessageLog.log addMessage: [NSString stringWithFormat: @"Entering %s", __PRETTY_FUNCTION__] withLevel: LogLevel_Debug]
#define LOG_LEAVE [MessageLog.log addMessage: [NSString stringWithFormat: @"Leaving %s", __PRETTY_FUNCTION__] withLevel: LogLevel_Debug]

@interface MessageLog : NSObject {
    NSMutableSet    *logUIs;
    NSDateFormatter *formatter;
    BOOL            forceConsole;
}

@property (nonatomic, assign) BOOL     forceConsole;
@property (nonatomic, assign) LogLevel currentLevel;

- (void)registerLogUI: (id<MessageLogUI>)ui;
- (void)unregisterLogUI: (id<MessageLogUI>)ui;
- (void)addMessage: (NSString *)msg withLevel: (LogLevel)level;

+ (MessageLog *)log;


@end
