//
//  PecuniaError.h
//  Pecunia
//
//  Created by Frank Emminghaus on 15.05.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    err_hbci_abort = 0,
    err_hbci_gen,
    err_hbci_passwd,
    err_hbci_param,
    err_gen = 100
} ErrorCode;

@interface PecuniaError : NSError {
    NSString    *title;
}

@property(nonatomic,retain) NSString *title;

+(NSError*)errorWithText:(NSString*)msg;
+(PecuniaError*)errorWithCode:(ErrorCode)code message:(NSString*)msg;
+(PecuniaError*)errorWithMessage:(NSString*)msg;
-(void)alertPanel;
-(void)logMessage;

@end
