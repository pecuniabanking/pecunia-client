//
//  ChipcardDataWindowController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.08.16.
//  Copyright © 2016 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChipcardDataWindowController : NSWindowController


@property(nonatomic, retain) CardBankData *bankData;
@property(nonatomic, retain) NSMutableDictionary *fields;
@property(nonatomic, retain) ChipcardManager *manager;
@property(nonatomic, retain) IBOutlet NSObjectController *dataController;
@property(nonatomic, retain) IBOutlet NSButton *writeButton;

- (IBAction) close: (id)sender;
- (IBAction) write: (id)sender;


@end
