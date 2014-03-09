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

#import <Quartz/Quartz.h>

#import "ComTraceHelper.h"
#import "MessageLog.h"

#import "NSImage+PecuniaAdditions.h"

@implementation ComTraceHelper

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
    }
    return self;
}

- (void)awakeFromNib
{
    magnifyButton.toolTip = NSLocalizedString(@"AP125", nil);
}

- (void)viewDidChangeBackingProperties
{
    if (MessageLog.log.isComTraceActive) {
        // Recreate the animation if it is currently running to use hidpi images.
        [magnifyButton.layer removeAllAnimations];
        [self startMagnifyAnimation];
    }
}

- (void)startMagnifyAnimation
{
    magnifyButton.wantsLayer = YES;

    NSMutableArray *images = [NSMutableArray array];
    [images addObject: [NSImage imageNamed: @"magnify"]];
    [images addObject: [NSImage imageNamed: @"magnify-busy1"]];
    [images addObject: [NSImage imageNamed: @"magnify-busy2"]];
    [images addObject: [NSImage imageNamed: @"magnify-busy3"]];


    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath: @"contents"];
    [animation setCalculationMode: kCAAnimationDiscrete];
    [animation setDuration: 4.0f];
    [animation setRepeatCount: 100000000];
    [animation setValues: images];

    CGFloat contentsScale = NSScreen.mainScreen.backingScaleFactor;
    magnifyButton.layer.contentsScale = contentsScale;

    NSSize size = [images[0] size];
    NSRect bounds = NSMakeRect(0, 0, size.width, size.height);
    magnifyButton.layer.bounds = bounds;

    magnifyButton.layer.position = (contentsScale > 1) ? NSMakePoint(2.5, 1.5) : NSMakePoint(3, 1);
    magnifyButton.image = nil;
    [magnifyButton.layer addAnimation: animation forKey: @"contents"];
}

- (IBAction)toggleComTrace: (id)sender
{
    if (MessageLog.log.isComTraceActive) {
        [magnifyButton.layer removeAllAnimations];
        magnifyButton.layer.bounds = magnifyButton.bounds;
        magnifyButton.layer.position = NSZeroPoint;
        magnifyButton.image = [NSImage imageNamed: @"magnify"];
        magnifyButton.toolTip = NSLocalizedString(@"AP125", nil);

        [MessageLog.log sendLog];
        MessageLog.log.isComTraceActive = NO;

    } else {
        magnifyButton.toolTip = NSLocalizedString(@"AP126", nil);
        MessageLog.log.isComTraceActive = YES;
        [self startMagnifyAnimation];
    }
}

@end
