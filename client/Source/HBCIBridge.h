//
//  HBCIBridge.h
//  Client
//
//  Created by Frank Emminghaus on 18.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ResultParser;
@class CallbackParser;
@class HBCIError;
//@class PasswordWindow;
@class PecuniaError;
@class CallbackData;
@class CallbackHandler;

@interface HBCIBridge : NSObject <NSXMLParserDelegate>
{
    ResultParser	*rp;
    CallbackParser	*cp;
    
    NSPipe		*inPipe;
    NSPipe		*outPipe;
    NSTask		*task;
    
    BOOL		resultExists;
    BOOL		running;
    
    id				result;
    HBCIError		*error;
//    PasswordWindow	*pwWindow;
//    NSString		*currentPwService;
//    NSString		*currentPwAccount;
    NSMutableString	*asyncString;
    id				asyncSender;
	CallbackHandler	*callbackHandler;
}

@property(nonatomic, readonly) CallbackHandler *callbackHandler;

-(NSPipe*)outPipe;
-(void)setResult: (id)res;
-(id)result;
-(void)startup;

-(id)syncCommand: (NSString*)cmd error:(PecuniaError**)err;
-(void)asyncCommand:(NSString*)cmd sender:(id)sender;
-(HBCIError*)error;
//-(void)finishPasswordEntry;
//-(NSString*)callbackWithData:(CallbackData*)data;


@end
