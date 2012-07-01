/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import <Cocoa/Cocoa.h>

@interface NSColor (PecuniaAdditions)

+ (NSColor*)nextDefaultAccountColor;
+ (NSColor*)nextDefaultCategoryColor;
+ (NSColor*)applicationColorForKey: (NSString*)key;

- (CGColorRef)CGColor;

@end

/**
 * Helper code for drawing with bezier paths and shadows.
 * Code mostly from: http://www.seanpatrickobrien.com/journal/posts/3.
 */

@interface NSShadow (PecuniaAdditions)

- (id)initWithColor: (NSColor *)color offset: (NSSize)offset blurRadius: (CGFloat)blur;

@end

@interface NSBezierPath (PecuniaAdditions)

+ (NSBezierPath *)bezierPathWithCGPath: (CGPathRef)pathRef;
- (CGPathRef)cgPath;

- (NSBezierPath *)pathWithStrokeWidth: (CGFloat)strokeWidth;

- (void)fillWithInnerShadow: (NSShadow *)shadow borderOnly: (BOOL) borderOnly;
- (void)drawBlurWithColor: (NSColor *)color radius: (CGFloat)radius;

- (void)strokeInside;
- (void)strokeInsideWithinRect: (NSRect)clipRect;

@end

@interface NSView (PecuniaAdditions)

- (NSView*)printViewForLayerBackedView;

@end
