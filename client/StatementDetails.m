//
//  StatementDetails.m
//  Pecunia
//
//  Created by Frank Emminghaus on 16.11.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "StatementDetails.h"


@implementation StatementDetails

-(void)drawRect: (NSRect)rect
{
	[[NSColor colorWithDeviceHue: 0.589 saturation: 0.068 brightness: 0.9 alpha: 1.0] setFill ];
//	[[NSColor whiteColor ] setFill ];
	[[NSColor colorWithDeviceRed: 0.745 green: 0.745 blue: 0.745 alpha: 1.0 ] setStroke ];
	[NSBezierPath setDefaultLineWidth:2.0];
	NSRectFill([self bounds ]);
	[NSBezierPath strokeRect: [self bounds ] ];
}

@end
