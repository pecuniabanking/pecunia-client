//
//  LaunchParameters.h
//  Pecunia
//
//  Created by Frank Emminghaus on 20.01.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LaunchParameters : NSObject {
    NSString    *dataFile;
    BOOL        debugServer;
}

@property (nonatomic, copy) NSString *dataFile;
@property (nonatomic, assign) BOOL debugServer;

+(LaunchParameters*) parameters;

@end

