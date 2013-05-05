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

#import "CCDLayoutAdditions.h"

@implementation NSSplitView (CCDLayoutAdditions)

- (NSString *)ccd__keyForLayoutName: (NSString *)name
{
    return [NSString stringWithFormat: @"CCDNSSplitView Layout %@", name];
}

- (void)storeLayoutWithName: (NSString *)name
{
    NSString       *key = [self ccd__keyForLayoutName: name];
    NSMutableArray *viewRects = [NSMutableArray array];
    NSEnumerator   *viewEnum = [[self subviews] objectEnumerator];
    NSView         *view;
    NSRect         frame;

    while ( (view = [viewEnum nextObject]) != nil) {
        if ([self isSubviewCollapsed: view]) {
            frame = NSZeroRect;
        } else {
            frame = [view frame];
        }

        [viewRects addObject: NSStringFromRect(frame)];
    }

    [[NSUserDefaults standardUserDefaults] setObject: viewRects forKey: key];
}

- (void)loadLayoutWithName: (NSString *)name
{
    NSString       *key = [self ccd__keyForLayoutName: name];
    NSMutableArray *viewRects = [[NSUserDefaults standardUserDefaults] objectForKey: key];
    NSArray        *views = [self subviews];
    int            i, count;
    NSRect         frame;

    count = MIN([viewRects count], [views count]);

    for (i = 0; i < count; i++) {
        frame = NSRectFromString(viewRects[i]);
        if (NSIsEmptyRect(frame) ) {
            frame = [views[i] frame];
            if ([self isVertical]) {
                frame.size.width = 0;
            } else {
                frame.size.height = 0;
            }
        }

        [views[i] setFrame: frame];
    }
}

@end
