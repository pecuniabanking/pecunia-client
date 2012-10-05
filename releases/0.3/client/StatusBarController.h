//
//  StatusBarController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 08.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusBarController : NSObject {
	
	IBOutlet NSProgressIndicator	*progressIndicator;
	IBOutlet NSTextField			*messageField;

}

+(StatusBarController*)controller;

-(void)startSpinning;
-(void)stopSpinning;
-(void)setMessage: (NSString*)message removeAfter: (int)secs;
-(void)clearMessage;


@end
