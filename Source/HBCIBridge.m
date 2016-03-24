/**
 * Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "HBCIBridge.h"
#import "ResultParser.h"
#import "CallbackParser.h"
#import "LogParser.h"
#import "HBCIError.h"
#import "PecuniaError.h"
#import "HBCICommon.h"
#import "LaunchParameters.h"
#import "CallbackHandler.h"
#import "HBCIController.h"
#import "NSString+PecuniaAdditions.h"

@interface HBCIBridge () {
    ResultParser   *rp;
    CallbackParser *cp;
    LogParser      *lp;

    NSPipe *inPipe;
    NSPipe *outPipe;
    NSTask *task;

    BOOL resultExists;
    BOOL running;

    id result;
    id asyncSender;

    HBCI_Error *error;

    NSMutableString *asyncString;
}

@end

@implementation HBCIBridge

@synthesize authRequest;

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    running = NO;
    authRequest = [AuthRequest new];

    return self;
}

- (NSPipe *)outPipe {
    return outPipe;
}

// Returns NO if the result was an error.
- (BOOL)setResult: (id)res {
    if ([res isKindOfClass: [HBCI_Error class]]) {
        result = nil;
        error = res;
        return NO;
    } else {
        result = res;
        error = nil;
    }
    return YES;
}

- (id)result {
    return result;
}

- (HBCI_Error *)error {
    return error;
}

- (void)startup {
    task = [[NSTask alloc] init];
    // The output of stdout and stderr is sent to a pipe so that we can catch it later
    // and send it along to the controller; notice that we don't bother to do anything with stdin,
    // so this class isn't as useful for a task that you need to send info to, not just receive.
    inPipe = [NSPipe pipe];
    outPipe = [NSPipe pipe];
    [task setStandardOutput: inPipe];
    [task setStandardInput: outPipe];

    if (LaunchParameters.parameters.debugServer) {
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *jarPath = [bundlePath stringByAppendingString: @"/Contents/Resources/HBCIServer.jar"];

        [task setLaunchPath: @"/usr/bin/java" ];
        //	[task setEnvironment: [NSDictionary dictionaryWithObjectsAndKeys: @"/users/emmi/workspace/HBCIServer", @"CLASSPATH", nil ] ];

        if (LaunchParameters.parameters.debugServer) {
            [task setArguments: @[@"-Xdebug", @"-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005", @"-jar", jarPath] ];
        }

        // Launch the task asynchronously.
        [task launch];

        if (LaunchParameters.parameters.debugServer) {
            // Consume jvm status message.
            (void)[[inPipe fileHandleForReading] availableData];
        }
    } else {
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *jarPath = [bundlePath stringByAppendingString: @"/Contents/Resources/HBCIServer.jar"];
        NSString *launchPath = [bundlePath stringByAppendingString: @"/Contents/Resources/Java/jre/Contents/Home/bin/java"];

        [task setLaunchPath: launchPath];
        [task setArguments: @[@"-jar", jarPath]];

        [task launch];
    }
}

- (void)parse: (NSString *)cmd
{
    LogVerbose(@"HBCI bridge string to parse: %@", cmd);

    NSXMLParser *parser = [[NSXMLParser alloc] initWithData: [cmd dataUsingEncoding: NSUTF8StringEncoding]];
    [parser setDelegate: self];
    [parser setShouldResolveExternalEntities: YES];
    [parser parse];
}

- (void)getData: (NSNotification *)aNotification
{
    NSData *data = [aNotification userInfo][NSFileHandleNotificationDataItem];
    // If the length of the data is zero, then the task is basically over - there is nothing
    // more to get from the handle so we may as well shut down.
    if ([data length] > 0) {
        // Send the data on to the controller; we can't just use +stringWithUTF8String: here
        // because -[data bytes] is not necessarily a properly terminated string.
        // -initWithData:encoding: on the other hand checks -[data length]
        NSString *s = [NSString stringWithData: data];

        if (asyncString == nil) {
            asyncString = [[NSMutableString alloc] init];
        }
        if ([s hasSuffix: @">."]) {
            [asyncString appendString: [s substringToIndex: [s length] - 1]];
        } else {
            [asyncString appendString: s];
            // command is not yet complete: go on
            [[aNotification object] readInBackgroundAndNotify];
            return;
        }

        NSRange    r = [asyncString rangeOfString: @">\n.<"];
        NSUInteger offset = 0;
        NSUInteger length = [asyncString length];
        while (r.location != NSNotFound) {
            @try {
                [self parse: [asyncString substringWithRange: NSMakeRange(offset, r.location - offset + 1)]];
            }
            @catch (NSException *exception) {
                LogError(@"Exception during result parsing: %@", exception.description);
            }
            offset = r.location + 3;
            r = [asyncString rangeOfString: @">\n.<" options: 0 range: NSMakeRange(offset, length - offset)];
        }

        if (length > offset) {
            @try {
                [self parse: [asyncString substringWithRange: NSMakeRange(offset, length - offset)]];
            }
            @catch (NSException *exception) {
                LogError(@"Exception during result parsing: %@", exception.description);
            }
        }
        [asyncString setString: @""];

        if (resultExists) {
            PecuniaError *err = nil;
            if (error) {
                err = [error toPecuniaError];
            }
            [authRequest finishPasswordEntry];

            [asyncSender asyncCommandCompletedWithResult: result error: err];
            [[NSNotificationCenter defaultCenter] removeObserver: self name: NSFileHandleReadCompletionNotification object: [inPipe fileHandleForReading]];
            running = NO;
        } else {
            [[aNotification object] readInBackgroundAndNotify];
        }
    } else {
        if (!resultExists) {
            [[aNotification object] readInBackgroundAndNotify];
        }
    }
}

- (void)receive
{
    NSMutableString *cmd = [[NSMutableString alloc] init];

    while (resultExists == NO) {
        while (TRUE) {
            NSData *data = [[inPipe fileHandleForReading] availableData];

            NSString *s = [NSString stringWithData: data];

            if ([s hasSuffix: @">."]) {
                [cmd appendString: [s substringToIndex: [s length] - 1]];
                break;
            } else {
                [cmd appendString: s];
            }
        }

        NSRange    r = [cmd rangeOfString: @">\n.<"];
        NSUInteger offset = 0;
        NSUInteger length = [cmd length];
        while (r.location != NSNotFound) {
            [self parse: [cmd substringWithRange: NSMakeRange(offset, r.location - offset + 1)]];
            offset = r.location + 3;
            r = [cmd rangeOfString: @">\n.<" options: 0 range: NSMakeRange(offset, length - offset)];
        }

        if (length > offset) {
            [self parse: [cmd substringWithRange: NSMakeRange(offset, length - offset)]];
        }
        [cmd setString: @""];
    }
}

- (void)parser: (NSXMLParser *)parser didStartElement: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName attributes: (NSDictionary *)attributeDict
{
    if ([elementName isEqualToString: @"callback"]) {
        cp = [[CallbackParser alloc] initWithParent: self command: [attributeDict valueForKey:  @"command"]];
        [parser setDelegate: cp];
    } else if ([elementName isEqualToString: @"result"]) {
        rp = [[ResultParser alloc] initWithParent: self];
        [parser setDelegate: rp];
        resultExists = YES;
    } else if ([elementName isEqualToString: @"log"]) {
        lp = [[LogParser alloc] initWithParent: self level: [attributeDict valueForKey: @"level"]];
        [parser setDelegate: lp];
    }

}

- (void)parser: (NSXMLParser *)parser didEndElement: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName
{
}

- (id)syncCommand: (NSString *)cmd error: (PecuniaError **)err
{
    result = nil; error = nil; resultExists = NO;

    // HBCIServer is not running
    if ([task isRunning] == NO) {
        *err = [PecuniaError errorWithCode: 1 message: NSLocalizedString(@"AP358", nil)];
        return nil;
    }

    if (running == YES) {
        // async command is still running
        *err = [PecuniaError errorWithCode: 1 message: NSLocalizedString(@"AP78", nil)];
        return nil;
    }
    NSString *command = [cmd stringByAppendingString: @".\n"];

    authRequest.errorOccured = NO;
    LogComTrace(HBCILogIntern, [MessageLog prettyPrintServerMessage: cmd]);
    [[outPipe fileHandleForWriting] writeData: [command dataUsingEncoding: NSUTF8StringEncoding]];
    [self receive];

    [authRequest finishPasswordEntry];

    if (error) {
        *err = [error toPecuniaError];
        return nil;
    }
    return result;
}

- (void)asyncCommand: (NSString *)cmd sender: (id)sender
{
    result = nil; error = nil; resultExists = NO;

    // HBCIServer is not running
    if ([task isRunning] == NO) {
        //		*err = [PecuniaError errorWithCode:1 message: NSLocalizedString(@"AP358", nil) ];
        return;
    }
    NSString *command = [cmd stringByAppendingString: @".\n"];
    LogComTrace(HBCILogIntern, [MessageLog prettyPrintServerMessage: cmd]);

    [[outPipe fileHandleForWriting] writeData: [command dataUsingEncoding: NSUTF8StringEncoding]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(getData:) name: NSFileHandleReadCompletionNotification object: [inPipe fileHandleForReading]];
    [[inPipe fileHandleForReading] readInBackgroundAndNotify];
    asyncSender = sender;
    running = YES;
}

@end
