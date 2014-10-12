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

- (id)init {
    self = [super init];
    if (self != nil) {
        NSUserNotificationCenter.defaultUserNotificationCenter.delegate = self;
    }
    return self;
}

- (BOOL)userNotificationCenter: (NSUserNotificationCenter *)center
     shouldPresentNotification: (NSUserNotification *)notification {
    return YES; // Show
}

/**
 * Shows the given message identified by a context string in the notification center of the system .
 */
+ (void)showMessage: (NSString *)message withTitle: (NSString *)title {
    static SystemNotification *singleton;
    if (singleton == nil) {
        singleton = [SystemNotification new];
    }

    NSUserNotification *notification = [NSUserNotification new];
    notification.title = title;
    notification.informativeText = message;
    notification.hasActionButton = NO;

    [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification: notification];
}

@end
