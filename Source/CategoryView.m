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

#import "CategoryView.h"


@implementation CategoryView

@synthesize saveCatName;

- (NSMenu *)menuForEvent: (NSEvent *)theEvent
{
    NSPoint curLoc = [self convertPoint: [theEvent locationInWindow] fromView: nil];

    int row = [self rowAtPoint: curLoc];
    if (row < 0) {
        return nil;
    }
    [self selectRowIndexes: [NSIndexSet indexSetWithIndex: row] byExtendingSelection: NO];

    return [self menu];
}

- (void)editSelectedCell
{
    [self editColumn: 0 row: [self selectedRow] withEvent: nil select: YES];
}

- (void)highlightSelectionInClipRect: (NSRect)rect
{
    // Stop the outline from drawing a selection background. We do that in the image cell.
}

- (void)cancelOperation: (id)sender
{
    if ([self currentEditor] != nil) {
        [self abortEditing];
        [[self window] makeFirstResponder: self];
    }
}

@end
