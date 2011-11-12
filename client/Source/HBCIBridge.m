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
#import "CallbackData.h"
#import "HBCIController.h"
#import "PasswordWindow.h"
#import "Keychain.h"
#import "TanMethod.h"
#import "PasswordWindow.h"
#import "NewPasswordController.h"
#import "TanMethodListController.h"
#import "PecuniaError.h"
#import "LogController.h"
#import "ChipTanWindowController.h"
#import "TanMediaWindowController.h"


@implementation HBCIBridge

-(id)initWithHbciClient: (HBCIController*)cl
{
    self = [super init ];
    if(self == nil) return nil;
    client = cl;
    running = NO;
    
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
    [task setArguments: [NSArray arrayWithObjects: @"-jar", launchPath, nil ] ];
    
    /*	
     [[NSNotificationCenter defaultCenter] addObserver:self 
     selector:@selector(getData:) 
     name: NSFileHandleReadCompletionNotification 
     object: [[task standardOutput] fileHandleForReading]];
     */	
    //    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    
    // launch the task asynchronously
    [task launch];
    
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
            if(pwWindow) [self finishPasswordEntry ];
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
        cp = [[CallbackParser alloc ] initWithParent: self command: [attributeDict valueForKey: @"command" ] ];
        [parser setDelegate: cp ];
    } else if([elementName isEqualToString: @"result" ]) {
        rp = [[ResultParser alloc ] initWithParent: self ];
        [parser setDelegate: rp ];
        resultExists = YES;
    } else if([elementName isEqualToString: @"log" ]) {
        LogParser *lp = [[LogParser alloc ] initWithParent: self level: [attributeDict valueForKey: @"level" ] ];
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
    if(pwWindow) [self finishPasswordEntry ];
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

-(NSString*)getPassword
{
    currentPwService = @"Pecunia";
    currentPwAccount = @"DataFile";
    NSString* passwd = [Keychain passwordForService: currentPwService account: currentPwAccount ];
    if(passwd == nil) {
        if(pwWindow == nil) {
            pwWindow = [[PasswordWindow alloc] initWithText: NSLocalizedString(@"AP54", @"")
                                                      title: NSLocalizedString(@"AP53", @"")];
            
        } else [pwWindow retry ];
        
        int res = [NSApp runModalForWindow: [pwWindow window]];
        if(res) [NSApp terminate: self ];
        
        passwd = [pwWindow result];
    }
    if(passwd == nil || [passwd length ] == 0) return @"<abort>";
    return passwd;
}

-(void)finishPasswordEntry
{
    if(error == nil) {
        NSString *passwd = [pwWindow result];
        BOOL savePassword = [pwWindow shouldSavePassword ];
        [Keychain setPassword:passwd forService:currentPwService account:currentPwAccount store:savePassword ];
    }
    [pwWindow close ];
    [pwWindow release ];
    pwWindow = nil;
}

-(NSString*)getNewPassword: (CallbackData*)data
{
    NSString* passwd = [Keychain passwordForService: @"Pecunia" account: @"DataFile" ];
    if(passwd) return passwd;
    NewPasswordController *pwController = [[NewPasswordController alloc] initWithText: data.message
                                                                                title: @"Bitte Passwort eingeben" ];
    int res = [NSApp runModalForWindow: [pwController window]];
    if(res) {
        [pwController release ];
        return @"<abort>";
    }
    passwd = [pwController result ];
    [pwController autorelease ];
    
    [Keychain setPassword:passwd forService:@"Pecunia" account:@"DataFile" store:NO ];
    return passwd;
}

-(NSString*)getTanMethod: (CallbackData*)data
{
    NSMutableArray *tanMethods = [NSMutableArray arrayWithCapacity: 5 ];
    NSArray *meths = [data.proposal componentsSeparatedByString: @"|" ];
    NSString *meth;
    for(meth in meths) {
        TanMethod *tanMethod = [[[TanMethod alloc ] init ] autorelease ];
        NSArray *list = [meth componentsSeparatedByString: @":" ];
        tanMethod.function = [NSNumber numberWithInteger:[[list objectAtIndex:0 ] integerValue ] ];
        tanMethod.description = [list objectAtIndex:1 ];
        [tanMethods addObject: tanMethod ];
    }
    
    TanMethodListController *controller = [[TanMethodListController alloc ] initWithMethods: tanMethods ];
    int res = [NSApp runModalForWindow: [controller window]];
    if(res) {
        [controller release ];
        return @"<abort>";
    }
    NSNumber *selectedMethod = [controller selectedMethod ];
    return [selectedMethod stringValue ];
}

-(NSString*)getPin:(CallbackData*)data
{
    currentPwService = @"Pecunia PIN";
    NSString *s = [NSString stringWithFormat: @"PIN_%@_%@", data.bankCode, data.userId ];
    if (![s isEqualToString: currentPwAccount]) {
        if(pwWindow) [self finishPasswordEntry ];
        [currentPwAccount release ];
        currentPwAccount = [s retain ];
    }
    
    NSString* passwd;
    // Check keychain
    passwd = [Keychain passwordForService: currentPwService account: currentPwAccount ];
    if(passwd) return passwd;
    
    if(pwWindow == nil) {
        pwWindow = [[PasswordWindow alloc] initWithText: [NSString stringWithFormat: NSLocalizedString(@"AP96", @""), data.userId ]
                                                  title: @"Bitte PIN eingeben" ];
        
    } else [pwWindow retry ];
    
    int res = [NSApp runModalForWindow: [pwWindow window]];
    if(res == 0) {
        return [pwWindow result];
    } else return @"<abort>";
}

-(NSString*)getTan:(CallbackData*)data
{
    if (data.proposal && [data.proposal length ] > 0) {
        // FlickerCode
        ChipTanWindowController *controller = [[ChipTanWindowController alloc ] initWithCode:data.proposal message:data.message ];
        int res = [NSApp runModalForWindow:[controller window ] ];
        if (res == 0) {
            return [controller tan ];
        } else return  @"<abort>";
    }
    
    
    PasswordWindow *tanWindow = [[PasswordWindow alloc] initWithText: [NSString stringWithFormat: NSLocalizedString(@"AP98", @""), data.userId, data.message ]
                                                               title: @"Bitte TAN eingeben" ];
    int res = [NSApp runModalForWindow: [tanWindow window]];
    [tanWindow close ];
    [tanWindow autorelease ];
    if(res == 0) {
        return [tanWindow result];
    } else return @"<abort>";
}

-(NSString*)getTanMedia:(CallbackData*)data
{
    TanMediaWindowController *mediaWindow = [[TanMediaWindowController alloc] initWithUser:data.userId bankCode:data.bankCode message:data.message ];
    int res = [NSApp runModalForWindow: [mediaWindow window]];
    if(res == 0) {
        return mediaWindow.tanMedia;
    } else return @"<abort>";
}


-(NSString*)callbackWithData:(CallbackData*)data
{
    if([data.command isEqualToString: @"password_load" ]) {
        NSString *passwd = [self getPassword ];
        return passwd;
    }
    if([data.command isEqualToString: @"password_save" ]) {
        NSString *passwd = [self getNewPassword: data ];
        return passwd;
    }
    if([data.command isEqualToString: @"getTanMethod" ]) {
        return [self getTanMethod: data ];
    }
    if([data.command isEqualToString: @"getPin" ]) {
        return [self getPin: data ];
    }
    if([data.command isEqualToString: @"getTan" ]) {
        return [self getTan: data ];
    }
    if([data.command isEqualToString: @"getTanMedia" ]) {
        return [self getTanMedia: data ];
    }
    return @"";
}

@end
