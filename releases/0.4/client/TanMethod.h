//
//  TanMethod.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TanMethod : NSObject {
	NSNumber	*function;
	NSString	*description;
}

-(id)initDefault: (NSNumber*) func;

@property (nonatomic, retain) NSNumber* function;
@property (nonatomic, retain) NSString* description;

@end
