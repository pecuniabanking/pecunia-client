//
//  TransferResult.h
//  Pecunia
//
//  Created by Frank Emminghaus on 16.02.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TransferResult : NSObject {
	NSString	*transferId;
	BOOL		isOk;
}

@property (copy) NSString *transferId;
@property (assign) BOOL isOk;



@end
