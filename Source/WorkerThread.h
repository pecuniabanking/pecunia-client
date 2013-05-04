//
//  WorkerThread.h
//  Pecunia
//
//  Created by Frank Emminghaus on 01.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WorkerThread : NSObject {
}

+ (void)init;
+ (NSThread *)thread;
+ (void)finish;

@end
