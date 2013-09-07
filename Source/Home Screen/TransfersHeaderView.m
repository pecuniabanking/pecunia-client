/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "TransfersHeaderView.h"
#import "GraphicsAdditions.h"

extern void *UserDefaultsBindingContext;

@implementation TransfersHeaderView

- (void)awakeFromNib
{
}

- (void)dealloc
{
}

- (void)drawRect: (NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedWhite: 1 alpha: 0.2] setFill];
    //NSRectFill(dirtyRect);

    [[NSColor colorWithCalibratedWhite: 1 alpha: 1] setFill];
    //NSFrameRect(dirtyRect);
}

@end
