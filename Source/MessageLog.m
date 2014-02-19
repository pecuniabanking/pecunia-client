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

#include <sys/sysctl.h>

#import "MessageLog.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

#include "LaunchParameters.h"

@interface MessageLog ()
{
    int logLevel; // One of the CocoaLumberjack log levels.
}
@end

@implementation MessageLog

@synthesize forceConsole;
@synthesize currentLevel;

- (id)init
{
    self = [super init];
    if (self != nil) {
        // Default log level is info, unless we are debugging or got a custom log level.
#ifdef DEBUG
        // Logging to console only for debug builds. Otherwise use the log file only.
        logLevel = LOG_LEVEL_DEBUG;
        [DDLog addLogger: DDTTYLogger.sharedInstance];
        DDTTYLogger.sharedInstance.colorsEnabled = YES;
#else
        logLevel = LOG_LEVEL_INFO;
#endif

        // The file logger is always active.
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger: fileLogger];

        if (LaunchParameters.parameters.customLogLevel > -1) {
            logLevel = LaunchParameters.parameters.customLogLevel;
        }

        // Send a log message to create the log file handles, otherwise explicit log file rolling is ignored.
        // This goes to the last log file.
        [self logInfo: @"Rolling log file due to app start."];
        [fileLogger rollLogFileWithCompletionBlock: nil]; // We want a new log file on each start of the application.

        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat: @"HH:mm:ss.SSS"];
        logUIs = [[NSMutableSet alloc] initWithCapacity: 5];
    }
    return self;
}

- (void)registerLogUI: (id<MessageLogUI>)ui
{
    @synchronized(logUIs) {
        if (![logUIs containsObject: ui]) {
            [logUIs addObject: ui];
        }
    }
}

- (void)unregisterLogUI: (id<MessageLogUI>)ui
{
    @synchronized(logUIs) {
        if ([logUIs containsObject: ui]) {
            [logUIs removeObject: ui];
        }
    }
}

- (void)addMessage: (NSString *)msg withLevel: (LogLevel)level
{
    if ((logUIs.count == 0 && !forceConsole)){
        return;
    }
    NSDate   *date = [NSDate date];
    NSString *message = [NSString stringWithFormat: @"<%@> %@\n", [formatter stringFromDate: date], msg];
    if (forceConsole) {
        NSLog(@"%@", message);
    }

    @synchronized(logUIs) {
        for (id<MessageLogUI> logUI in logUIs) {
            [logUI addMessage: message withLevel: level];
        }
    }
}

- (void)addMessageFromDict: (NSDictionary *)data
{
    LogLevel level = (LogLevel)[data[@"level"] intValue];
    [self addMessage: data[@"message"] withLevel: level];
}

+ (NSString *)getStringInfoFor: (const char *)name
{
    NSString *result = @"Unknown";

    size_t len = 0;
    sysctlbyname(name, NULL, &len, NULL, 0);

    if (len > 0)
    {
        char *value = malloc(len * sizeof(char));
        sysctlbyname(name, value, &len, NULL, 0);
        result = [NSString stringWithUTF8String: value];
        free(value);
    }

    return result;
}

+ (NSNumber *)getNumberInfoFor: (const char *)name
{
    size_t len = 0;
    sysctlbyname(name, NULL, &len, NULL, 0);

    switch (len) {
        case 4: {
            int value;
            sysctlbyname(name, &value, &len, NULL, 0);
            return [NSNumber numberWithInt: value];
        }
        case 8: {
            int64_t value = 0;
            sysctlbyname(name, &value, &len, NULL, 0);
            return [NSNumber numberWithInteger: value];
        }
        default:
            return [NSNumber numberWithInt: 0];
    }
}

+ (MessageLog *)log
{
    static MessageLog *_messageLog;
    
    if (_messageLog == nil) {
        _messageLog = [[MessageLog alloc] init];

        // Log some important information. This goes to the newly created log file.
        LogInfo(@"Starting up application");

        NSProcessInfo *info = NSProcessInfo.processInfo;
        info.automaticTerminationSupportEnabled = NO;

        LogInfo(@"Arguments: %@", info.arguments);

        NSBundle *mainBundle = [NSBundle mainBundle];
        LogInfo(@"Pecunia version: %@", [mainBundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"]);

        LogInfo(@"Machine + OS: %@, %@", [MessageLog getStringInfoFor: "hw.model"], info.operatingSystemVersionString);
        LogInfo(@"Mem size: %.01fGB", [MessageLog getNumberInfoFor: "hw.memsize"].doubleValue / 1024 / 1024 / 1024);
        LogInfo(@"CPU : %@", [MessageLog getStringInfoFor: "machdep.cpu.brand_string"]);

        LogInfo(@"Process environment: %@", info.environment);

    }
    return _messageLog;
}

- (void)logError: (NSString *)format, ...
{
    if ((logLevel & LOG_FLAG_ERROR) != 0) {
        va_list args;
        va_start(args, format);

        [DDLog log: LOG_ASYNC_ERROR
             level: logLevel
              flag: LOG_FLAG_ERROR
           context: 0
              file: __FILE__
          function: sel_getName(_cmd)
              line: __LINE__
               tag:  nil
            format: [NSString stringWithFormat: @"[Error] %@", format]
              args: args];
    }
}

- (void)logWarning: (NSString *)format, ...
{
    if ((logLevel & LOG_FLAG_WARN) != 0) {
        va_list args;
        va_start(args, format);

        [DDLog log: LOG_ASYNC_WARN
             level: logLevel
              flag: LOG_FLAG_WARN
           context: 0
              file: __FILE__
          function: sel_getName(_cmd)
              line: __LINE__
               tag:  nil
            format: [NSString stringWithFormat: @"[Warning] %@", format]
              args: args];
    }
}

- (void)logInfo: (NSString *)format, ...
{
    if ((logLevel & LOG_FLAG_INFO) != 0) {
        va_list args;
        va_start(args, format);

        [DDLog log: LOG_ASYNC_INFO
             level: logLevel
              flag: LOG_FLAG_INFO
           context: 0
              file: __FILE__
          function: sel_getName(_cmd)
              line: __LINE__
               tag:  nil
            format: [NSString stringWithFormat: @"[Info] %@", format]
              args: args];
    }
}

- (void)logDebug: (NSString *)format, ...
{
    if ((logLevel & LOG_FLAG_DEBUG) != 0) {
        va_list args;
        va_start(args, format);

        [DDLog log: LOG_ASYNC_DEBUG
             level: logLevel
              flag: LOG_FLAG_DEBUG
           context: 0
              file: __FILE__
          function: sel_getName(_cmd)
              line: __LINE__
               tag:  nil
            format: [NSString stringWithFormat: @"[Debug] %@", format]
              args: args];
    }
}

- (void)logVerbose: (NSString *)format, ...
{
    if ((logLevel & LOG_FLAG_VERBOSE) != 0) {
        va_list args;
        va_start(args, format);

        [DDLog log: LOG_ASYNC_VERBOSE
             level: logLevel
              flag: LOG_FLAG_VERBOSE
           context: 0
              file: __FILE__
          function: sel_getName(_cmd)
              line: __LINE__
               tag:  nil
            format: [NSString stringWithFormat: @"[Verbose] %@", format]
              args: args];
    }
}

@end
