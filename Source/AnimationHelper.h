/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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
#import <Quartz/Quartz.h>

#import <CorePlot/CorePlot.h>

@interface AnimationHelper : NSObject {
}

+ (void)crossFadeFromView: (NSView *)oldView
                   toView: (NSView *)newView
             withDuration: (float)duration;

+ (void)switchFromView: (NSView *)from
                toView: (NSView *)to
             withSlide: (BOOL)doSlide;

+ (CAKeyframeAnimation *)shakeAnimation: (NSRect)frame;

@end

@interface NSWindow (PecuniaAdditions)

- (void)fadeIn;
- (void)zoomInWithOvershot: (NSRect)overshotFrame withFade: (BOOL)fade makeKey: (BOOL)makeKey;
- (void)fadeOut;
- (void)zoomOffToRect: (NSRect)endRect withFade: (BOOL)fade;

@end

@interface CALayer (PecuniaAdditions)

- (void)fadeIn;
- (void)fadeOut;
- (void)slideTo: (CGPoint)newPosition inTime: (CGFloat)time;

@end
