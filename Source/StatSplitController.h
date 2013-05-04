//
//  StatSplitController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.02.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankStatement;

@interface StatSplitController : NSWindowController {
    IBOutlet NSTableView        *splitView;
    IBOutlet NSArrayController  *splitStatController;
    IBOutlet NSArrayController  *catController;
    IBOutlet NSObjectController *currentStat;

    NSManagedObjectContext *managedObjectContext;
    BankStatement          *statement;
    NSDecimalNumber        *residualAmount;
    NSView                 *catView;

}

- (id)initWithStatement: (BankStatement *)stat view: (NSView *)view;

- (IBAction)manageAssignments: (id)sender;

@end
