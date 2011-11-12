//
//  GraphicsAdditions.h
//  Pecunia
//
//  Created by Mike on 29.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
