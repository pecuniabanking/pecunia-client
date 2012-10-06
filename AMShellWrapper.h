//
//  AMShellWrapper.h
//  CommX
//
//  Created by Andreas on 2002-04-24.
//  Based on TaskWrapper from Apple
//
//  2002-06-17 Andreas Mayer
//  - used defines for keys in AMShellWrapperProcessFinishedNotification userInfo dictionary
//  2002-08-30 Andreas Mayer
//  - added setInputStringEncoding: and setOutputStringEncoding:

#import <Foundation/Foundation.h>

#define AMShellWrapperProcessFinishedNotification @"AMShellWrapperProcessFinishedNotification"
#define AMShellWrapperProcessFinishedNotificationTaskKey @"AMShellWrapperProcessFinishedNotificationTaskKey"
#define AMShellWrapperProcessFinishedNotificationTerminationStatusKey @"AMShellWrapperProcessFinishedNotificationTerminationStatusKey"


@protocol AMShellWrapperController
// implement this protocol to control your AMShellWrapper object:

- (void)appendOutput:(NSString *)output;
// output from stdout

- (void)appendError:(NSString *)error;
// output from stderr

- (void)processStarted:(id)sender;
// This method is a callback which your controller can use to do other initialization
// when a process is launched.

- (void)processFinished:(id)sender withTerminationStatus:(int)resultCode;
// This method is a callback which your controller can use to do other cleanup
// when a process is halted.

// AMShellWrapper posts a AMShellWrapperProcessFinishedNotification when a process finished.
// The userInfo of the notification contains the corresponding NSTask ((NSTask *), key @"task")
// and the result code ((NSNumber *), key @"resultCode")
// ! notification removed since it prevented the task from getting deallocated

@end


@interface AMShellWrapper : NSObject {
	NSTask *task;
	id <AMShellWrapperController>controller;
	NSString *workingDirectory;
	NSDictionary *environment;
	NSArray *arguments;
	id stdinPipe;
	id stdoutPipe;
	id stderrPipe;
	NSFileHandle *stdinHandle;
	NSFileHandle	 *stdoutHandle;
	NSFileHandle	 *stderrHandle;
	NSStringEncoding inputStringEncoding;
	NSStringEncoding outputStringEncoding;
	BOOL stdoutEmpty;
	BOOL stderrEmpty;
	BOOL taskDidTerminate;
}

- (id)initWithController:(id <AMShellWrapperController>)controller inputPipe:(id)input outputPipe:(id)output errorPipe:(id)error workingDirectory:(NSString *)directoryPath environment:(NSDictionary *)env arguments:(NSArray *)args;
// This is the designated initializer - pass in your controller and any task arguments.
// The first argument should be the path to the executable to launch with the NSTask.
// Allowed for stdin/stdout and stderr are
// - values of type NSFileHandle or
// - NSPipe or
// - nil, in which case this wrapper class automatically connects to the callbacks
//   and appendInput: method and provides asynchronous feedback notifications.
// The environment argument may be nil in which case the environment is inherited from
// the calling process.

- (void)setInputStringEncoding:(NSStringEncoding)newInputStringEncoding;
// If you need something else than UTF8, set the encoding type of the task's input here

- (void)setOutputStringEncoding:(NSStringEncoding)newOutputStringEncoding;
// If you need something else than UTF8, tell the task what encoding to use for output here

- (void)startProcess;
// This method launches the process, setting up asynchronous feedback notifications.

- (void)stopProcess;
// This method stops the process, stoping asynchronous feedback notifications.

- (void)appendInput:(NSString *)input;
// input to stdin


@end
