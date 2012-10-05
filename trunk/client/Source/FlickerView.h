//
//  FlickerView.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FlickerView : NSView {
	char code;
	int size;
}

@property (nonatomic, assign) int size;
@property (nonatomic, assign) char code;

@end


