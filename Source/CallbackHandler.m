/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

#import "CallbackHandler.h"
#import "ChipcardHandler.h"
#import "HBCIBridge.h"

static CallbackHandler *callbackHandler = nil;

@implementation CallbackHandler
@synthesize notificationController;

- (void)userIDChanged: (CallbackData*)data {
    NSArray *userData = [data.proposal componentsSeparatedByString: @"|"];
    BankUser *user = [BankUser findUserWithId:data.userId bankCode:data.bankCode];
    if (user != nil) {
        if (![user.userId isEqualToString:[userData objectAtIndex:0]]) {
            user.updatedUserId = [userData objectAtIndex:0];
        }
        if (![user.customerId isEqualToString:[userData objectAtIndex:1]]) {
            user.updatedCustomerId = [userData objectAtIndex:1];
        }
    }
}


- (NSString *)callbackWithData: (CallbackData *)data parent: (HBCIBridge *)parent {
    if ([data.command isEqualToString: @"password_load"]) {
        return [Security getPasswordForDataFile];
    }
    if ([data.command isEqualToString: @"password_save"]) {
        NSString *passwd = [Security getNewPassword: data];
        return passwd;
    }
    if ([data.command isEqualToString: @"getTanMethod"]) {
        return [Security getTanMethod: data];
    }
    if ([data.command isEqualToString: @"getPin"]) {
        return [parent.authRequest getPin: data.bankCode userId: data.userId];
    }
    if ([data.command isEqualToString: @"getTan"]) {
        return [Security getTan: data];
    }
    if ([data.command isEqualToString: @"getTanMedia"]) {
        return [Security getTanMedia: data];
    }
    if ([data.command isEqualToString: @"instMessage"]) {
        NSNotification *notification = [NSNotification notificationWithName: PecuniaInstituteMessageNotification
                                                                     object: @{@"bankCode": data.bankCode, @"message": data.message}];
        [[NSNotificationCenter defaultCenter] postNotification: notification];
    }
    if ([data.command isEqualToString: @"needChipcard"]) {
        notificationController = [[NotificationWindowController alloc] initWithMessage: NSLocalizedString(@"AP360", nil)
                                                                                 title: NSLocalizedString(@"AP357", nil)];
        [notificationController showWindow: self];
    }
    if ([data.command isEqualToString: @"haveChipcard"]) {
        [[notificationController window] close];
        notificationController = nil;
    }

    if ([data.command isEqualToString: @"needHardPin"]) {
        notificationController = [[NotificationWindowController alloc] initWithMessage: NSLocalizedString(@"AP351", nil)
                                                                                 title: NSLocalizedString(@"AP357", nil)];
        [notificationController showWindow: self];
    }
    if ([data.command isEqualToString: @"haveHardPin"]) {
        [[notificationController window] close];
        notificationController = nil;
    }
    if ([data.command isEqualToString: @"wrongPin"]) {
        [Security removePin: data];
    }
    if ([data.command isEqualToString: @"UserIDChanged"]) {
        [self userIDChanged: data];
    }
    if ([data.command isEqualToString:@"ctInit"]) {
        NSString *res = [[ChipcardHandler handler] initializeChipcard:data.proposal];
        if (res == nil) {
            return @"<error>";
        } else {
            return res;
        }
    }
    if ([data.command isEqualToString:@"ctReadBankData"]) {
        NSString *res = [[ChipcardHandler handler] readBankData:data.proposal];
        if (res == nil) {
            return @"<error>";
        } else {
            return res;
        }
    }
    if ([data.command isEqualToString:@"ctReadKeyData"]) {
        NSString *res = [[ChipcardHandler handler] readKeyData:data.proposal];
        if (res == nil) {
            return @"<error>";
        } else {
            return res;
        }
    }
    if ([data.command isEqualToString:@"ctEnterPin"]) {
        if ([[ChipcardHandler handler] enterPin:data.proposal]) {
            return @"<ok>";
        } else {
            return @"<error>";
        }
    }
    if ([data.command isEqualToString:@"ctSaveBankData"]) {
        if ([[ChipcardHandler handler] saveBankData:data.proposal]) {
            return @"<ok>";
        } else {
            return @"<error>";
        }
    }
    if ([data.command isEqualToString:@"ctSaveSig"]) {
        if ([[ChipcardHandler handler] saveSigId:data.proposal]) {
            return @"<ok>";
        } else {
            return @"<error>";
        }
    }
    if ([data.command isEqualToString:@"ctSign"]) {
        NSString *res = [[ChipcardHandler handler] sign:data.proposal];
        if (res == nil) {
            return @"<error>";
        } else {
            return res;
        }
    }
    if ([data.command isEqualToString:@"ctEncrypt"]) {
        NSString *res = [[ChipcardHandler handler] encrypt:data.proposal];
        if (res == nil) {
            return @"<error>";
        } else {
            return res;
        }
    }
    if ([data.command isEqualToString:@"ctDecrypt"]) {
        NSString *res = [[ChipcardHandler handler] decrypt:data.proposal];
        if (res == nil) {
            return @"<error>";
        } else {
            return res;
        }
    }
    if ([data.command isEqualToString:@"ctClose"]) {
        [[ChipcardHandler handler] close];
    }

    return @"";
}

- (void)showNotificationWindow
{
    [notificationController showWindow: self];
    [[notificationController window] makeKeyAndOrderFront: self];
}

+ (CallbackHandler *)handler
{
    if (callbackHandler == nil) {
        callbackHandler = [[CallbackHandler alloc] init];
    }
    return callbackHandler;
}

@end
