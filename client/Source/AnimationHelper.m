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

//--------------------------------------------------------------------------------------------------

@interface ZoomWindow : NSWindow
{
    CGFloat animationTimeMultiplier;
}

@property (nonatomic, readwrite, assign) CGFloat animationTimeMultiplier;

@end

@implementation ZoomWindow

@synthesize animationTimeMultiplier;

- (NSTimeInterval)animationResizeTime: (NSRect)newWindowFrame
{
	float multiplier = animationTimeMultiplier;
	
	if (([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) != 0) {
		multiplier *= 10;
	}
	
	return [super animationResizeTime: newWindowFrame] * multiplier;
}

@end

@implementation NSWindow (PecuniaAdditions)

- (ZoomWindow*)createZoomWindowWithRect: (NSRect)rect
{
    // Code mostly from http://www.noodlesoft.com/blog/2007/06/30/animation-in-the-time-of-tiger-part-1/
    // Copyright 2007 Noodlesoft, L.L.C.. All rights reserved.
    // The code is provided under the MIT license.
    
    // The code has been extended to support layer-backed views. However, only the top view is
    // considered here. The code might not produce the desired output if only a subview has its layer
    // set. So better set it on the top view (which should cover most cases).
    
    NSImageView *imageView;
    NSImage *image;
    NSRect frame;
    BOOL isOneShot;
    
    frame = [self frame];

    isOneShot = [self isOneShot];
	if (isOneShot) {
		[self setOneShot: NO];
	}
    
    BOOL hasLayer = [[self contentView] wantsLayer];
	if ([self windowNumber] <= 0) // <= 0 if hidden
	{
        // We need to temporarily switch off the backing layer of the content view or we get
        // context errors on the second or following runs of this code.
        [[self contentView] setWantsLayer: NO];

        // Force window device. Kinda crufty but I don't see a visible flash
		// when doing this. May be a timing thing wrt the vertical refresh.
        [self orderBack: self];
        [self orderOut: self];
        
        [[self contentView] setWantsLayer: hasLayer];
	}

    // Capture the window into an off-screen bitmap.
    image = [[NSImage alloc] initWithSize: frame.size];
    [[self contentView] lockFocus];
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0.0, 0.0, frame.size.width, frame.size.height)];
    [[self contentView] unlockFocus];
    [image addRepresentation: rep];
    [rep release];

    // If the content view is layer-backed the above initWithFocusedViewRect call won't get the content
    // of the view (seems it doesn't work for CALayers). So we need a second call that captures the
    // CALayer content and copies it over the captured image (compositing so the window frame and its content).
    if (hasLayer)
    {
        NSRect contentFrame = [[self contentView] bounds];
        int bitmapBytesPerRow = 4 * contentFrame.size.width;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGContextRef context = CGBitmapContextCreate (NULL,
                                                      contentFrame.size.width,
                                                      contentFrame.size.height,
                                                      8,
                                                      bitmapBytesPerRow,
                                                      colorSpace,
                                                      kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        
        [[[self contentView] layer] renderInContext: context];
        CGImageRef img = CGBitmapContextCreateImage(context);
        NSImage *subImage = [[NSImage alloc] initWithCGImage: img size: contentFrame.size];
        [image lockFocus];
        [subImage drawAtPoint: NSMakePoint(0, 0)
                     fromRect: NSMakeRect(0, 0, contentFrame.size.width, contentFrame.size.height)
                    operation: NSCompositeCopy
                     fraction: 1];
        [image unlockFocus];
        [subImage release];
    }
    
    ZoomWindow *zoomWindow = [[ZoomWindow alloc] initWithContentRect: rect
                                                           styleMask: NSBorderlessWindowMask
                                                             backing: NSBackingStoreBuffered
                                                               defer: NO];
    zoomWindow.animationTimeMultiplier = 0.3;
    [zoomWindow setBackgroundColor: [NSColor colorWithDeviceWhite: 0.0 alpha: 0.0]];
    [zoomWindow setHasShadow: [self hasShadow]];
	[zoomWindow setLevel: [self level]];
    [zoomWindow setOpaque: NO];
    [zoomWindow setReleasedWhenClosed: YES];
    [zoomWindow useOptimizedDrawing: YES];
    
    imageView = [[NSImageView alloc] initWithFrame: [zoomWindow contentRectForFrameRect: frame]];
    [imageView setImage: image];
    [imageView setImageFrameStyle: NSImageFrameNone];
    [imageView setImageScaling: NSScaleToFit];
    [imageView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    
    [zoomWindow setContentView: imageView];
    [image release];	
    [imageView release];
    
    [self setOneShot: isOneShot];
    
    return zoomWindow;
}

- (void)fadeIn
{
    [self setAlphaValue: 0.f];
    [self orderFront: nil];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration: 0.25];
    [[self animator] setAlphaValue: 1.f];
    [NSAnimationContext endGrouping];
}

