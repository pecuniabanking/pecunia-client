//
//  DonationMessageController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 24.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DonationMessageController : NSWindowController {
    BOOL donate;
}

- (IBAction)donate: (id)sender;
- (IBAction)later: (id)sender;
- (BOOL)run;
@end
