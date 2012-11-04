//
//  TanMethodOld.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TanMethodOld : NSObject {
    NSNumber    *function;
    NSString    *description;

}

@property (nonatomic, strong) NSNumber *function;
@property (nonatomic, copy) NSString *description;

-(id)initDefault: (NSNumber*) func;

@end

