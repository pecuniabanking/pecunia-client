//
//  StatusBarController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 08.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "StatusBarController.h"

static StatusBarController *controller = nil;

@implementation StatusBarController

-(void)awakeFromNib
{
	controller = self;
}

-(void)startSpinning
{
	[progressIndicator setHidden: NO ];
	[progressIndicator setUsesThreadedAnimation: YES];
	[progressIndicator startAnimation: self];
}

-(void)stopSpinning
{
	[progressIndicator stopAnimation: self ];
	[progressIndicator setHidden: YES ];
}

-(void)setMessage: (NSString*)message removeAfter: (int)secs
{
	if(timer) {
		[timer invalidate ];
		[timer release ];
	}
	
	[messageField setStringValue: message ];

	if(secs > 0) {
		NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow: secs ];
		NSTimer *ltimer = [[NSTimer alloc ] initWithFireDate:endDate 
											  	    interval:0.0 
													  target:self 
												    selector:@selector(clearMessage) 
												    userInfo:nil 
													 repeats:NO];
		[[NSRunLoop currentRunLoop ] addTimer:ltimer forMode:NSDefaultRunLoopMode ];
		timer = [ltimer retain ];
	}
}

-(void)clearMessage
{
	[messageField setStringValue: @"" ];
}

+(StatusBarController*)controller
{
	return controller;
}


@end
