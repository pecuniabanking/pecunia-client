//
//  CategoryPeriodsView.m
//  Pecunia
//
//  Created by Frank Emminghaus on 16.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "CategoryPeriodsView.h"


@implementation CategoryPeriodsView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	[super drawBackgroundInClipRect:clipRect ];
	NSRect columnRect = NSIntersectionRect(clipRect, [self rectOfColumn:0 ]);
	[[NSColor colorWithDeviceRed: 0.867 green: 0.894 blue: 0.918 alpha: 1.0 ] setFill ];
	[NSBezierPath fillRect:columnRect ];
}

@end
