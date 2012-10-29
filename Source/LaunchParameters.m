//
//  LaunchParameters.m
//  Pecunia
//
//  Created by Frank Emminghaus on 20.01.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import "LaunchParameters.h"

static NSString *extensionPackage = @".pecuniadata";

@implementation LaunchParameters

@synthesize dataFile;
@synthesize debugServer;

static LaunchParameters *parameters = nil;

- (void)parseParameters
{
    // customize data file name
    BOOL altFile = NO;
    NSArray *args=[[NSProcessInfo processInfo] arguments];
    for(NSString *s in args) {
        if ([s hasPrefix:@"-f" ]) {
            altFile = YES;
            NSString *name = [s substringFromIndex:2 ];
            if (name == nil || [name length ] == 0) continue;
            else {
                self.dataFile = [name stringByAppendingString:extensionPackage];
                altFile = NO;
            }
        }
        if (altFile) {
            altFile = NO;
            if (s == nil || [s length ] == 0) continue;
            self.dataFile = [s stringByAppendingString:extensionPackage];
        }
        
        if ([s isEqualToString: @"-dServer" ]) {
            debugServer = YES;
        }
    }
}

+(LaunchParameters*)parameters
{
    if (parameters == nil) {
        parameters = [[LaunchParameters alloc ] init ];
    }
    return parameters;
}


- (id)init
{
    self = [super init ];
    if (self == nil) return nil;
    [self parseParameters ];
    parameters = self;
    return self;
}

- (void)dealloc
{
	[dataFile release], dataFile = nil;

	[super dealloc];
}

@end

