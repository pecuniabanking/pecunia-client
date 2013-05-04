//
//  SigningOptionsController.h
//  SigningOptions
//
//  Created by Frank Emminghaus on 06.08.12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SigningOption;
@class BankAccount;

@interface SigningOptionsController : NSWindowController {
    IBOutlet NSTableView       *optionsView;
    IBOutlet NSArrayController *optionsController;

    NSArray  *options;
    NSString *accountNumber;

}

- (IBAction)ok: (id)sender;
- (IBAction)cancel: (id)sender;

- (id)initWithSigningOptions: (NSArray *)opts forAccount: (BankAccount *)acc;
- (SigningOption *)selectedOption;

@end
