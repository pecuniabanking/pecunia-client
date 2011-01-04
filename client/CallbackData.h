//
//  CallbackData.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CallbackData : NSObject {
	NSString	*bankCode;
	NSString	*userId;
	NSString	*message;
	NSString	*proposal;
	NSString	*command;
	int			reason;
	int			type;
}

@property (copy) NSString *bankCode;
@property (copy) NSString *message;
@property (copy) NSString *proposal;
@property (copy) NSString *command;
@property (copy) NSString *userId;

-(void)setReason: (NSString*)res;
-(void)setType: (NSString*)t;

@end
