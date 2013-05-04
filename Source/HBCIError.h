//
//  HBCIError.h
//  Client
//
//  Created by Frank Emminghaus on 23.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PecuniaError;

@interface HBCIError : NSObject {
    NSString *msg;
    NSString *code;
}

@property (copy) NSString *msg;
@property (copy) NSString *code;

- (PecuniaError *)toPecuniaError;


@end
