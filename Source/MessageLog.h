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

#import <Cocoa/Cocoa.h>

// XXX: remove as soon as the other loggers are updated/removed.
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

// Helper macros to simplify logging calls.
#define LogEnter [MessageLog.log logDebug: @"Entering %s", __PRETTY_FUNCTION__]
#define LogLeave [MessageLog.log logDebug: @"Leaving %s", __PRETTY_FUNCTION__]

#define LogError(format, ...) [MessageLog.log logError: format, ##__VA_ARGS__]
#define LogWarning(format, ...) [MessageLog.log logWarning: format, ##__VA_ARGS__]
#define LogInfo(format, ...) [MessageLog.log logInfo: format, ##__VA_ARGS__]
#define LogDebug(format, ...) [MessageLog.log logDebug: format, ##__VA_ARGS__]
#define LogVerbose(format, ...) [MessageLog.log logVerbose: format, ##__VA_ARGS__]

@interface MessageLog : NSObject {
    NSMutableSet    *logUIs;
    NSDateFormatter *formatter;
    BOOL            forceConsole;
}

@property (nonatomic, assign) BOOL     forceConsole;
@property (nonatomic, assign) LogLevel currentLevel;

+ (MessageLog *)log;

- (void)registerLogUI: (id<MessageLogUI>)ui;
- (void)unregisterLogUI: (id<MessageLogUI>)ui;
- (void)addMessage: (NSString *)msg withLevel: (LogLevel)level;

- (void)logError: (NSString *)format, ...;
- (void)logWarning: (NSString *)format, ...;
- (void)logInfo: (NSString *)format, ...;
- (void)logDebug: (NSString *)format, ...;
- (void)logVerbose: (NSString *)format, ...;

@end