- (void)zoomInFromRect: (NSRect)startRect withFade: (BOOL)fade makeKey: (BOOL)makeKey
{
    if ([self isVisible]) {
        return;
    }
    
    [self setAlphaValue: 1];
    NSRect frame = [self frame];
    NSRect overshotFrame = NSInsetRect(frame, -0.07 * frame.size.width, -0.07 * frame.size.height);
    ZoomWindow *zoomWindow = [self createZoomWindowWithRect: startRect];
    
    [zoomWindow orderFront: self];
    
    zoomWindow.animationTimeMultiplier = 0.35;
    [zoomWindow setFrame: overshotFrame display: YES animate: YES];
    zoomWindow.animationTimeMultiplier = 0.25;
    [zoomWindow setFrame: frame display: YES animate: YES];
    
    if (makeKey) {
        [self makeKeyAndOrderFront: self];
    } else {
        [self orderFront: self];
    }
    [zoomWindow close];
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

- (void)zoomOffToRect: (NSRect)endRect withFade: (BOOL)fade
{
    if (![self isVisible]) {
        return;
    }
    
    NSRect frame = [self frame];
    ZoomWindow *zoomWindow = [self createZoomWindowWithRect: frame];
    zoomWindow.animationTimeMultiplier = 0.35;
	[zoomWindow orderFront: self];
    [self orderOut: self];

    NSDictionary *fadeWindow = nil;
    if (fade) {
        fadeWindow = [NSDictionary dictionaryWithObjectsAndKeys:
                      zoomWindow, NSViewAnimationTargetKey,
                      NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
                      nil];
    }
    
    NSDictionary *resizeWindow = [NSDictionary dictionaryWithObjectsAndKeys:
                                  zoomWindow, NSViewAnimationTargetKey,
                                  [NSValue valueWithRect: endRect], NSViewAnimationEndFrameKey,
                                  nil];
    
    NSArray *animations;
    animations = [NSArray arrayWithObjects: resizeWindow, fadeWindow, nil];
    
    NSViewAnimation *animation;
    animation = [[NSViewAnimation alloc] initWithViewAnimations: animations];
    
    [animation setAnimationBlockingMode: NSAnimationBlocking];
    [animation setDuration: [zoomWindow animationResizeTime: endRect]];
    
    [animation startAnimation];
    
    [animation release];
    
	[zoomWindow close];
}

/**
 * Shakes the receiver left-right with the given values. Good values are:
 * number of shakes: 4
 * duration: 0.1
 * vigour: 0.02
 */
- (void)shakeItWithDuration: (float)duration count: (int)numberOfShakes vigour: (float)vigourOfShake
{
    NSRect frame = [self frame];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath: @"frame"];
    
    NSRect rect1 = NSMakeRect(NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame), frame.size.width, frame.size.height);
    NSRect rect2 = NSMakeRect(NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame), frame.size.width, frame.size.height);
    NSArray *array = [NSArray arrayWithObjects: [NSValue valueWithRect: rect1], [NSValue valueWithRect: rect2], nil];
    [animation setValues: array];
    
    [animation setDuration: duration];
    [animation setRepeatCount: numberOfShakes];
    
    [self setAnimations: [NSDictionary dictionaryWithObject: animation forKey: @"frame"]];
    [[self animator] setFrame: frame display: NO];
}

@end

//--------------------------------------------------------------------------------------------------

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

//--------------------------------------------------------------------------------------------------

@implementation CorePlotXYRangeAnimation

@synthesize targetPosition;
@synthesize targetLength;

- (id)initWithDuration: (NSTimeInterval)duration
        animationCurve: (NSAnimationCurve)animationCurve
             plotSpace: (CPTXYPlotSpace*)theSpace
                  axis: (CPTXYAxis*)theAxis
             forXRange: (bool)forXRange
{
    self = [super initWithDuration: duration animationCurve: animationCurve];
    if (self != nil) {
        plotSpace = theSpace;
        axis = theAxis;
        useXRange = forXRange; // False for yRange.
        
        if (useXRange) {
            startPosition = plotSpace.xRange.locationDouble;
            startLength = plotSpace.xRange.lengthDouble;
        } else {
            startPosition = plotSpace.yRange.locationDouble;
            startLength = plotSpace.yRange.lengthDouble;
        }

    }
    return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    if (startPosition == targetPosition && startLength == targetLength) {
        [self stopAnimation];
        return;
    }
    
    [super setCurrentProgress: progress];
    float value = [self currentValue];
    
    double newPosition = startPosition * (1 - value) + targetPosition * value;
    double newLength = startLength * (1 - value) + targetLength * value;
    CPTPlotRange* plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(newPosition)
                                                           length: CPTDecimalFromDouble(newLength)];

    if (useXRange) {
        // First check the global range if the new local range would exceed it. Without adjusting the
        // global range the new local range has no effect (in certain circumstances).
        double newGlobalPosition = newPosition;
        if (plotSpace.globalXRange.locationDouble < newGlobalPosition) {
            newGlobalPosition = plotSpace.globalXRange.locationDouble;
        }
        double newGlobalLength = newLength;
        if (plotSpace.globalXRange.lengthDouble > newGlobalLength) {
            newGlobalLength = plotSpace.globalXRange.lengthDouble;
        }
        CPTPlotRange* globalRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(newGlobalPosition)
                                                                 length: CPTDecimalFromDouble(newGlobalLength)];
        plotSpace.globalXRange = globalRange;
        plotSpace.xRange = plotRange;
    } else {
        double newGlobalPosition = newPosition;
        if (plotSpace.globalYRange.locationDouble < newGlobalPosition) {
            newGlobalPosition = plotSpace.globalYRange.locationDouble;
        }
        double newGlobalLength = newLength;
        if (plotSpace.globalYRange.lengthDouble > newGlobalLength) {
            newGlobalLength = plotSpace.globalYRange.lengthDouble;
        }
        CPTPlotRange* globalRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromDouble(newGlobalPosition)
                                                                 length: CPTDecimalFromDouble(newGlobalLength)];
        plotSpace.globalYRange = globalRange;
        plotSpace.yRange = plotRange;
    }

    if (axis != nil) {
        axis.visibleRange = plotRange;
    }
}

@end



