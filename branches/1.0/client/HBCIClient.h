//
//  HBCIClient.h
//  Pecunia
//
//  Created by Frank Emminghaus on 25.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#define HBCI4JAVA

#import <Cocoa/Cocoa.h>
#import "Transfer.h"
#import "StandingOrder.h"
#import "MessageLog.h"
#import "HBCIBackend.h"
#import "HBCIController.h"

@interface HBCIClient : NSObject <HBCIBackend> {
	id<HBCIBackend> controller;
}

+(HBCIClient*)hbciClient;

@end
