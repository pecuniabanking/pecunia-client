//
//  TanMethod.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "aqhbci/tanmethod.h"

@interface TanMethod : NSObject {
	NSString	*function;
	NSString	*description;
}

//-(id)initWithAB: (const AH_TAN_METHOD*)tm;
-(id)initDefault: (int)func;
-(id)initWithString:(NSString*)s;


@property (copy) NSString	*function;
@property (copy) NSString	*description;

@end
