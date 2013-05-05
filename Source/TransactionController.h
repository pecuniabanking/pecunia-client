/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

@class BankingController;
@class BankAccount;
@class TransactionLimits;


@interface ChargeByValueTransformer : NSValueTransformer

@end

@interface TransactionController : NSObject
{
    IBOutlet NSArrayController *countryController;
    IBOutlet NSWindow          *transferLocalWindow;
    IBOutlet NSWindow          *transferEUWindow;
    IBOutlet NSWindow          *transferInternalWindow;
    IBOutlet NSWindow          *transferSEPAWindow;
    IBOutlet NSPopUpButton     *countryButton;
    IBOutlet NSComboBox        *accountBox;
    IBOutlet NSComboBox        *chargeBox;
    IBOutlet NSDatePicker      *executionDatePicker;
    IBOutlet NSDrawer          *templatesDraw;
    IBOutlet NSView            *standardHelpView;
    IBOutlet NSView            *foreignHelpView;
    IBOutlet BankingController *bankingController;

    NSWindow *window;

    BankAccount       *account;
    TransactionLimits *limits;
    TransferType      transferType;
    NSString          *selectedCountry;
    NSArray           *internalAccounts;
    NSDictionary      *selCountryInfo;

    BOOL donation;
}

@property (unsafe_unretained, nonatomic, readonly) Transfer *currentTransfer;
@property (nonatomic, strong) IBOutlet NSObjectController   *currentTransferController;
@property (nonatomic, strong) IBOutlet NSArrayController    *templateController;

- (BOOL)newTransferOfType: (TransferType)type;
- (BOOL)editExistingTransfer: (Transfer *)transfer;
- (BOOL)newTransferFromExistingTransfer: (Transfer *)transfer;
- (BOOL)newTransferFromTemplate: (TransferTemplate *)template;
- (void)saveTransfer: (Transfer *)transfer asTemplateWithName: (NSString *)name;
- (BOOL)editingInProgress;
- (void)cancelCurrentTransfer;
- (BOOL)finishCurrentTransfer;
- (BOOL)validateCurrentTransfer;

- (void)transferOfType: (TransferType)tt forAccount: (BankAccount *)account; // deprecated
- (void)donateWithAccount: (BankAccount *)account; // deprecated
- (void)changeTransfer: (Transfer *)transfer; // deprecated
- (void)hideTransferDate: (BOOL)hide; // deprecated

- (IBAction)transferFinished: (id)sender; // deprecated
- (IBAction)nextTransfer: (id)sender; // deprecated
- (IBAction)cancel: (id)sender; // deprecated
- (IBAction)getDataFromTemplate: (id)sender; // deprecated
- (IBAction)countryDidChange: (id)sender; // deprecated
- (IBAction)sendTransfer: (id)sender; // deprecated

- (void)preparePurposeFields;
- (void)setManagedObjectContext: (NSManagedObjectContext *)context;

@end
