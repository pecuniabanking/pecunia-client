//
//  AnimationHelper.h
//  Pecunia
//
//  Created by Mike Lischke on 28.11.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import <CorePlot/CorePlot.h>

@interface AnimationHelper : NSObject {
}

+ (void)crossFadeFromView: (NSView*)oldView
                   toView: (NSView*)newView
             withDuration: (float)duration;

+ (void)switchFromView: (NSView*)from
                toView: (NSView*)to
             withSlide: (BOOL)doSlide;

@end

@interface NSWindow (PecuniaAdditions)

- (void)fadeIn;
- (void)zoomInFromRect: (NSRect)startRect withFade: (BOOL)fade makeKey: (BOOL)makeKey;
- (void)fadeOut;
- (void)zoomOffToRect: (NSRect)endRect withFade: (BOOL)fade;

@end

@interface CALayer (PecuniaAdditions)

- (void)fadeIn;
- (void)fadeOut;
- (void)slideTo: (CGPoint)newPosition inTime: (CGFloat)time;

@end

@interface CorePlotXYRangeAnimation : NSAnimation {
    CPTXYPlotSpace* plotSpace; // The plotspace of which we animate the xRange or the yRange.
    CPTXYAxis* axis; // Can be nil.
    
    bool useXRange;
    double startPosition;
    double startLength;
    double targetPosition;
    double targetLength;
}

- (id)initWithDuration: (NSTimeInterval)duration
        animationCurve: (NSAnimationCurve)animationCurve
             plotSpace: (CPTXYPlotSpace*)theSpace
                  axis: (CPTXYAxis*)theAxis
             forXRange: (bool)forXRange;

@property (nonatomic, assign) double targetPosition;
@property (nonatomic, assign) double targetLength;

@end


