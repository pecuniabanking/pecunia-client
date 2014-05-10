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

#import "MessageLog.h"

#import "DockIconController.h"
#import "BankStatement.h"
#include "BankAccount.h"

@implementation DockIconController

- (DockIconController *)initWithManagedObjectContext: (NSManagedObjectContext *)objectContext
{
    self = [super init];
    if (self != nil) {
        managedObjectContext = objectContext;
        [self updateBadge];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (NSInteger)numberUnread
{
    NSError             *error = nil;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement"
                                                         inManagedObjectContext: managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest new];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isNew = 1", self];
    [request setPredicate: predicate];
    return [managedObjectContext countForFetchRequest: request error: &error];
}

- (void)updateBadge
{
    NSInteger newBadgeValue = [self numberUnread];

    if (badgeValue != newBadgeValue) {
        badgeValue = newBadgeValue;
        if (newBadgeValue == 0) {
            [NSApplication.sharedApplication.dockTile setBadgeLabel: @""];
        } else {
            [NSApplication.sharedApplication.dockTile setBadgeLabel: [NSString stringWithFormat: @"%li", badgeValue]];
        }
    }
}

@end
