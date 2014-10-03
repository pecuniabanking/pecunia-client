/**
 * Copyright (c) 2010, 2014, Pecunia Project. All rights reserved.
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
#import "TransfersListview.h"
#import "TransferTemplatesListview.h"
#import "PecuniaTabItem.h"

@class TransactionController;
@class TransfersController;
@class TransferFormularView;

@class DragImageView;
@class DeleteTransferTargetView;
@class BankAccount;
@class BankStatement;
@class TransactionLimits;
@class TimeSliceManager;
@class ShadowedTextField;

@interface TransferTemplateDragDestination : NSView
{
@private
    BOOL     formularVisible;
    NSString *currentDragDataType;
}

@property (nonatomic, weak) TransfersController *controller;

- (NSRect)dropTargetFrame;
- (void)hideFormular;
- (void)showFormular;

@end

@interface TransfersController : NSObject <PecuniaTabItem, NSWindowDelegate, NSTextFieldDelegate, TransfersActionDelegate>
{
    IBOutlet NSView                          *mainView;
    IBOutlet NSArrayController               *finishedTransfers;
    IBOutlet NSArrayController               *pendingTransfers;
    IBOutlet TransactionController           *transactionController;
    IBOutlet TransfersListView               *finishedTransfersListView;
    IBOutlet TransfersListView               *pendingTransfersListView;
    IBOutlet TransferTemplatesListView       *transferTemplateListView;
    IBOutlet TransferTemplateDragDestination *rightPane;

    IBOutlet NSTextField   *titleText;
    IBOutlet NSTextField   *receiverText;
    IBOutlet NSPopUpButton *sourceAccountSelector;
    IBOutlet NSPopUpButton *targetAccountSelector;
    IBOutlet NSComboBox    *receiverComboBox;
    IBOutlet NSTextField   *amountCurrencyText;
    IBOutlet NSTextField   *amountCurrencyField;
    IBOutlet NSTextField   *amountField;
    IBOutlet NSTextField   *remoteBankField;
    IBOutlet NSTextField   *remoteBankLabel;
    IBOutlet NSTextField   *accountText;
    IBOutlet NSTextField   *accountNumber;
    IBOutlet NSTextField   *bankCodeText;
    IBOutlet NSTextField   *bankCode;
    IBOutlet NSTextField   *saldoText;
    IBOutlet NSTextField   *saldoCurrencyText;
    IBOutlet NSTextField   *targetCountryText;
    IBOutlet NSPopUpButton *targetCountrySelector;
    IBOutlet NSTextField   *feeText;
    IBOutlet NSPopUpButton *feeSelector;
    IBOutlet NSTextField   *bankDescription;
    IBOutlet NSTextField   *purpose1;
    IBOutlet NSTextField   *purpose2;
    IBOutlet NSTextField   *purpose3;
    IBOutlet NSTextField   *purpose4;

    IBOutlet NSTextField  *executionText;
    IBOutlet NSButton     *executeImmediatelyRadioButton;
    IBOutlet NSTextField  *executeImmediatelyText;
    IBOutlet NSTextField  *executeAtDateLabel;
    IBOutlet NSButton     *executeAtDateRadioButton;
    IBOutlet NSDatePicker *executionDatePicker;
    IBOutlet NSView       *calendarView;
    IBOutlet NSButton     *calendarButton;
    IBOutlet NSDatePicker *calendar;
    IBOutlet NSPopover    *calendarPopover;
    IBOutlet NSTableView  *autofillTable;

    IBOutlet NSPopover         *autofillPopover;
    IBOutlet NSArrayController *autofillController;

    IBOutlet NSButton    *queueItButton;
    IBOutlet NSButton    *doItButton;
    IBOutlet NSButton    *sendTransfersButton;
    IBOutlet NSTextField *templateName;

    IBOutlet DragImageView            *transferInternalImage;
    IBOutlet DragImageView            *transferNormalImage;
    IBOutlet DragImageView            *transferEUImage;
    IBOutlet DragImageView            *transferSEPAImage;
    IBOutlet DragImageView            *transferDebitImage;
    IBOutlet DeleteTransferTargetView *transferDeleteImage;
    IBOutlet TimeSliceManager         *timeSlicer;

    IBOutlet NSPanel   *templateNameSheet;
    IBOutlet NSTabView *transferTab;

@private
    TransactionLimits *limits;
    NSArray           *draggedTransfers;
    NSUInteger        rowPositions[4];

    NSPredicate *finishedTransfersPredicate;
}

@property (strong) IBOutlet TransferFormularView *transferFormular;
@property (strong) IBOutlet ShadowedTextField *dragToHereLabel;

@property (nonatomic, assign) BOOL dropToEditRejected;
@property (nonatomic, assign) BOOL donation;

- (IBAction)sendTransfers: (id)sender;
- (IBAction)showCalendar: (id)sender;
- (IBAction)sourceAccountChanged: (id)sender;
- (IBAction)targetAccountChanged: (id)sender;
- (IBAction)calendarChanged: (id)sender;
- (IBAction)queueTransfer: (id)sender;
- (IBAction)sendTransfer: (id)sender;
- (IBAction)deleteTransfer: (id)sender;
- (IBAction)saveTemplate: (id)sender;
- (IBAction)cancelCreateTemplate: (id)sender;

- (void)draggingStartsFor: (TransfersListView *)sender;
- (BOOL)prepareTransferOfType: (TransferType)type;
- (BOOL)prepareEditingFromDragging: (id<NSDraggingInfo>)info;
- (BOOL)startEditingFromDragging: (id<NSDraggingInfo>)info;
- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info;
- (void)cancelEditing;
- (BOOL)editingInProgress;
- (void)startDonationTransfer;
- (BOOL)startTransferOfType: (TransferType)type withAccount: (BankAccount *)account statement: (BankStatement *)statement;
- (void)createTemplateOfType: (TransferType)type fromStatement: (BankStatement *)statement;

@end
