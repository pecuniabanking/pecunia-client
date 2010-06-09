//
//  HDIWrapper.m
//  Pecunia
//
//  Created by Frank Emminghaus on 11.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "HDIWrapper.h"

static HDIWrapper *_wrapper = nil;

@implementation HDIWrapper

-(void)waitForCompletion
{
	// loop until we are done receiving the data
	if (!done)
	{
		double resolution = 1;
		BOOL isRunning;
		NSDate* next;
		
		do {
			next = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
			
			isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:next];
		} while (isRunning && !done);
	}
}

-(BOOL)createImage: (NSString*)path withPassword: (NSString*)pwd strongEncryption: (BOOL)encr
{
	NSMutableArray *arguments = [NSMutableArray arrayWithArray: [@"/usr/bin/hdiutil create -type SPARSE -encryption -size 100m -fs HFS+J -layout NONE -volname PecuniaData" componentsSeparatedByString:@" "] ];
	if(encr) [arguments insertObject: @"AES-256" atIndex:5 ]; else [arguments insertObject: @"AES-128" atIndex:5 ];
	[arguments addObject: path ];
	[wrapper release ];
	wrapper = [[AMShellWrapper alloc ] initWithController: self 
												inputPipe:nil
											   outputPipe:nil
												errorPipe:nil
										 workingDirectory:@"."
											  environment:nil
												arguments: arguments ];
	NSString *input = [pwd stringByAppendingString: @"\n" ];
	input = [input stringByAppendingString: pwd ];
	input = [input stringByAppendingString: @"\n" ];
	done = NO;
	hasError = NO;
	if(errorMessage) { [errorMessage release ]; errorMessage = nil; }
	if(output) { [output release ]; output = nil; }
	if(wrapper) [wrapper startProcess ];
	else {
		NSLog(@"hdiutil create could not be started");
		return NO;
	}
	[wrapper appendInput: input ];
	[self waitForCompletion ];
	
	if(hasError) return NO; else return YES;
}

-(BOOL)attachImage: (NSString*)path withPassword: (NSString*)pwd browsable:(BOOL)browsable
{
	NSMutableArray *arguments = [NSMutableArray arrayWithArray: [@"/usr/bin/hdiutil attach" componentsSeparatedByString:@" "] ];
	[arguments addObject: path ];
	if(!browsable) [arguments insertObject: @"-nobrowse" atIndex: 2 ];
	
	[wrapper release ];
	wrapper = [[AMShellWrapper alloc ] initWithController: self 
												inputPipe:nil
											   outputPipe:nil
												errorPipe:nil
										 workingDirectory:@"."
											  environment:nil
												arguments: arguments ];
	
	NSString *input = [pwd stringByAppendingString: @"\n" ];
	done = NO;
	hasError = NO;
	attached = NO;
	if(errorMessage) { [errorMessage release ]; errorMessage = nil; }
	if(output) { [output release ]; output = nil; }
	if(wrapper) [wrapper startProcess ];
	else {
		NSLog(@"hdiutil attach could not be started");
		return NO;
	}
	[wrapper appendInput: input ];
	[self waitForCompletion ];
	
	if(!hasError) {
		NSRange r = [output rangeOfString: @"/Volumes" ];
		[volumePath release ];
		volumePath = [output substringFromIndex: r.location ];
		[volumePath retain ];
		attached = YES;
		return YES;
	}
	return NO;
}

-(BOOL)detachImage
{
	if(attached == NO) return YES;
	NSMutableArray *arguments = [NSMutableArray arrayWithArray: [@"/usr/bin/hdiutil detach -force" componentsSeparatedByString:@" "] ];
	[arguments addObject: volumePath ];
	
	[wrapper release ];
	wrapper = [[AMShellWrapper alloc ] initWithController: self 
												inputPipe:nil
											   outputPipe:nil
												errorPipe:nil
										 workingDirectory:@"."
											  environment:nil
												arguments: arguments ];
	
	done = NO;
	hasError = NO;
	if(errorMessage) { [errorMessage release ]; errorMessage = nil; }
	if(output) { [output release ]; output = nil; }
	if(wrapper) [wrapper startProcess ];
	else {
		NSLog(@"hdiutil detach could not be started");
		return NO;
	}
//	[self waitForCompletion ];
	
//	if(!hasError) return YES; else return NO;
	attached = NO;
	return YES;
	
}

-(NSString*)volumePath
{
	return volumePath;
}

-(NSString*)errorMessage
{
	return errorMessage;
}



-(void)dealloc
{
	[super dealloc ];
	[wrapper release ];
	[volumePath release ];
	[output release ];
	[errorMessage release ];
	[super dealloc ];
}

+(HDIWrapper*)wrapper
{
	if(_wrapper == nil) _wrapper = [[HDIWrapper alloc ] init ];
	return _wrapper;
}


// Protocol methods

- (void)appendOutput:(NSString *)outp;
// output from stdout
{
	NSLog(outp);
	NSString *s = [outp stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet ] ];
	if(output) {
		[output autorelease ];
		output = [[output stringByAppendingString: s ] retain ];
	} else output = [s retain ];
}

- (void)appendError:(NSString *)error
{
// output from stderr
	NSLog(error);
	NSString *err = [error stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet ] ];
	if(errorMessage) {
		[errorMessage autorelease ];
		errorMessage = [[errorMessage stringByAppendingString: err ] retain ];
	} else errorMessage = [err retain ];
	hasError = YES;
}

- (void)processStarted:(id)sender
// This method is a callback which your controller can use to do other initialization
// when a process is launched.
{
}

- (void)processFinished:(id)sender withTerminationStatus:(int)resultCode
{
	// This method is a callback which your controller can use to do other cleanup
	// when a process is halted.
	done = YES;
}

@end
