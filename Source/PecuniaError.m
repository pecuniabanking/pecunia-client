/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
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

#import "PecuniaError.h"
#import "MessageLog.h"

@implementation PecuniaError

@synthesize title;

+ (NSError *)errorWithText: (NSString *)msg
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity: 1];
    if (msg) {
        userInfo[NSLocalizedDescriptionKey] = msg;
    }
    return [NSError errorWithDomain: @"de.pecuniabanking.ErrorDomain" code: 1 userInfo: userInfo];
}

+ (PecuniaError *)errorWithCode: (ErrorCode)code message: (NSString *)msg
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity: 1];
    if (msg) {
        userInfo[NSLocalizedDescriptionKey] = msg;
    }
    PecuniaError *error = [[PecuniaError alloc] initWithDomain: @"de.pecuniabanking.ErrorDomain" code: code userInfo: userInfo];
    return error;
}

+ (PecuniaError *)errorWithMessage: (NSString *)msg title: (NSString *)title
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity: 1];
    if (msg) {
        userInfo[NSLocalizedDescriptionKey] = msg;
    }
    PecuniaError *error = [[PecuniaError alloc] initWithDomain: @"de.pecuniabanking.ErrorDomain" code: err_gen userInfo: userInfo];
    if (title) {
        error.title = title;
    }
    return error;
}

- (void)alertPanel
{
    // HBCI Errors
    if (self.code < err_gen && self.title == nil) {
        self.title = NSLocalizedString(@"AP53", nil);
    }

    NSString *message = nil;
    switch (self.code) {
        case err_hbci_abort: {
            message = NSLocalizedString(@"AP106", nil);
            break;
        }

        case err_hbci_gen: {
            message = @"%@";
            break;
        }

        case err_hbci_passwd: {
            message = NSLocalizedString(@"AP170", nil);
            break;
        }

        case err_hbci_param: {
            message = NSLocalizedString(@"AP359", nil);
            break;
        }

        default: {
            message = @"%@";
            break;
        }
    }

    if (message && title) {
        NSRunAlertPanel(title, message, NSLocalizedString(@"AP1", nil), nil, nil, self.localizedDescription);
    } else {
        LogError(@"Unhandled alert: %@", [self localizedDescription]);
    }
}

- (void)logMessage
{
    NSString *message = nil;
    switch (self.code) {
        case err_hbci_abort: {
            message = NSLocalizedString(@"AP106", nil);
            break;
        }

        case err_hbci_gen: {
            message = [self localizedDescription];
            break;
        }

        case err_hbci_passwd: {
            message = NSLocalizedString(@"AP170", nil);
            break;
        }

        case err_hbci_param: {
            message = [NSString stringWithFormat: NSLocalizedString(@"AP359", nil), [self localizedDescription]];
            break;
        }

        default: {
            message = [self localizedDescription];
            break;
        }
    }
    LogError(message);
}

@end
