//
//  NewPasswordController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.12.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NewPasswordController : NSWindowController {
    IBOutlet NSTextField *passwordText;
    IBOutlet NSTextField *passwordField1;
    IBOutlet NSTextField *passwordField2;
    IBOutlet NSButton    *okButton;

    NSString *text;
    NSString *title;
    NSString *result;

}
- (id)initWithText: (NSString *)x title: (NSString *)y;
- (void)windowWillClose: (NSNotification *)aNotification;
- (void)windowDidLoad;
- (NSString *)result;

- (IBAction)ok: (id)sender;
- (IBAction)cancel: (id)sender;

@end
