/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

#import "GrowlNotification.h"

#define PecuniaNotification            @"Pecunia Notification"
#define PecuniaNotificationDescription NSLocalizedString(@"Pecunia Notification", nil)

@implementation GrowlNotification

- (id)init
{
    self = [super init];
    if (self != nil) {
        Class bridge = NSClassFromString(@"GrowlApplicationBridge");
        if ([bridge respondsToSelector: @selector(setGrowlDelegate:)]) {
            [bridge performSelector: @selector(setGrowlDelegate:) withObject: self];
        }
    }
    return self;
}

- (NSDictionary *)registrationDictionaryForGrowl
{
    NSDictionary *notificationsWithDescriptions = @{PecuniaNotification: PecuniaNotificationDescription};

    NSArray        *allNotifications = [notificationsWithDescriptions allKeys];
    NSMutableArray *defaultNotifications = [allNotifications mutableCopy];
    NSDictionary   *regDict = @{GROWL_APP_NAME: @"Pecunia",
                                GROWL_NOTIFICATIONS_ALL: allNotifications,
                                GROWL_NOTIFICATIONS_DEFAULT: defaultNotifications,
                                GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES: notificationsWithDescriptions};

    return regDict;
}

static NSData * pecuniaLogo(void)
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

static GrowlNotification *singleton;

/**
 * If Growl is installed this function shows the given message identified by a context string.
 * The context string determines which messages are coalesced.
 */
+ (void)showMessage: (NSString *)message withTitle: (NSString *)title context: (NSString *)context
{
    if (singleton == nil) {
        singleton = [[GrowlNotification alloc] init];
    }

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

}

@end
