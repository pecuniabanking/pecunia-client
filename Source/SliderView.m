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

#import "SliderView.h"

@interface SliderView () {
    NSInteger currentViewIndex;
}

@end

@implementation SliderView

@synthesize slide;
@synthesize fade;
@synthesize wrap;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        currentViewIndex = -1;
        slide = SlideNone;
        self.wantsLayer = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

}

- (void)didAddSubview: (NSView *)subview {
    [super didAddSubview: subview];

    if (currentViewIndex == -1) {
        currentViewIndex = 0; // Set the first add view as initial value.
        subview.hidden = NO;
    } else {
        subview.hidden = YES;
    }
    subview.frame = self.bounds;
}

- (void)willRemoveSubview: (NSView *)subview {
    if (self.subviews.count == 1) {
        currentViewIndex = -1; // The last view will be removed.
    } else {
        if ([self.subviews indexOfObject: subview] == (NSUInteger)currentViewIndex) {
            --currentViewIndex;
            if (currentViewIndex > -1) {
                NSView *view = self.subviews[currentViewIndex];
                view.hidden = NO;
                view.alphaValue = 1;
                view.frame = self.bounds;
            }
        }
    }
    [super willRemoveSubview: subview];
}

- (void)resizeSubviewsWithOldSize: (NSSize)oldSize {
    if (currentViewIndex > -1) {
        [self.subviews[currentViewIndex] setFrame: self.bounds];
    }
}

- (void)animateFromIndex: (NSInteger)first toIndex: (NSInteger)second up: (BOOL)up {
    NSView *firstView = first > -1 ? self.subviews[first] : nil;
    NSView *secondView = second > -1 ? self.subviews[second] : nil;

    NSRect frame = self.bounds;
    NSRect firstTarget = frame;
    NSRect secondStart = frame;
    switch (slide) {
        case SlideHorizontal:
            if (up) {
                firstTarget.origin.x -= NSWidth(frame);
                secondStart.origin.x += NSWidth(frame);
            } else {
                firstTarget.origin.x += NSWidth(frame);
                secondStart.origin.x -= NSWidth(frame);
            }
            break;

        case SlideVertical:
            if (up) {
                firstTarget.origin.y -= NSHeight(frame);
                secondStart.origin.y += NSHeight(frame);
            } else {
                firstTarget.origin.y += NSHeight(frame);
                secondStart.origin.y -= NSHeight(frame);
            }
            break;

        default:
            secondView.frame = frame;
            break;
    }

    secondView.hidden = NO;

    if (!fade && slide == SlideNone) {
        secondView.layer.opacity = 1;
        return;
    }

    if (fade) {
        CALayer *layer = firstView.layer;
        CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath: @"opacity"];
        alphaAnimation.fromValue = @1.0f;
        alphaAnimation.toValue = @0;
        layer.opacity = 0;
        [layer addAnimation: alphaAnimation forKey: @"opacity"];

        layer = secondView.layer;
        alphaAnimation = [CABasicAnimation animationWithKeyPath: @"opacity"];
        alphaAnimation.fromValue = @0;
        alphaAnimation.toValue = @1.0f;
        alphaAnimation.duration = 1.5;
        layer.opacity = 1;
        [layer addAnimation: alphaAnimation forKey: @"opacity"];
    }

    if (slide != SlideNone) {
        CALayer *layer = firstView.layer;
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath: @"bounds"];
        boundsAnimation.fromValue = [NSValue valueWithRect: self.bounds];
        boundsAnimation.toValue = [NSValue valueWithRect: firstTarget];
        layer.bounds = NSRectToCGRect(firstTarget);
        [layer addAnimation: boundsAnimation forKey: @"bounds"];

        layer = secondView.layer;
        boundsAnimation = [CABasicAnimation animationWithKeyPath: @"bounds"];
        boundsAnimation.fromValue = [NSValue valueWithRect: secondStart];
        boundsAnimation.toValue = [NSValue valueWithRect: self.bounds];
        layer.bounds = NSRectToCGRect(self.bounds);
        [layer addAnimation: boundsAnimation forKey: @"bounds"];
    }
}

- (void)showNext {
    NSInteger currentIndex = currentViewIndex;
    if (currentViewIndex < (NSInteger)self.subviews.count - 1) {
        ++currentViewIndex;
    } else {
        if (wrap) {
            currentViewIndex = self.subviews.count == 0 ? -1 : 0;
        }
    }

    if (currentViewIndex != currentIndex) {
        [self animateFromIndex: currentIndex toIndex: currentViewIndex up: NO];
    }
}

- (void)showPrevious {
    NSInteger currentIndex = currentViewIndex;
    if (currentViewIndex > 0) {
        --currentViewIndex;
    } else {
        if (wrap) {
            currentViewIndex = (NSInteger)self.subviews.count - 1;
        }
    }

    if (currentViewIndex != currentIndex) {
        [self animateFromIndex: currentIndex toIndex: currentViewIndex up: YES];
    }
}

@end
