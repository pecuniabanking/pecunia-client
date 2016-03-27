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
#import "HBCIBridge.h"
#import "CallbackData.h"
#import "BankUser.h"
#import "NotificationWindowController.h"
#import "HBCICommon.h"

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
