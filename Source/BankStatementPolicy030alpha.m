/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "BankStatementPolicy030alpha.h"

@implementation BankStatementPolicy030alpha

- (BOOL)endRelationshipCreationForEntityMapping: (NSEntityMapping *)mapping
                                        manager: (NSMigrationManager *)manager
                                          error: (NSError **)error
{
    NSManagedObjectContext *context = [manager destinationContext];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSArray *statements = [context executeFetchRequest: request error: error];

    for (NSManagedObject *statement in statements) {
        // calculate not assigned value
        NSMutableSet    *stats = [statement mutableSetValueForKey: @"assignments"];
        NSEnumerator    *iter = [stats objectEnumerator];
        NSManagedObject *stat;
        while ((stat = [iter nextObject]) != nil) {
            NSManagedObject *cat = [stat valueForKey: @"category"];
            if ([[cat valueForKey: @"isBankAcc"] boolValue] == NO && ![[cat valueForKey: @"name"] isEqualToString: @"++nassroot"]) {
                [statement setValue: [NSDecimalNumber zero] forKey: @"nassValue"];
                break;
            }
        }
    }
    return YES;
}

@end
