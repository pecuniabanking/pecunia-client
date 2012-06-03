/**
 * Copyright (c) 2010, 2012, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import <Cocoa/Cocoa.h>

#import "Transfer.h"

@class TransactionController;
@class TransfersController;
@class TransfersListView;
@class TransferFormularBackground;

@class iCarousel;
@class OnOffSwitchControlCell;
@class MAAttachedWindow;

@interface TransferTemplateDragDestination : NSView
{
@private
    BOOL formularVisible;
}

@property (nonatomic, assign) TransfersController *controller;

- (NSRect)dropTargetFrame;

@end

@interface TransfersController : NSObject
{
    IBOutlet NSView                 *mainView;
	IBOutlet NSArrayController      *finishedTransfers;
	IBOutlet NSArrayController      *pendingTransfers;
	IBOutlet NSTableView            *transferView;
    IBOutlet NSTextField            *selAmountField;
	IBOutlet TransactionController  *transactionController;
    IBOutlet TransfersListView      *finishedTransfersListView;
    IBOutlet TransfersListView      *pendingTransfersListView;
    IBOutlet iCarousel              *templateCarousel;
    IBOutlet OnOffSwitchControlCell *carouselSwitch;
    IBOutlet TransferTemplateDragDestination *rightPane;

    IBOutlet NSTextField            *titleText;
    IBOutlet NSTextField            *receiverText;
    IBOutlet NSPopUpButton          *sourceAccountSelector;
    IBOutlet NSPopUpButton          *targetAccountSelector;
    IBOutlet NSComboBox             *receiverComboBox;
    IBOutlet NSTextField            *amountTextField;
    IBOutlet NSTextField            *amountCurrencyText;
    IBOutlet NSTextField            *accountText;
    IBOutlet NSTextField            *accountNumber;
    IBOutlet NSTextField            *bankCodeText;
    IBOutlet NSTextField            *bankCode;
    IBOutlet NSTextField            *saldoText;
    IBOutlet NSTextField            *saldoCurrencyText;
    IBOutlet NSTextField            *targetCountryText;
    IBOutlet NSPopUpButton          *targetCountrySelector;
    IBOutlet NSTextField            *feeText;
    IBOutlet NSPopUpButton          *feeSelector;
    IBOutlet NSTextField            *purposeTextField;
    IBOutlet NSTextField            *bankDescription;
    
    IBOutlet NSTextField            *executionText;
    IBOutlet NSButton               *executeImmediatelyRadioButton;
    IBOutlet NSTextField            *executeImmediatelyText;
    IBOutlet NSButton               *executeAtDateRadioButton;
    IBOutlet NSDatePicker           *executionDatePicker;
    IBOutlet NSView                 *calendarView;
    IBOutlet NSButton               *calendarButton;
    IBOutlet NSDatePicker           *calendar;
    
    IBOutlet NSButton               *queueItButton;
    IBOutlet NSButton               *doItButton;
    
@private
	NSNumberFormatter *formatter;
    MAAttachedWindow* calendarWindow;
}

// Formulars.
@property (assign) IBOutlet TransferFormularBackground *transferFormular;

- (IBAction)sendTransfers: (id)sender;
- (IBAction)deleteTransfers: (id)sender;
- (IBAction)changeTransfer: (id)sender;
- (IBAction)transferDoubleClicked: (id)sender;
- (IBAction)carouselSwitchChanged: (id)sender;
- (IBAction)showCalendar: (id)sender;

- (void)prepareTransferFormular: (TransferType)type;

- (NSView *)mainView;
- (void)prepare;
- (void)activate;
- (void)deactivate;
- (void)terminate;

@end
