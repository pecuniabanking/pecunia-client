//
//  TransferListController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 14.07.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TransactionController;

@interface TransferListController : NSObject {
	IBOutlet NSArrayController  *transferController;
	IBOutlet NSTableView		*transferView;
    IBOutlet NSTextField		*selAmountField;
	IBOutlet TransactionController		*transferWindowController;
	
	NSNumberFormatter	*formatter;
}

-(IBAction)sendTransfers: (id)sender;
-(IBAction)deleteTransfers: (id)sender;
-(IBAction)changeTransfer: (id)sender;
-(IBAction)transferDoubleClicked: (id)sender;

-(void)setFilterPredicate:(NSPredicate*)pred;
-(void)setManagedObjectContext:(NSManagedObjectContext *)context;

@end
