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

#import "NSTreeController+PecuniaAdditions.h"

@implementation NSTreeController (PecuniaAdditions)

- (NSIndexPath *)reverseIndexPathForObject: (id)obj inArray: (NSArray *)nodes
{
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        NSTreeNode *node = nodes[i];
        id         nodeObj = [node representedObject];
        if (nodeObj == obj) {
            return [NSIndexPath indexPathWithIndex: i];
        } else {
            NSArray *children = [node childNodes];
            if (children == nil) {
                continue;
            }
            NSIndexPath *p = [self reverseIndexPathForObject: obj inArray: children];
            if (p) {
                return [p indexPathByAddingIndex: i];
            }
        }
    }
    return nil;
}

- (NSIndexPath *)indexPathForObject: (id)obj
{
    NSArray     *nodes = [[self arrangedObjects] childNodes];
    NSIndexPath *path = [self reverseIndexPathForObject: obj inArray: nodes];
    if (path == nil) {
        return nil;
    }
    // IndexPath umdrehen
    NSIndexPath *newPath = [[NSIndexPath alloc] init];
    for (NSInteger i = path.length - 1; i >= 0; i--) {
        newPath = [newPath indexPathByAddingIndex: [path indexAtPosition: i]];
    }
    return newPath;
}

- (BOOL)setSelectedObject: (id)obj
{
    NSIndexPath *path = [self indexPathForObject: obj];
    if (path == nil) {
        return NO;
    }
    return [self setSelectionIndexPath: path];
}

- (void)resort
{
    NSArray *sds = [self sortDescriptors];
    if (sds == nil) {
        return;
    }

    NSArray    *nodes = [[self arrangedObjects] childNodes];
    NSTreeNode *node;
    for (node in nodes) {
        [node sortWithSortDescriptors: sds recursively: YES];
    }
}

@end
