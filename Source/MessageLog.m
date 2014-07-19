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

#import "ZipFile.h"
#import "ZipWriteStream.h"
#import "ZipException.h"

#include "LaunchParameters.h"
#import "HBCIController.h"

#define LOG_FLAG_COM_TRACE (1 << 5)

// A log file manager to implement own file names.
@interface ComTraceFileManager : DDLogFileManagerDefault

- (NSString *)newLogFileName;
- (BOOL)isLogFile: (NSString *)fileName;

@end

@implementation ComTraceFileManager

- (NSString *)newLogFileName {
    return @"Pecunia Com Trace.log";
}

- (BOOL)isLogFile: (NSString *)fileName {
    return [fileName isEqualToString: @"Pecunia Com Trace.log"];
}

@end

@interface MessageLog () {
    int          logLevel;        // One of the CocoaLumberjack log levels. Only used for the regular logger.
    DDFileLogger *fileLogger;     // The regular file logger.
    DDFileLogger *comTraceLogger; // The communication trace logger.
}
@end

@implementation MessageLog

@synthesize currentLevel;
@synthesize isComTraceActive;

- (id)init {
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
        fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger: fileLogger];

        if (LaunchParameters.parameters.customLogLevel > -1) {
            logLevel = LaunchParameters.parameters.customLogLevel;
        }

        fileLogger.doNotReuseLogFiles = YES; // Start with a new log file at each application launch.

        [self cleanUp]; // In case we were not shutdown properly on last run.
    }
    return self;
}

- (void)setIsComTraceActive: (BOOL)flag {
    if (isComTraceActive != flag) {
        if (isComTraceActive) {
            // Going to switch off the com trace. Remove logger and log file.
            NSArray *filePaths = [comTraceLogger.logFileManager sortedLogFilePaths];
            NSError *error;
            if (![NSFileManager.defaultManager removeItemAtPath: filePaths[0] error: &error]) {
                // Removing the file faild. Take a notice.
                LogError(@"Couldn't delete trace log at %@. The error is: %@", filePaths[0], error.localizedDescription);
            }

            [DDLog removeLogger: comTraceLogger];
            comTraceLogger = nil;

            // Only log errors now.
            [HBCIController.controller setLogLevel: HBCILogError];
        }

        isComTraceActive = flag;
        if (isComTraceActive) {
            // Switching on the com trace. Add logger.
            ComTraceFileManager *manager = [[ComTraceFileManager alloc] init];
            manager.maximumNumberOfLogFiles = 0;

            comTraceLogger = [[DDFileLogger alloc] initWithLogFileManager: manager];
            comTraceLogger.rollingFrequency = 0;

            [DDLog addLogger: comTraceLogger withLogLevel: LOG_FLAG_COM_TRACE];

            // Enable maximum logging in the server.
            [HBCIController.controller setLogLevel: HBCILogIntern];
        }
    }
}

/**
 * Internal helper method for prettyPrintServerMessage.
 */
+ (NSString *)doPrettyPrint: (NSString *)text {
    if ([text hasPrefix: @"<"]) {
        NSError       *error;
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString: text
                                                                   options: NSXMLNodePreserveAll
                                                                     error: &error];
        if (error == nil) {
            text = [document XMLStringWithOptions: NSXMLNodePrettyPrint];
        }

        return [NSString stringWithFormat: @"{\n%@\n}", text];
    }

    NSArray *parts = [text componentsSeparatedByString: @"'"];
    if (parts.count == 1) {
        return text;
    }
    NSString *combined = [parts componentsJoinedByString: @"\n  "];
    return [NSString stringWithFormat: @"{\n  %@\n}", [combined substringToIndex: combined.length - 3]];
}

/**
 * Server messages can have different formats and this functions tries to pretty print in a human
 * readable format.
 */
+ (NSString *)prettyPrintServerMessage: (NSString *)text {
    // For now only format plain xml log messages (usually commands) whose format isn't important for error analysis,
    // but which profit from better readablility. All other messages stay as they are.
    if ([text hasPrefix: @"<"]) {
        NSError       *error;
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString: text
                                                                   options: NSXMLNodePreserveAll
                                                                     error: &error];
        if (error == nil) {
            text = [document XMLStringWithOptions: NSXMLNodePrettyPrint];
        }

        return [NSString stringWithFormat: @"{\n%@\n}", text];
    }

    return text;
}

+ (NSString *)getStringInfoFor: (const char *)name {
    NSString *result = @"Unknown";

    size_t len = 0;
    sysctlbyname(name, NULL, &len, NULL, 0);

    if (len > 0) {
        char *value = malloc(len * sizeof(char));
        sysctlbyname(name, value, &len, NULL, 0);
        result = [NSString stringWithUTF8String: value];
        free(value);
    }

    return result;
}

