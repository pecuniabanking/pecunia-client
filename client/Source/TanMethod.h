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
    NSString    *identifier;
    NSString    *process;
    NSString    *zkaMethodName;
    NSString    *zkaMethodVersion;
    NSString    *name;
    NSString    *inputInfo;
    NSNumber    *maxTanLength;
    NSNumber    *needTanMedia;
}

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *process;
@property (nonatomic, copy) NSString *zkaMethodName;
@property (nonatomic, copy) NSString *zkaMethodVersion;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *inputInfo;
@property (nonatomic, retain) NSNumber *maxTanLength;
@property (nonatomic, retain) NSNumber *needTanMedia;
@property (nonatomic, retain) NSNumber* function;
@property (nonatomic, retain) NSString* description;

-(id)initDefault: (NSNumber*) func;

@end

