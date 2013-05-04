//
//  MCEMBorderedView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 02.08.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "MCEMBorderedView.h"


@implementation MCEMBorderedView

- (void)drawRect: (NSRect)rect
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect: [self bounds]];

    NSGradient *aGradient = [[NSGradient alloc]
                             initWithColorsAndLocations: [NSColor colorWithDeviceHue: 0.589 saturation: 0.068 brightness: 0.9 alpha: 1.0], (CGFloat) - 0.1, [NSColor whiteColor], (CGFloat)1.1,
                             nil];

    [aGradient drawInBezierPath: path angle: 90.0];

    [[NSColor colorWithDeviceRed: 0.745 green: 0.745 blue: 0.745 alpha: 1.0] setStroke];
    [NSBezierPath setDefaultLineWidth: 2.0];
    [NSBezierPath strokeRect: [self bounds]];
}

@end