+ (NSNumber *)getNumberInfoFor: (const char *)name {
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

+ (MessageLog *)log {
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

- (void)logError: (NSString *)format file: (const char *)file function: (const char *)function line: (int)line, ... {
    self.hasError = YES;
    if ((logLevel & LOG_FLAG_ERROR) != 0) {
        va_list args;
        va_start(args, line);

        [DDLog log: LOG_ASYNC_ERROR
             level: logLevel
              flag: LOG_FLAG_ERROR
           context: 0
              file: file
          function: function
              line: line
               tag:  nil
            format: [NSString stringWithFormat: @"[Error] %@", format]
              args: args];
    }
}

- (void)logWarning: (NSString *)format file: (const char *)file function: (const char *)function line: (int)line, ... {
    if ((logLevel & LOG_FLAG_WARN) != 0) {
        va_list args;
        va_start(args, line);

        [DDLog log: LOG_ASYNC_WARN
             level: logLevel
              flag: LOG_FLAG_WARN
           context: 0
              file: file
          function: function
              line: line
               tag:  nil
            format: [NSString stringWithFormat: @"[Warning] %@", format]
              args: args];
    }
}

- (void)logInfo: (NSString *)format file: (const char *)file function: (const char *)function line: (int)line, ... {
    if ((logLevel & LOG_FLAG_INFO) != 0) {
        va_list args;
        va_start(args, line);

        [DDLog log: LOG_ASYNC_INFO
             level: logLevel
              flag: LOG_FLAG_INFO
           context: 0
              file: file
          function: function
              line: line
               tag:  nil
            format: [NSString stringWithFormat: @"[Info] %@", format]
              args: args];
    }
}

- (void)logDebug: (NSString *)format file: (const char *)file function: (const char *)function line: (int)line, ... {
    if ((logLevel & LOG_FLAG_DEBUG) != 0) {
        va_list args;
        va_start(args, line);

        [DDLog log: LOG_ASYNC_DEBUG
             level: logLevel
              flag: LOG_FLAG_DEBUG
           context: 0
              file: file
          function: function
              line: line
               tag:  nil
            format: [NSString stringWithFormat: @"[Debug] %@", format]
              args: args];
    }
}

- (void)logDebug: (NSString *)format, ... {
    if ((logLevel & LOG_FLAG_WARN) != 0) {
        va_list args;
        va_start(args, format);

        [DDLog log: LOG_ASYNC_DEBUG
             level: logLevel
              flag: LOG_FLAG_DEBUG
           context: 0
              file: NULL
          function: NULL
              line: 0
               tag:  nil
            format: [NSString stringWithFormat: @"[Debug] %@", format]
              args: args];
    }
}

- (void)logVerbose: (NSString *)format file: (const char *)file function: (const char *)function line: (int)line, ... {
    if ((logLevel & LOG_FLAG_VERBOSE) != 0) {
        va_list args;
        va_start(args, line);

        [DDLog log: LOG_ASYNC_VERBOSE
             level: logLevel
              flag: LOG_FLAG_VERBOSE
           context: 0
              file: file
          function: function
              line: line
               tag:  nil
            format: [NSString stringWithFormat: @"[Verbose] %@", format]
              args: args];
    }
}

/**
 * Logs a communication trace message with the given level. For com traces we don't filter by log level, as we want
 * all messages logged at the moment. Communication traces are enabled only on demand, so this is ok.
 */
- (void)logComTraceForLevel: (HBCILogLevel)level format: (NSString *)format, ... {
    if (level == HBCILogError) {
        self.hasError = YES;
    }

    if (isComTraceActive) {
        va_list args;
        va_start(args, format);

        int      ddLevel = 0;
        NSString *comTraceFormat;
        switch (level) {
            case HBCILogNone:
                return;

            case HBCILogError:
                ddLevel = LOG_FLAG_ERROR;
                comTraceFormat = [NSString stringWithFormat: @"[Error] %@", format];
                break;

            case HBCILogWarning:
                ddLevel = LOG_FLAG_WARN;
                comTraceFormat = [NSString stringWithFormat: @"[Warning] %@", format];
                break;

            case HBCILogInfo:
                ddLevel = LOG_FLAG_INFO;
                comTraceFormat = [NSString stringWithFormat: @"[Info] %@", format];
                break;

            case HBCILogDebug:
                ddLevel = LOG_FLAG_DEBUG;
                comTraceFormat = [NSString stringWithFormat: @"[Debug] %@", format];
                break;

            case HBCILogDebug2:
            case HBCILogIntern:
                ddLevel = LOG_FLAG_VERBOSE;
                comTraceFormat = [NSString stringWithFormat: @"[Verbose] %@", format];
                break;
        }

        [DDLog log: YES
             level: ddLevel
              flag: LOG_FLAG_COM_TRACE
           context: 0
              file: NULL
          function: NULL
              line: 0
               tag:  nil
            format: comTraceFormat
              args: args];
    }
}

/**
 * An attempt is made to compress the source file and add the created zip (the target file) to the given items array.
 * If that for any reason fails the source file is added to the items instead.
 */
- (void)compressFileAndAndAddToItems: (NSMutableArray *)items
                          sourceFile: (NSURL *)source
                          targetFile: (NSURL *)target {
    BOOL savedAsZip = NO;

    @try {
        ZipFile *zipFile = [[ZipFile alloc] initWithFileName: target.path
                                                        mode: ZipFileModeCreate];
        ZipWriteStream *stream = [zipFile writeFileInZipWithName: [source.path lastPathComponent]
                                                compressionLevel: ZipCompressionLevelBest];
        NSData *logData = [NSData dataWithContentsOfURL: source];
        [stream writeData: logData];
        [stream finishedWriting];
        [zipFile close];

        [items addObject: target];
        savedAsZip = YES;
    }
    @catch (NSException *e) {
        LogError(@"Could not create zipped log (%@). Error: %@", source, e);
    }

    if (!savedAsZip) {
        [items addObject: source];
    }
}

/*
 * Sends the current log via mail to the Pecunia support. If there's a communication trace this is sent too.
 */
- (void)sendLog {
    [DDLog flushLog];

    // The standard log.
    NSArray *filePaths = [fileLogger.logFileManager sortedLogFilePaths];
    NSURL   *logURL = [NSURL fileURLWithPath: filePaths[0]];

    NSMutableArray *mailItems = [NSMutableArray array];
    if (logURL != nil) {
        // We use fixed zip file names by intention, to avoid polluting the log folder with many zip files.
        NSString *zip = [[fileLogger.logFileManager logsDirectory] stringByAppendingPathComponent: @"Pecunia Log.zip"];
        [self compressFileAndAndAddToItems: mailItems sourceFile: logURL targetFile: [NSURL fileURLWithPath: zip]];
    }

    // The com trace if active.
    if (isComTraceActive) {
        filePaths = [comTraceLogger.logFileManager sortedLogFilePaths];
        if ([NSFileManager.defaultManager fileExistsAtPath: filePaths[0]]) {
            NSURL    *traceURL = [NSURL fileURLWithPath: filePaths[0]];
            NSString *zip = [[fileLogger.logFileManager logsDirectory] stringByAppendingPathComponent: @"Pecunia Com Trace.zip"];
            [self compressFileAndAndAddToItems: mailItems sourceFile: traceURL targetFile: [NSURL fileURLWithPath: zip]];
        }
    }

    // It's a weird oversight that there's no unified way of sending a mail to a given address with an attachment.
    // That holds true at least until 10.8 where we finally have sharing services for that.
    if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_8) {
        // The least comfortable way.
        NSString *mailtoLink = [NSString stringWithFormat: @"mailto:support@pecuniabanking.de?subject=%@&body=%@%@",
                                NSLocalizedString(@"AP123", nil),
                                NSLocalizedString(@"AP121", nil),
                                NSLocalizedString(@"AP122", nil)];
        NSURL *url = [NSURL URLWithString: (NSString *)
                      CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)mailtoLink,
                                                                                NULL, NULL, kCFStringEncodingUTF8))];

        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: mailItems];
        [[NSWorkspace sharedWorkspace] openURL: url];
    } else {
        NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"AP121", nil)];

        NSSharingService *mailShare = [NSSharingService sharingServiceNamed: NSSharingServiceNameComposeEmail];
        [mailItems insertObject: textAttributedString atIndex: 0];
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
            // Mavericks and up. The best solution.
            mailShare.subject = NSLocalizedString(@"AP123", nil);
            mailShare.recipients = @[@"support@pecuniabanking.de"];
        } else {
            // Cannot set a mail subject or receiver before OS X 10.9 <sigh>.
            [mailItems insertObject: NSLocalizedString(@"AP124", nil) atIndex: 0];
        }
        [mailShare performWithItems: mailItems];
    }
}

