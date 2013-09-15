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

#import "NSOutlineView+PecuniaAdditions.h"
#import "PreferenceController.h"

@implementation NSOutlineView (PecuniaAdditions)

/**
 * Stores the expand and selection states of this outline view in the context.
 */
- (void)saveState
{
    NSString *autoSaveName = self.autosaveName;
    if (autoSaveName.length == 0) {
        return;
    }

    NSMutableArray *expandStates = [NSMutableArray array];
    for (NSInteger row = 0; row < self.numberOfRows; row++) {
        id item = [self itemAtRow: row];
        if ([self isItemExpanded: item]) {
            [expandStates addObject: @(row)];
        }
    }

    NSString *saveKey = [NSString stringWithFormat: @"%@-expand-state", autoSaveName];
    NSData *data = [NSArchiver archivedDataWithRootObject: expandStates];
    [PreferenceController setPersistentValue: data forKey: saveKey];

    saveKey = [NSString stringWithFormat: @"%@-selection", autoSaveName];
    [PreferenceController setPersistentIntValue: self.selectedRow forKey: saveKey];
}

/**
 * Restores a previously stored expand/selection state.
 */
- (void)restoreState
{
    NSString *autoSaveName = self.autosaveName;
    if (autoSaveName.length == 0) {
        return;
    }

    NSString *saveKey = [NSString stringWithFormat: @"%@-expand-state", autoSaveName];
    NSData *data = [PreferenceController persistentValueForKey: saveKey];
    if (data != nil) {
        NSArray *expandStates = [NSUnarchiver unarchiveObjectWithData: data];
        for (NSUInteger i = 0; i < expandStates.count; ++i) {
            [self expandItem: [self itemAtRow: [expandStates[i] intValue]]];
        }
    }

    saveKey = [NSString stringWithFormat: @"%@-selection", autoSaveName];
    NSInteger selectedRow = [PreferenceController persistentIntValueForKey: saveKey];
    [self selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow] byExtendingSelection: NO];
}

@end
