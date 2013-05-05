/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

#import "CategoryReportingNode.h"

@implementation CategoryReportingNode

@synthesize name;
@synthesize children;
@synthesize values;
@synthesize periodValues;
@synthesize category;

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    self.children = [NSMutableSet setWithCapacity: 5];
    self.values = [NSMutableDictionary dictionaryWithCapacity: 20];
    self.periodValues = [NSMutableDictionary dictionaryWithCapacity: 20];
    return self;
}

- (void)dealloc
{
    name = nil;
    children = nil;
    values = nil;
    periodValues = nil;
}

@end
