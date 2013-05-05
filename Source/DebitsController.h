/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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
#import "DebitsListview.h"
#import "PecuniaTabItem.h"

@class DebitDragImageView;
@class DeleteDebitTargetView;
@class BankAccount;
@class TransactionLimits;

@class TransactionController;
@class DebitsController;
@class DebitFormularView;

@interface DebitTemplateDragDestination : NSView
{
@private
    BOOL     formularVisible;
    NSString *currentDragDataType;
}

@property (nonatomic, weak) DebitsController *controller;

- (NSRect)dropTargetFrame;
- (void)hideFormular;
- (void)showFormular;

@end

@interface DebitsController : NSObject <PecuniaTabItem, NSWindowDelegate, NSTextFieldDelegate, DebitsActionDelegate>
{
    IBOutlet NSView                       *mainView;
    IBOutlet NSArrayController            *finishedDebits;
    IBOutlet NSArrayController            *pendingDebits;
    IBOutlet TransactionController        *transactionController;
    IBOutlet DebitsListView               *finishedDebitsListView;
    IBOutlet DebitsListView               *pendingDebitsListView;
    IBOutlet DebitTemplateDragDestination *rightPane;

    IBOutlet NSTextField   *titleText;
    IBOutlet NSTextField   *receiverText;
    IBOutlet NSPopUpButton *targetAccountSelector;
    IBOutlet NSComboBox    *receiverComboBox;
    IBOutlet NSTextField   *amountCurrencyText;
    IBOutlet NSTextField   *amountField;
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

    IBOutlet NSButton     *executeImmediatelyRadioButton;
    IBOutlet NSTextField  *executeImmediatelyText;
    IBOutlet NSTextField  *executeAtDateLabel;
    IBOutlet NSButton     *executeAtDateRadioButton;
    IBOutlet NSDatePicker *executionDatePicker;
    IBOutlet NSView       *calendarView;
    IBOutlet NSButton     *calendarButton;
    IBOutlet NSDatePicker *calendar;

    IBOutlet NSButton *queueItButton;
    IBOutlet NSButton *doItButton;
    IBOutlet NSButton *sendDebitsButton;

    IBOutlet DebitDragImageView    *debitImage;
    IBOutlet DeleteDebitTargetView *debitDeleteImage;

    IBOutlet NSTabView *debitTab;

@private
    TransactionLimits *limits;
    NSArray           *draggedDebits;
    NSUInteger        rowPositions[4];
}

@property (weak) IBOutlet DebitFormularView *debitFormular;
@property (weak) IBOutlet NSTextField       *dragToHereLabel;
@property (nonatomic, assign) BOOL          dropToEditRejected;

- (IBAction)sendDebits: (id)sender;
- (IBAction)showCalendar: (id)sender;
- (IBAction)targetAccountChanged: (id)sender;
- (IBAction)calendarChanged: (id)sender;
- (IBAction)queueDebit: (id)sender;
- (IBAction)sendDebit: (id)sender;
- (IBAction)deleteDebit: (id)sender;

- (void)draggingStartsFor: (DebitsListView *)sender;
- (BOOL)prepareDebitOfType: (TransferType)type;
- (BOOL)prepareEditingFromDragging: (id<NSDraggingInfo>)info;
- (BOOL)startEditingFromDragging: (id<NSDraggingInfo>)info;
- (BOOL)concludeDropDeleteOperation: (id<NSDraggingInfo>)info;
- (void)cancelEditing;
- (BOOL)editingInProgress;
- (BOOL)startDebitOfType: (TransferType)type withAccount: (BankAccount *)account;

@end
