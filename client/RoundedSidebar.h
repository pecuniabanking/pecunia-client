//
//  RoundedSidebar.h
//  Pecunia
//
//  Created by Mike on 28.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Background graphic elements, used in all sidebars.
static NSShadow* borderShadow = nil;
static NSGradient* backgroundGradient = nil;
static NSGradient* insetGradient = nil;

// Inset graphic elements, used in all sidebars.
static NSColor* strokeColor = nil;
static NSShadow* innerShadow1 = nil;
static NSShadow* innerShadow2 = nil;
	
@interface RoundedSidebar : NSView {

}

@end
