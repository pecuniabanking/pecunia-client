//
//  HBCIBridge.m
//  Client
//
//  Created by Frank Emminghaus on 18.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "HBCIBridge.h"
#import "ResultParser.h"
#import "CallbackParser.h"
#import "LogParser.h"
#import "HBCIError.h"
#import "PecuniaError.h"
#import "HBCIBackend.h"
#import "LaunchParameters.h"
#import "CallbackHandler.h"

#import "HBCIController.h" // for -asyncCommandCompletedWithResult

@implementation HBCIBridge

@synthesize callbackHandler;

-(id)init
{
    self = [super init ];
    if(self == nil) return nil;
    running = NO;
	callbackHandler = [[CallbackHandler alloc ] init ];
    
    return self;
}

-(NSPipe*)outPipe
{
    return outPipe;
}

-(void)setResult: (id)res
{
    if([res isKindOfClass: [HBCIError class ] ]) {
        result = nil;
        error = res;
    } else {
        result = res;
        error = nil;
    }
}

-(id)result
{
    return result;
}

-(HBCIError*)error
{
    return error;
}


-(void)startup
{
    task = [[NSTask alloc] init];
    // The output of stdout and stderr is sent to a pipe so that we can catch it later
    // and send it along to the controller; notice that we don't bother to do anything with stdin,
    // so this class isn't as useful for a task that you need to send info to, not just receive.
    inPipe = [NSPipe pipe ];
    outPipe = [NSPipe pipe ];
    [task setStandardOutput: inPipe ];
    [task setStandardInput: outPipe ];
    
    // check if java is present
    if ([[NSFileManager defaultManager ] fileExistsAtPath:@"/usr/bin/java"] == NO) {
        NSRunCriticalAlertPanel(NSLocalizedString(@"AP130", @""), 
                                NSLocalizedString(@"AP131", @""), 
                                NSLocalizedString(@"ok", @""), 
                                nil, 
                                nil);
        [NSApp terminate: self];
    }
    
    [task setLaunchPath: @"/usr/bin/java" ];
    //	[task setEnvironment: [NSDictionary dictionaryWithObjectsAndKeys: @"/users/emmi/workspace/HBCIServer", @"CLASSPATH", nil ] ];
    
    NSString *bundlePath = [[NSBundle mainBundle ] bundlePath ];
    NSString *launchPath = [bundlePath stringByAppendingString:@"/Contents/HBCIServer.jar" ];
    
    if ([LaunchParameters parameters ].debugServer) {
        [task setArguments: [NSArray arrayWithObjects: @"-Xdebug", @"-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005", @"-jar", launchPath, nil ] ];
    } else [task setArguments: [NSArray arrayWithObjects: @"-jar", launchPath, nil ] ];
    
    /*	
     [[NSNotificationCenter defaultCenter] addObserver:self 
     selector:@selector(getData:) 
     name: NSFileHandleReadCompletionNotification 
     object: [[task standardOutput] fileHandleForReading]];
     */	
    //    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    
    // launch the task asynchronously
    [task launch];
    
    if ([LaunchParameters parameters ].debugServer) {
        // consume jvm status message
        [[inPipe fileHandleForReading ] availableData ];
    }
    
    // init 
    //	NSString *cmd = @"<command name=\"init\"><path>/users/emmi/workspace/HBCIServer</path></command>.\n";
    //	[[outPipe fileHandleForWriting ] writeData: [cmd dataUsingEncoding: NSUTF8StringEncoding ] ];
    //	[self receive ];
}



-(void)parse: (NSString*)cmd
{
    //	NSLog(@"String to parse: %@", cmd);
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData: [cmd dataUsingEncoding: NSUTF8StringEncoding ]];
    [parser setDelegate: self];
    [parser setShouldResolveExternalEntities:YES];
    [parser parse];
    [parser release ];
}

