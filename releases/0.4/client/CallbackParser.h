//
//  CallbackParser.h
//  Client
//
//  Created by Frank Emminghaus on 14.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HBCIBridge;
@class CallbackData;

@interface CallbackParser : NSObject {
	NSMutableString *currentValue;
	HBCIBridge		*parent;
	CallbackData    *data;
}

-(id)initWithParent: (HBCIBridge*)par command:(NSString*)cmd;


@end
