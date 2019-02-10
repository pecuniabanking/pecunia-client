//
//  BudgetWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 14.06.17.
//  Copyright © 2017 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BudgetWindowController : NSWindowController {
    NSUInteger                           year;
    NSUInteger                           effMonths;
}



@property(nonatomic, retain) IBOutlet NSOutlineView         *budgetView;
@property(nonatomic, retain) IBOutlet NSTreeController      *budgetContainer;
@property(nonatomic, retain) IBOutlet NSSegmentedControl    *yearSelector;
@property(nonatomic, retain) IBOutlet NSTextField           *totalField;

@property(nonatomic, retain) NSMutableArray                 *budgetData;
@property(nonatomic, retain) NSNumber                       *period;
@property(nonatomic, retain) NSNumber                       *total;
@property(nonatomic, retain) NSNumber                       *tolerance;
@property(nonatomic, retain) NSMutableDictionary            *actuals;
@property(nonatomic, retain) NSColor                        *lightRed;
@property(nonatomic, retain) NSNumber                       *hideBudgetless;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)changeYear:(id)sender;
- (IBAction)hideBudgetless:(id)sender;


@end


