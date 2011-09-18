//
//  TransactionController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.09.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "Transfer.h"

@class BankingController;
@class BankAccount;
@class TransactionLimits;


@interface TransactionController : NSObject
{
    IBOutlet NSObjectController		*transferController;
	IBOutlet NSArrayController		*templateController;
	IBOutlet NSArrayController		*countryController;
    IBOutlet NSWindow				*transferLocalWindow;
	IBOutlet NSWindow				*transferEUWindow;
	IBOutlet NSWindow				*transferInternalWindow;
	IBOutlet NSPopUpButton			*countryButton;
	IBOutlet NSComboBox				*accountBox;
	IBOutlet NSComboBox				*chargeBox;
	IBOutlet NSDatePicker			*executionDatePicker;
	IBOutlet NSDrawer				*templatesDraw;
	IBOutlet NSTableView			*templatesView;
	NSWindow						*window;
	
	Transfer						*transfer;
	NSMutableArray					*transfers;
	BankingController				*bankingController;
	BankAccount						*account;
	TransactionLimits				*limits;
	TransferType					transferType;
	NSString						*selectedCountry;
	NSArray							*internalAccounts;
	NSDictionary					*selCountryInfo;
	
	BOOL							donation;
}

- (void)transferOfType: (TransferType)tt forAccount: (BankAccount*)account;
- (void)donateWithAccount: (BankAccount*)account;
- (void)changeTransfer:(Transfer*)transfer;
- (void)hideTransferDate: (BOOL)hide;

- (IBAction)transferFinished:(id)sender;
- (IBAction)nextTransfer:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)getDataFromTemplate:(id)sender;
- (IBAction)countryDidChange:(id)sender;
- (IBAction)sendTransfer:(id)sender;

-(void)preparePurposeFields;
-(void)setManagedObjectContext:(NSManagedObjectContext*)context;
-(BOOL)check;

@end
