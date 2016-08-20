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

#import "SystemNotification.h"
#import "NSImage+PecuniaAdditions.h"

@implementation ComTraceHelper

- (id)initWithFrame: (NSRect)frame {
    self = [super initWithFrame: frame];
    if (self != nil) {
    }
    return self;
}

- (void)awakeFromNib {
    magnifyButton.toolTip = NSLocalizedString(@"AP125", nil);
}

- (void)viewDidChangeBackingProperties {
    if (MessageLog.log.isComTraceActive) {
        // Recreate the animation if it is currently running to use hidpi images.
        [magnifyButton.layer removeAllAnimations];
        [self startMagnifyAnimation];
    }
}

- (void)startMagnifyAnimation {
    NSMutableArray *images = [NSMutableArray array];
    [images addObject: [NSImage imageNamed: @"magnify"]];
    [images addObject: [NSImage imageNamed: @"magnify-busy1"]];
    [images addObject: [NSImage imageNamed: @"magnify-busy2"]];
    [images addObject: [NSImage imageNamed: @"magnify-busy3"]];


    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath: @"contents"];
    [animation setCalculationMode: kCAAnimationDiscrete];
    [animation setDuration: 3.0f];
    [animation setRepeatCount: 100000000];
    [animation setValues: images];

    CGFloat contentsScale = NSScreen.mainScreen.backingScaleFactor;
    magnifyButton.layer.contentsScale = contentsScale;

    // Need to set the size here, not upfront.
    NSSize size = [(NSImage *)images[0] size];
    magnifyButton.layer.frame = NSMakeRect(1, 0, size.width, size.height);

    magnifyButton.image = nil;
    [magnifyButton.layer addAnimation: animation forKey: @"contents"];
}

- (IBAction)toggleComTrace: (id)sender {
    if (MessageLog.log.isComTraceActive) {
        [magnifyButton.layer removeAllAnimations];
        magnifyButton.layer.frame = magnifyButton.frame;
        magnifyButton.image = [NSImage imageNamed: @"magnify"];
        magnifyButton.toolTip = NSLocalizedString(@"AP125", nil);

        [MessageLog.log sendLog];
        MessageLog.log.isComTraceActive = NO; // Must happen *after* sendLog, as it deletes the com trace file.

        [SystemNotification showMessage: NSLocalizedString(@"AP505", nil)
                              withTitle: NSLocalizedString(@"AP503", nil)];
    } else {
        // Data Privacy Check
        int res = NSRunCriticalAlertPanel(NSLocalizedString(@"AP1027", @""),
                                          NSLocalizedString(@"AP1028", @""),
                                          NSLocalizedString(@"AP2", @""),
                                          NSLocalizedString(@"AP36", @""),
                                          nil);
        if (res == NSAlertDefaultReturn) {
            return;
        }
        
        magnifyButton.toolTip = NSLocalizedString(@"AP126", nil);
        MessageLog.log.isComTraceActive = YES;
        [self startMagnifyAnimation];

        [SystemNotification showMessage: NSLocalizedString(@"AP504", nil)
                              withTitle: NSLocalizedString(@"AP503", nil)];
    }
}

@end
