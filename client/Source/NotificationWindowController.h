//
//  NotificationWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.08.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NotificationWindowController : NSWindowController {
    IBOutlet    NSTextField *messageField;
    NSString    *message;
    NSString    *title;

}

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *title;


-(IBAction)ok:(id)sender;
-(id)initWithMessage:(NSString*)msg title:(NSString*)header;

@end

