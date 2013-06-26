//
//  AssignmentController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 24.06.13.
//  Copyright (c) 2013 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AssignmentController : NSWindowController {
    IBOutlet NSTextField *amountField;
    IBOutlet NSTextField *infoField;
    
    NSDecimalNumber *amount;
    NSString        *info;
}

- (id)initWithAmount:(NSDecimalNumber*)am;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@property(nonatomic, copy) NSDecimalNumber *amount;
@property(nonatomic, copy) NSString *info;
@end
