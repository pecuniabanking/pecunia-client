/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

// A view that shows only one of its subviews at a time, but can animate switching between them using
// a simple built-in up/down control, by code or by a timer.

typedef NS_ENUM(NSUInteger, SlideDirection) {
    SlideNone,
    SlideHorizontal,
    SlideVertical,
};

@interface SliderView : NSView <NSAnimationDelegate>

@property (assign) SlideDirection slide; // Determines the direction of the slide animation, if any.
@property (assign) BOOL fade;            // Determines if to apply a cross-fade (alone or in addition to the slide).
@property (assign) BOOL wrap;            // Determines whether to start at the beginning again when reaching the end and vice versa.

- (void)showNext;
- (void)showPrevious;

@end
