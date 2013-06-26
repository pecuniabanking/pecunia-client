//
//  AssignmentController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 24.06.13.
//  Copyright (c) 2013 Frank Emminghaus. All rights reserved.
//

#import "AssignmentController.h"

@interface AssignmentController ()

@end

@implementation AssignmentController
@synthesize info;
@synthesize amount;

- (id)initWithAmount:(NSDecimalNumber*)am
{
    self = [super initWithWindowNibName:@"AssignmentController"];
    self.amount = am;
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}


- (IBAction)ok:(id)sender
{
    [self.window close];
    [NSApp stopModalWithCode:0];
}

- (IBAction)cancel:(id)sender
{
    [self.window close];
    [NSApp stopModalWithCode:1];
}

@end
