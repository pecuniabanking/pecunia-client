//
//  AnimationHelper.m
//  Pecunia
//
//  Created by Mike Lischke on 28.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "AnimationHelper.h"

@implementation AnimationHelper

/**
 * Cross fade variant for not-layer-backed NSViews.
 */
+ (void)crossFadeFromView: (NSView*)oldView
                   toView: (NSView*)newView
             withDuration: (float)duration
{
    NSDictionary *oldFadeOut = nil;
    if (oldView != nil) {
        oldFadeOut = [NSDictionary dictionaryWithObjectsAndKeys:
                      oldView, NSViewAnimationTargetKey,
                      NSViewAnimationFadeOutEffect,
                      NSViewAnimationEffectKey, nil];
    }
    
    NSDictionary *newFadeIn;
    newFadeIn = [NSDictionary dictionaryWithObjectsAndKeys:
                 newView, NSViewAnimationTargetKey,
                 NSViewAnimationFadeInEffect,
                 NSViewAnimationEffectKey, nil];
    
    NSArray *animations;
    animations = [NSArray arrayWithObjects: newFadeIn, oldFadeOut, nil];
    
    NSViewAnimation *animation;
    animation = [[NSViewAnimation alloc]
                 initWithViewAnimations: animations];
    
    [animation setAnimationBlockingMode: NSAnimationBlocking];
    [animation setDuration: duration];
    
    [animation startAnimation];
    
    [animation release];
}

/**
 * Works for both, normal NSViews and layer-backed views. However it is much smoother for
 * the latter case.
 */
+ (void)switchFromView: (NSView*)from
                toView: (NSView*)to
             withSlide: (BOOL)doSlide
{
    if (doSlide) {
        NSRect frame = [to frame];
        frame.origin.x -= frame.size.width;
        [to setFrame: frame];
        frame.origin.x += frame.size.width;
        [[to animator] setFrame: frame];
    }
    
    [[to animator] setHidden: NO];
    [[from animator] setHidden: YES];
}

@end

@implementation NSWindow (PecuniaAdditions)

- (void)fadeIn
{
    [self setAlphaValue: 0.f];
    [self makeKeyAndOrderFront: nil];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration: 0.2];
    [[self animator] setAlphaValue: 1.f];
    [NSAnimationContext endGrouping];
}

- (void)fadeOut
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration: 0.2];
    /* Completion handler aren't available before 10.7.
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [self orderOut: nil];
        [self setAlphaValue: 1.f];
    }];
     */
    [[self animator] setAlphaValue: 0.f];
    [NSAnimationContext endGrouping];
}

@end

@implementation CALayer (PecuniaAdditions)

- (void)fadeIn
{
    self.hidden = NO;
    if (self.opacity < 1) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath: @"opacity"];
        animation.fromValue = [NSNumber numberWithFloat: 0];
        animation.toValue = [NSNumber numberWithFloat: 1];
        animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
        [animation setValue: @"fadeIn" forKey: @"action"];
        
        [self addAnimation: animation forKey: @"layerFade"];
        self.opacity = 1;
    }
}

- (void)fadeOut
{
    if (self.opacity > 0) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath: @"opacity"];
        animation.fromValue = [NSNumber numberWithFloat: 1];
        animation.toValue = [NSNumber numberWithFloat: 0];
        animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
        animation.delegate = self;
        [animation setValue: @"fadeOut" forKey: @"action"];
        
        // It is important to use the same key for fadeIn and fadeOut to avoid concurrency if triggered
        // quickly one after the other (e.g. for fast mouse moves). Using the same key will remove
        // an ongoing animation instead letting it run concurrently on the same property.
        [self addAnimation: animation forKey: @"layerFade"];
        self.opacity = 0;
    }
}

- (void)slideTo: (CGPoint)newPosition inTime: (CGFloat)time
{
    if (self.hidden) {
        return;
    }

    CGMutablePathRef animationPath = CGPathCreateMutable();
    CGPathMoveToPoint(animationPath, NULL, self.position.x, self.position.y);
    CGPathAddLineToPoint(animationPath, NULL, newPosition.x, newPosition.y);
    
    self.position = newPosition;
    
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath: @"position"];
    animation.path = animationPath;
    animation.duration = time;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    
    [self addAnimation: animation forKey: @"slide"];
}

- (void)animationDidStop: (CAAnimation*)anim finished: (BOOL)flag
{
    if (flag) {
        CABasicAnimation* animation = (CABasicAnimation*)anim;
        NSString* action = [animation valueForKey: @"action"];
        if ([action isEqualToString: @"fadeOut"]) {
            self.hidden = YES;
        }
    }
}

@end