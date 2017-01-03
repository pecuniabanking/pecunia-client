/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

#import "Transfer.h"

@class BankAccount;
@class BankStatement;
@class TransactionLimits;

@interface ChargeByValueTransformer : NSValueTransformer

@end

@interface TransactionController : NSObject
{
    IBOutlet NSArrayController *countryController;
    BankAccount       *account;
    TransactionLimits *limits;
    NSString          *selectedCountry;
    NSArray           *internalAccounts;
    NSDictionary      *selCountryInfo;
}

@property (nonatomic, weak, readonly) Transfer            *currentTransfer;
@property (nonatomic, strong) IBOutlet NSObjectController *currentTransferController;
@property (nonatomic, strong) IBOutlet NSArrayController  *templateController;

- (BOOL)newTransferOfType: (TransferType)type;
- (BOOL)editExistingTransfer: (Transfer *)transfer;
- (BOOL)newTransferFromExistingTransfer: (Transfer *)transfer;
- (BOOL)newTransferFromTemplate: (TransferTemplate *)template;
- (void)saveTransfer: (Transfer *)transfer asTemplateWithName: (NSString *)name;
- (void)saveStatement: (BankStatement *)statement withType: (TransferType)type asTemplateWithName: (NSString *)name;
- (BOOL)editingInProgress;
- (void)cancelCurrentTransfer;
- (BOOL)finishCurrentTransferValidatingValue: (BOOL)valueValidation;

- (void)setManagedObjectContext: (NSManagedObjectContext *)context;

@end
