//
//  LicenseWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.09.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LicenseWindowController : NSObject {
    IBOutlet NSTextView *licenseView;
    IBOutlet NSWindow   *window;

}

- (IBAction)accept: (id)sender;
- (IBAction)decline: (id)sender;

@end
