//
//  SideMenuView.h
//  Pecunia
//
//  Created by Mike Lischke on 04.12.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * Provides the visual shape and behavior of the side menu, a small vertically oriented
 * view carrying a number of buttons to trigger actions. The side menu is mostly hidden and
 * slides in when the mouse is over it. When the mouse leaves the view slides back taking so up
 * as few space as possible when not used.
 */
@interface SideToolbarView : NSView {
    NSTrackingArea* trackingArea;
}

- (void)slideOut;
- (void)slideIn;

@end
