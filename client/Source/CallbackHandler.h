//
//  CallbackHandler.h
//  Pecunia
//
//  Created by Emminghaus, Frank on 09.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CallbackData;
@class PasswordWindow;

@interface CallbackHandler : NSObject {
	NSMutableDictionary *currentSignOptions;
	
	PasswordWindow	*pwWindow;
    NSString		*currentPwService;
    NSString		*currentPwAccount;
	BOOL			errorOccured;
}

@property(nonatomic, retain) NSMutableDictionary * currentSignOptions;

-(void)startSession;
-(NSString*)getPassword;
-(void)finishPasswordEntry;
-(NSString*)getNewPassword: (CallbackData*)data;
-(NSString*)getTanMethod: (CallbackData*)data;
-(NSString*)getPin:(CallbackData*)data;
-(NSString*)getTan:(CallbackData*)data;
-(NSString*)getTanMedia:(CallbackData*)data;
-(NSString*)callbackWithData:(CallbackData*)data;
-(void)setErrorOccured;

@end
