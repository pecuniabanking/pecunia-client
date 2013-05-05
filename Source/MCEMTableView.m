/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

#import "MCEMTableView.h"

@interface NSObject (MCEMTableView)
- (NSColor *)tableView: (MCEMTableView *)tv labelColorForRow: (int)row;
@end

@implementation MCEMTableView

- (void)drawRow: (int)rowIndex clipRect: (NSRect)clipRect
{
    NSColor *rowColor = nil;
    /* Outcommented to avoid a warning. This class will go anyway.
     if([[self delegate ] respondsToSelector: @selector(tableView:labelColorForRow:) ]) rowColor = [[self delegate] tableView:self labelColorForRow:rowIndex];
     */
    if (![[self selectedRowIndexes] containsIndex: rowIndex] && rowColor) {
        NSRect rect = [self rectOfRow: rowIndex];
        rect.origin.x += 1.0;
        rect.size.width -= 2.0;
        rect.size.height -= 3.0;
        rect.origin.y += 1.0;

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRoundedRect: rect xRadius: 9.0 yRadius: 9.0];

        NSGradient *aGradient = [[NSGradient alloc]
                                 initWithColorsAndLocations: [NSColor whiteColor], (CGFloat) - 0.1, rowColor, (CGFloat)1.1,
                                 nil];

        [aGradient drawInBezierPath: path angle: 90.0];
    }
    [super drawRow: rowIndex clipRect: clipRect];
}

@end
