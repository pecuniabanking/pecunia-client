//
//  WorkerThread.m
//  Pecunia
//
//  Created by Frank Emminghaus on 01.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "WorkerThread.h"

NSThread *workerThread = nil;

@implementation WorkerThread

+(void)init
{
	if(workerThread) return;
	workerThread = [[NSThread alloc] initWithTarget:self
										   selector:@selector(threadMain:)
											 object:nil];
	[workerThread start ];
}

+(void)threadMain: (id)data
{
	@autoreleasepool {
	
        NSRunLoop *loop = [NSRunLoop currentRunLoop ];
	[loop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
	while(![workerThread isCancelled ]) [loop run ];
	
    }
}

+(NSThread*)thread
{
	return workerThread;
}

+(void)finish
{
	[workerThread cancel ];
}

@end