- (void)showLog {
    [DDLog flushLog];

    // The standard log.
    NSArray *filePaths = [fileLogger.logFileManager sortedLogFilePaths];
    [NSWorkspace.sharedWorkspace openFile: filePaths[0]];
}

- (void)openLogFolder {
    NSArray *filePaths = [fileLogger.logFileManager sortedLogFilePaths];
    NSURL   *logURL = [NSURL fileURLWithPath: filePaths[0]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: @[logURL]];
}

- (void)cleanUp {
    // Clean up the log folder. Remove any com trace and zip file there.
    NSFileManager *manager = NSFileManager.defaultManager;

    NSString    *logFolder = fileLogger.logFileManager.logsDirectory;
    NSArray     *allFiles = [manager contentsOfDirectoryAtPath: logFolder error: nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat: @"self ENDSWITH '.zip'"];
    NSArray     *filteredFiles = [allFiles filteredArrayUsingPredicate: filter];

    for (NSString *file in filteredFiles) {
        NSError *error = nil;
        [manager removeItemAtPath: [logFolder stringByAppendingPathComponent: file] error: &error];
        if (error != nil) {
            LogError(@"Could not remove file. Reason: %@", error);
        }
    }
    filter = [NSPredicate predicateWithFormat: @"self CONTAINS 'com trace'"];
    filteredFiles = [allFiles filteredArrayUsingPredicate: filter];

    for (NSString *file in filteredFiles) {
        NSError *error = nil;
        [manager removeItemAtPath: [logFolder stringByAppendingPathComponent: file] error: &error];
        if (error != nil) {
            LogError(@"Could not remove file. Reason: %@", error);
        }
    }
}

@end
