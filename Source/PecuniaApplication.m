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

#import "PecuniaApplication.h"
#import "MessageLog.h"
#import "PecuniaExceptionDelegate.h"
#import "MOAssistant.h"

static void signalHandler(int sig, siginfo_t *info, void *context)
{
    LogError(@"Caught signal %d", sig);

    // Log the current call stack. Do this before saving the context or we might get intermittent log output.
    [PecuniaExceptionDelegate printStackTraceForException: nil];

    NSError *error;
    if ([MOAssistant.sharedAssistant.context save: &error]) {
        LogInfo(@"Successfully saved context.");
    } else {
        LogError(@"Failed to save context. Reason: %@", error.description);
    }

    exit(102);
}

@implementation PecuniaApplication

- (id)init
{
    self = [super init];
    if (self != nil) {
        static PecuniaExceptionDelegate *exceptionDelegate = nil;

        @autoreleasepool
        {
            // First set exception handler delegate.
            exceptionDelegate = [[PecuniaExceptionDelegate alloc] init];
            NSExceptionHandler *exceptionHandler = [NSExceptionHandler defaultExceptionHandler];
            exceptionHandler.exceptionHandlingMask = NSLogUncaughtExceptionMask | NSHandleUncaughtExceptionMask |
            NSLogUncaughtSystemExceptionMask | NSHandleUncaughtSystemExceptionMask | NSLogUncaughtRuntimeErrorMask |
            NSHandleUncaughtRuntimeErrorMask | NSLogTopLevelExceptionMask | NSHandleTopLevelExceptionMask;
            exceptionHandler.delegate = exceptionDelegate;

            // Second set a handler for certain signals.
            int signals[] =
            {
                SIGQUIT, SIGILL, SIGTRAP, SIGABRT, SIGEMT, SIGFPE, SIGBUS, SIGSEGV,
                SIGSYS, SIGPIPE, SIGALRM, SIGXCPU, SIGXFSZ
            };
            const unsigned numSignals = sizeof(signals) / sizeof(signals[0]);
            struct sigaction sa;
            sa.sa_sigaction = signalHandler;
            sa.sa_flags = SA_SIGINFO;
            sigemptyset(&sa.sa_mask);
            for (unsigned i = 0; i < numSignals; i++)
                sigaction(signals[i], &sa, NULL);
        }
    }
    return self;
}

/**
 * Reports handled exceptions. Unhandled exceptions and signals are handled by the exception delegate and the sigaction.
 */
- (void)reportException: (NSException *)exception
{
    LogError(@"Exception reported by the runtime: %@", exception.debugDescription);
    [PecuniaExceptionDelegate printStackTraceForException: exception];
}

@end