- (void)getData: (NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    // If the length of the data is zero, then the task is basically over - there is nothing
    // more to get from the handle so we may as well shut down.
    if ([data length])
    {
        // Send the data on to the controller; we can't just use +stringWithUTF8String: here
        // because -[data bytes] is not necessarily a properly terminated string.
        // -initWithData:encoding: on the other hand checks -[data length]
        NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        // Receive log
        [[MessageLog log ] addMessage:s withLevel:LogLevel_Verbous ];
        
        if(asyncString == nil)  asyncString = [[NSMutableString alloc ] init ];
        if([s hasSuffix: @">." ]) {
            [asyncString appendString: [s substringToIndex: [s length ] -1  ] ];
        } else {
            [asyncString appendString: s ];
            // command is not yet complete: go on
            [[aNotification object] readInBackgroundAndNotify];
            return;
        }
        
        NSRange r = [asyncString rangeOfString: @">\n.<" ];
        NSUInteger offset = 0;
        NSUInteger length = [asyncString length];
        while (r.location != NSNotFound)
        {
            [self parse: [asyncString substringWithRange: NSMakeRange(offset, r.location - offset + 1)]];
            offset = r.location + 3;
            r = [asyncString rangeOfString: @">\n.<" options: 0 range: NSMakeRange(offset, length - offset)];
        }
        
        if (length > offset)
            [self parse: [asyncString substringWithRange: NSMakeRange(offset, length - offset)]];
        [asyncString setString: @"" ];
        
        if(resultExists == YES) {
            PecuniaError *err = nil;
            if(error) err = [error toPecuniaError ];
            [callbackHandler finishPasswordEntry ];
            [asyncSender asyncCommandCompletedWithResult: result error: err ];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object: [inPipe fileHandleForReading]];
            running = NO;
        } else [[aNotification object] readInBackgroundAndNotify];
    } else {
        if (resultExists == NO) [[aNotification object] readInBackgroundAndNotify];
    }
}


-(void)receive
{
    NSMutableString *cmd = [[NSMutableString alloc ] init ];
    
    while(resultExists == NO) {
        while(TRUE) {
            NSData *data = [[inPipe fileHandleForReading ] availableData ];
            NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            
            // Receive log
            [[MessageLog log ] addMessage:s withLevel:LogLevel_Verbous ];
            
            if([s hasSuffix: @">." ]) {
                [cmd appendString: [s substringToIndex: [s length ] -1  ] ];
                break;
            } else [cmd appendString: s ];
        }
        
        NSRange r = [cmd rangeOfString: @">\n.<" ];
        NSUInteger offset = 0;
        NSUInteger length = [cmd length];
        while (r.location != NSNotFound)
        {
            [self parse: [cmd substringWithRange: NSMakeRange(offset, r.location - offset + 1)]];
            offset = r.location + 3;
            r = [cmd rangeOfString: @">\n.<" options: 0 range: NSMakeRange(offset, length - offset)];
        }
        
        if (length > offset)
            [self parse: [cmd substringWithRange: NSMakeRange(offset, length - offset)]];
        [cmd setString: @"" ];
    }
    [cmd release ];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString: @"callback" ]) {
        cp = [[[CallbackParser alloc ] initWithParent: self command: [attributeDict valueForKey:  @"command"]] autorelease];
        [parser setDelegate: cp ];
    } else if([elementName isEqualToString: @"result" ]) {
        rp = [[[ResultParser alloc ] initWithParent: self] autorelease];
        [parser setDelegate: rp ];
        resultExists = YES;
    } else if([elementName isEqualToString: @"log" ]) {
        LogParser *lp = [[[LogParser alloc ] initWithParent: self level: [attributeDict valueForKey: @"level"]] autorelease];
        [parser setDelegate: lp ];
    }
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
}

-(id)syncCommand: (NSString*)cmd error:(PecuniaError**)err
{
    result = nil; error = nil; resultExists = NO;
    
    // HBCIServer is not running
    if ([task isRunning ] == NO) {
        *err = [PecuniaError errorWithCode:1 message: NSLocalizedString(@"AP99", nil) ];
        return nil;
    }
    
    if(running == YES) {
        // async command is still running
        *err = [PecuniaError errorWithCode:1 message: NSLocalizedString(@"AP97", nil) ];
        return nil;
    }
    NSString *command = [cmd stringByAppendingString: @".\n" ];
    // Send Log
    [[MessageLog log ] addMessage:cmd withLevel:LogLevel_Verbous ];
    [[outPipe fileHandleForWriting ] writeData: [command dataUsingEncoding: NSUTF8StringEncoding ] ];
    [self receive ];
    [callbackHandler finishPasswordEntry ];
    if(error) {
        *err = [error toPecuniaError ];
        return nil;
    }
    return result;
}

-(void)asyncCommand:(NSString*)cmd sender:(id)sender
{
    result = nil; error = nil; resultExists = NO;
    
    // HBCIServer is not running
    if ([task isRunning ] == NO) {
        //		*err = [PecuniaError errorWithCode:1 message: NSLocalizedString(@"AP99", nil) ];
        return;
    }
    NSString *command = [cmd stringByAppendingString: @".\n" ];
    // Send Log
    [[MessageLog log ] addMessage:cmd withLevel:LogLevel_Verbous ];
    [[outPipe fileHandleForWriting ] writeData: [command dataUsingEncoding: NSUTF8StringEncoding ] ];
    //	[[inPipe fileHandleForReading] readInBackgroundAndNotify ];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getData:) name: NSFileHandleReadCompletionNotification object: [inPipe fileHandleForReading]];
    [[inPipe fileHandleForReading] readInBackgroundAndNotify ];
    asyncSender = sender;
    running = YES;
}

@end
