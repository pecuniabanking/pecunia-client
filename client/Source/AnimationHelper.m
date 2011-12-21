//
//  AnimationHelper.m
//  Pecunia
//
//  Created by Mike Lischke on 28.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Quartz/Quartz.h>

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
        [bself orderOut: nil];
        [bself setAlphaValue: 1.f];
    }];
     */
    [[self animator] setAlphaValue: 0.f];
    [NSAnimationContext endGrouping];
}
@end

