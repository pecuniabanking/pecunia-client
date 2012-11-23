/**
 * Copyright (c) 2009, 2012, Pecunia Project. All rights reserved.
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

#import "StatusBarController.h"
#import "GrowlNotification.h"

static StatusBarController *controller = nil;

@implementation StatusBarController

- (void)awakeFromNib
{
	controller = self;
}

- (void)startSpinning
{
	[progressIndicator setHidden: NO];
	[progressIndicator setUsesThreadedAnimation: YES];
	[progressIndicator startAnimation: self];
}

-( void)stopSpinning
{
	[progressIndicator stopAnimation: self];
	[progressIndicator setHidden: YES];
}

- (void)setMessage: (NSString*)message removeAfter: (int)secs
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];

    [GrowlNotification showMessage: message withTitle: nil context: @"status"];
	[messageField setStringValue: message];

    [self performSelector: @selector(clearMessage) withObject: nil afterDelay: secs];
}

- (void)clearMessage
{
	[messageField setStringValue: @"" ];
}

+ (StatusBarController*)controller
{
	return controller;
}


@end
