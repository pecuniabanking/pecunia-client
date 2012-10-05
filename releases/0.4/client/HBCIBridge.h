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
@class HBCIController;
@class PasswordWindow;
@class PecuniaError;
@class CallbackData;

@interface HBCIBridge : NSObject {
	ResultParser	*rp;
	CallbackParser	*cp;
	
	NSPipe		*inPipe;
	NSPipe		*outPipe;
	NSTask		*task;
	
	BOOL		resultExists;
	BOOL		running;

	id				result;
	HBCIError		*error;
	HBCIController	*client;
	PasswordWindow	*pwWindow;
	NSString		*currentPwService;
	NSString		*currentPwAccount;
	NSMutableString	*asyncString;
	id				asyncSender;
}

@property(nonatomic, retain) HBCIError *error;

-(id)initWithClient: (HBCIController*)cl;

-(NSPipe*)outPipe;
-(void)setResult: (id)res;
-(id)result;
-(void)startup;

-(id)syncCommand: (NSString*)cmd error:(PecuniaError**)err;
-(void)asyncCommand:(NSString*)cmd sender:(id)sender;
-(void)finishPasswordEntry;
-(NSString*)callbackWithData:(CallbackData*)data;


@end
