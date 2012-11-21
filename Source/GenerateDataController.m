/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

#import "GenerateDataController.h"
#include "MOAssistant.h"
#include "BankUser.h"
#include "Category.h"
#include "BankAccount.h"

@interface GenerateDataController ()

@end

@implementation GenerateDataController

- (id)init;
{
    self = [super initWithWindowNibName: @"GenerateDataController"];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)selectFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: NO];
    [panel setAllowedFileTypes: [NSArray arrayWithObject: @"txt"]];
    NSInteger result = [panel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        [self.path setStringValue: panel.URL.path];
    }
}

- (IBAction)close:(id)sender {
    [NSApp stopModal];
}

- (IBAction)start:(id)sender {
    NSError *error;
    NSString *path = self.path.stringValue;
    NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
    if (error) {
        NSLog(@"Error reading demo data template file at %@\n%@", path, [error localizedFailureReason]);
    } else {
        NSMutableDictionary *blocks = [NSMutableDictionary dictionary];
        NSString *blockName = @"";
        NSMutableArray *entries;

        NSArray *lines = [s componentsSeparatedByString: @"\n"];
        for (NSString *line in lines) {
            if (line.length == 0) {
                continue; // Empty line.
            }
            if ([line hasPrefix: @"["] && [line hasSuffix: @"]"]) {
                // Starting new block.
                if (entries != nil) {
                    [blocks setObject: entries forKey: blockName];
                }
                entries = [NSMutableArray array];
                blockName = [line substringWithRange: NSMakeRange(1, line.length - 2)];

                continue;
            }
            [entries addObject: line];
        }

        NSManagedObjectContext *context = MOAssistant.assistant.context;

        // Before adding new data remove old data if requested.
        if (self.removeOldDataCheckBox.state == 1) {
            [MOAssistant.assistant clearAllData];
            [Category recreateRoots];
            [Category createDefaultCategories];
        }

        // Once all data is read start by generating bank users and accounts.
        BOOL highVolume = [self.highVolumeRadioButton state] == NSOnState;
        NSArray *banks = [blocks objectForKey: @"Banks"];
        if (banks.count == 0) {
            return;
        }

        NSArray *accounts = [blocks objectForKey: @"Accounts"];

        Category *root = [Category bankRoot];
        for (NSString *bank in banks) {
            BankUser *user = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser"
                                                           inManagedObjectContext: context];
            user.name = bank;
            user.bankCode = @"1234567890";
            user.bankName = bank;
            user.bankURL = @"http://noip.com";
            user.port = @"1";
            user.hbciVersion = @"2.2";
            user.checkCert = [NSNumber numberWithBool: YES];
            user.country = @"DE";
            user.userId = @"0987654321";
            user.customerId = @"";
            user.secMethod = [NSNumber numberWithInt: SecMethod_PinTan];

            // Add account for this bank (actually the bank root to which the real accounts are attached).
            BankAccount *bankRoot = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount"
                                                                  inManagedObjectContext: context];
            bankRoot.bankName = bank;
            bankRoot.name = bank;
            bankRoot.bankCode = user.bankCode;
            bankRoot.currency = @"EUR";
            bankRoot.country = user.country;
            bankRoot.isBankAcc = [NSNumber numberWithBool: YES];
            bankRoot.parent = root;

            // To each bank root add a few accounts. The actual number depends on the data amount flag.
            NSMutableArray *accountList = [NSMutableArray array];
            NSUInteger accountCount = highVolume ? 10 : 3;
            while (accountList.count < accountCount) {
                NSUInteger randomIndex = arc4random() % [accounts count];
                NSString *value = [accounts objectAtIndex: randomIndex];
                if (![accountList containsObject: value]) {
                    [accountList addObject: value];
                }
            }

            for (NSString *accountName in accountList) {
                BankAccount *newAccount = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount"
                                                                        inManagedObjectContext: context];
                newAccount.bankCode = user.bankCode;
                newAccount.bankName = user.bankName;
                newAccount.isManual = [NSNumber numberWithBool: YES];
                newAccount.userId = user.userId;
                newAccount.customerId = user.customerId;
                //newAccount.collTransferMethod = account.collTransferMethod;
                newAccount.isStandingOrderSupported = [NSNumber numberWithBool: YES];

                newAccount.parent = bankRoot;
                newAccount.isBankAcc = [NSNumber numberWithBool: YES];

                //newAccount.iban = account.iban;
                //newAccount.bic = account.bic;
                //newAccount.owner = account.owner;
                newAccount.accountNumber = @"12341234";
                newAccount.name = accountName;
                newAccount.currency = bankRoot.currency;
                newAccount.country = bankRoot.country;
            }
        }

		if (![context save: &error]) {
			NSAlert *alert = [NSAlert alertWithError: error];
			[alert runModal];
			return;
		}
    }
}

@end
