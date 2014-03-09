/**
 * Copyright (c) 2012, 2014, Pecunia Project. All rights reserved.
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

#import "SystemNotification.h"

#define PecuniaNotification @"Pecunia Notification"

@implementation SystemNotification

- (id)init
{
    self = [super init];
    if (self != nil) {
        // Register as Growl delegate if we are on 10.7. Otherwise we use the notification center directly.
        if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_8) {
            Class bridge = NSClassFromString(@"GrowlApplicationBridge");
            if ([bridge respondsToSelector: @selector(setGrowlDelegate:)]) {
                [bridge performSelector: @selector(setGrowlDelegate:) withObject: self];
            }
        } else {
            [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate: self];
        }
    }
    return self;
}

- (NSDictionary *)registrationDictionaryForGrowl
{
    NSDictionary *notificationsWithDescriptions = @{PecuniaNotification: NSLocalizedString(@"Pecunia Notification", nil)};

    NSArray        *allNotifications = [notificationsWithDescriptions allKeys];
    NSMutableArray *defaultNotifications = [allNotifications mutableCopy];
    NSDictionary   *regDict = @{GROWL_APP_NAME: @"Pecunia",
                                GROWL_NOTIFICATIONS_ALL: allNotifications,
                                GROWL_NOTIFICATIONS_DEFAULT: defaultNotifications,
                                GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES: notificationsWithDescriptions};

    return regDict;
}

- (BOOL)userNotificationCenter: (NSUserNotificationCenter *)center
     shouldPresentNotification: (NSUserNotification *)notification
{
    return YES; // Show
}

static NSData *pecuniaLogo(void)
{
    static NSData *pecuniaLogoData = nil;

    if (pecuniaLogoData == nil) {
        NSString *path = [[NSBundle mainBundle] pathForImageResource: @"Vespasian"];
        if (path) {
            pecuniaLogoData = [[NSData alloc] initWithContentsOfFile: path];
        }
    }

    return pecuniaLogoData;
}

static SystemNotification *singleton;

/**
 * Shows the given message identified by a context string in the notification center of the system (10.8+)
 * or by using Growl if installed (OS X on 10.7).
 * The context string determines which messages are to be coalesced. Set this only if you don't want to have the message
 * show up if it was shown once already at any time in the past.
 */
+ (void)showMessage: (NSString *)message withTitle: (NSString *)title context: (NSString *)context
{
    if (singleton == nil) {
        singleton = [[SystemNotification alloc] init];
    }

    if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_8) {
        Class bridge = NSClassFromString(@"GrowlApplicationBridge");
        if ([bridge respondsToSelector: @selector(notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:identifier:)]) {
            [bridge notifyWithTitle: title
                        description: message
                   notificationName: PecuniaNotification
                           iconData: pecuniaLogo()
                           priority: 0
                           isSticky: NO
                       clickContext: nil
                         identifier: context];
        }
    } else {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = title;
        notification.informativeText = message;
        notification.identifier = context;

        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
        }
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: notification];
    }
}

// Not really sticky yet. Needs investigation.
+ (void)showStickyMessage: (NSString *)message withTitle: (NSString *)title context: (NSString *)context
{
    if (singleton == nil) {
        singleton = [[SystemNotification alloc] init];
    }
    
    if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_8) {
        Class bridge = NSClassFromString(@"GrowlApplicationBridge");
        if ([bridge respondsToSelector: @selector(notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:identifier:)]) {
            [bridge notifyWithTitle: title
                        description: message
                   notificationName: PecuniaNotification
                           iconData: pecuniaLogo()
                           priority: 0
                           isSticky: YES
                       clickContext: nil
                         identifier: context];
        }
    } else {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = title;
        notification.informativeText = message;
        notification.identifier = context;
        //notification.hasActionButton = YES;
        //notification.actionButtonTitle = @"Show";

        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
        }
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification: notification];
    }
}

@end
