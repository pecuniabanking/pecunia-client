//
//  TanMediaWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 08.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TanMediaWindowController : NSWindowController {
	IBOutlet NSTextField	*messageField;
	IBOutlet NSComboBox		*tanMediaCombo;
	
	NSString	*message;
	NSString	*tanMedia;
	NSString	*userId;
	NSString	*bankCode;
	BOOL		active;
}
-(id)initWithUser:(NSString*)usrId bankCode:(NSString*)code message:(NSString*)msg;

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *tanMedia;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *bankCode;

@end

