/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import <ExceptionHandling/ExceptionHandling.h>
#import <execinfo.h>

#import "PecuniaExceptionDelegate.h"
#import "MessageLog.h"
#import "MOAssistant.h"

@implementation PecuniaExceptionDelegate

- (BOOL)exceptionHandler: (NSExceptionHandler *)exceptionHandler
      shouldLogException: (NSException *)exception
                    mask: (NSUInteger)mask
{
    LogError(@"An unhandled exception occurred: %@", exception.reason);
    id targetObject = exception.userInfo[@"NSTargetObjectUserInfoKey"];
    if (targetObject != nil) {
        LogInfo(@"Target object info:\n%@\n", targetObject);
    } else {
        LogInfo(@"No additional information available\n");
    }

    [PecuniaExceptionDelegate printStackTraceForException: exception];

    NSError *error;
    if ([MOAssistant.sharedAssistant.context save: &error]) {
        LogInfo(@"Successfully saved context.");
    } else {
        LogError(@"Failed to save context. Reason: %@", error.description);
    }

    return NO; // Don't let the exception handler log this exception again.
}

- (BOOL)exceptionHandler: (NSExceptionHandler *)exceptionHandler
   shouldHandleException: (NSException *)exception
                    mask: (NSUInteger)mask
{
    // Serious trouble encountered. Try shutting down the context and stop Pecunia.
    // This was preceeded by the exceptionHandler:shouldLogException:mask: call, so we don't need to log anything here.
    [MOAssistant.sharedAssistant shutdown];
    exit(101);

    return NO; // Never reached.
}

+ (void)printStackTraceForException: (NSException *)exception
{
    // Try the exception's call stack symbols first (as they refer to the actual backtrace for that exception when given).
    // Print the current stack trace if that doesn't work.
    if (exception.callStackSymbols != nil) {
        for (NSString *entry in exception.callStackSymbols) {
            LogError(@"%@", entry);
        }
    } else {
        void* callstack[128];
        int frames = backtrace(callstack, 128);
        char **strs = backtrace_symbols(callstack, frames);

        for (int i = 0; i < frames; ++i)
            LogError(@"%s", strs[i]);
        free(strs);
    }
}

@end
