//
//  HDIWrapper.h
//  Pecunia
//
//  Created by Frank Emminghaus on 11.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMShellWrapper.h"


@interface HDIWrapper : NSObject <AMShellWrapperController> {
	AMShellWrapper	*wrapper;
	BOOL			done;
	BOOL			hasError;
	BOOL            attached;
	NSString		*volumePath;
	NSString		*output;
	NSString		*errorMessage;
}

-(BOOL)createImage: (NSString*)path withPassword: (NSString*)pwd strongEncryption: (BOOL)encr;
-(BOOL)attachImage: (NSString*)path withPassword: (NSString*)pwd browsable:(BOOL)browsable;
-(BOOL)detachImage;

-(NSString*)volumePath;
-(NSString*)errorMessage;

+(HDIWrapper*)wrapper;

// Protocol methods

- (void)appendOutput:(NSString *)outp;
// output from stdout

- (void)appendError:(NSString *)error;
// output from stderr

- (void)processStarted:(id)sender;
// This method is a callback which your controller can use to do other initialization
// when a process is launched.

- (void)processFinished:(id)sender withTerminationStatus:(int)resultCode;
// This method is a callback which your controller can use to do other cleanup
// when a process is halted.

@end

//hdiutil create -type SPARSE -encryption AES-256 -size 100m -fs HFS+J PecuniaData