/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

#import "MCEMOutlineViewLayout.h"

@implementation NSOutlineView (MCEMOutlineViewLayout)

- (NSString *)persistentObjectForItem: (id)item
{
    return [[[[item representedObject] objectID] URIRepresentation] absoluteString];
}

- (void)restoreExpandedItems
{
    BOOL           found = TRUE;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray        *urs = [defaults objectForKey: [NSString stringWithFormat: @"NSOutlineView Items %@", [self autosaveName]]];
    NSMutableArray *uris = [NSMutableArray arrayWithArray: urs];

    while ([uris count] > 0 && found == TRUE) {
        NSInteger i, idx;

        found = FALSE;
        for (i = 0; i < [self numberOfRows]; i++) {
            NSString *uri = [self persistentObjectForItem: [self itemAtRow: i]];
            idx = [uris indexOfObject: uri];
            if (idx != NSNotFound) {
                [uris removeObjectAtIndex: idx];
                id item = [self itemAtRow: i];
                [self expandItem: item];
                found = TRUE;
            }
        }
    }
    if (found == FALSE) {
        [defaults setObject: nil forKey: [NSString stringWithFormat: @"NSOutlineView Items %@", [self autosaveName]]];
    }
}

- (void)saveLayout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: [self sortDescriptors]];
    [defaults setObject: data forKey: [NSString stringWithFormat: @"NSOutlineView SD %@", [self autosaveName]]];

    NSArray       *columns = [self tableColumns];
    NSTableColumn *tc = columns[0];
    [defaults setFloat: [tc width] forKey: [NSString stringWithFormat: @"NSOutlineView OW %@", [self autosaveName]]];
    [defaults setInteger: [self selectedRow] forKey: [NSString stringWithFormat: @"NSOutlineView SEL %@", [self autosaveName]]];

}

- (void)restoreLayout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData         *data = [defaults dataForKey: [NSString stringWithFormat: @"NSOutlineView SD %@", [self autosaveName]]];
    if (data) {
        NSArray *sd = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        if (sd) {
            [self setSortDescriptors: sd];
        }
    }
    float w = [defaults floatForKey: [NSString stringWithFormat: @"NSOutlineView SD %@", [self autosaveName]]];
    if (w > 0) {
        NSArray       *columns = [self tableColumns];
        NSTableColumn *tc = columns[0];
        [tc setWidth: w];
    }

    int idx = [defaults integerForKey: [NSString stringWithFormat: @"NSOutlineView SEL %@", [self autosaveName]]];
    if (idx >= 0) {
        [self selectRowIndexes: [NSIndexSet indexSetWithIndex: idx] byExtendingSelection: NO];
    }
}

- (void)restoreAll
{
    [self restoreExpandedItems];
    [self restoreLayout];
}

@end
