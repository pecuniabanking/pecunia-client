//
//  FlickerView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 05.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "FlickerView.h"



@implementation FlickerView

@synthesize size;
@synthesize code;

- (id)initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        // Initialization code here.
        code = 0;
        size = 45;
    }
    return self;
}

- (void)drawRect: (NSRect)dirtyRect
{
    NSRect r;
    int    i;
    int    anchor;

    NSRect bounds = [self bounds];
    int    flickerSize = size * 5 + 20;

    r.origin = NSMakePoint((bounds.size.width - flickerSize) / 2, 0);
    r.size = NSMakeSize(size, 60);

    [[NSColor blackColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    anchor = r.origin.x + size / 2;
    [path moveToPoint: NSMakePoint(anchor, 62)];
    [path lineToPoint: NSMakePoint(anchor + 10, 80)];
    [path lineToPoint: NSMakePoint(anchor - 10, 80)];
    [path closePath];
    [path fill];

    path = [NSBezierPath bezierPath];
    anchor += 4 * size + 20;
    [path moveToPoint: NSMakePoint(anchor, 62)];
    [path lineToPoint: NSMakePoint(anchor + 10, 80)];
    [path lineToPoint: NSMakePoint(anchor - 10, 80)];
    [path closePath];
    [path fill];

    char mask = 1;
    for (i = 0; i < 5; i++) {
        if (code & mask) {
            [[NSColor whiteColor] setFill];
        } else {
            [[NSColor blackColor] setFill];
        }

        [NSBezierPath fillRect: r];
        r.origin.x += size + 5;
        mask = mask << 1;

    }
}

@end
