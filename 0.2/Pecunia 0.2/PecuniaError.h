//
//  PecuniaError.h
//  Pecunia
//
//  Created by Frank Emminghaus on 15.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PecuniaError : NSError {

}

+(NSError*)errorWithText: (NSString*)msg;

@end
