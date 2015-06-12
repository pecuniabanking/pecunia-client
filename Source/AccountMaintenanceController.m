/**
 * Copyright (c) 2008, 2015, Pecunia Project. All rights reserved.
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

#import "AccountMaintenanceController.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "HBCIController.h"
#import "BankingController.h"
#import "PecuniaError.h"
#import "BankUser.h"

#import "BWGradientBox.h"

#import "BusinessTransactionsController.h"

extern NSString *const CategoryColorNotification;
extern NSString *const CategoryKey;

@interface AccountMaintenanceController () {
    IBOutlet NSArrayController *accountTypesController;
}

@end;

@implementation AccountMaintenanceController

- (id)initWithAccount: (BankAccount *)acc {
    self = [super initWithWindowNibName: @"AccountMaintenance"];
    moc = MOAssistant.sharedAssistant.memContext;

    account = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: moc];

    changedAccount = acc;
    account.bankCode = acc.bankCode;
    account.accountNumber = acc.accountNumber;
    account.accountSuffix = acc.accountSuffix;
    account.owner = acc.owner;
    account.bankName = acc.bankName;
    account.name = acc.name;
    account.bic = acc.bic;
    account.iban = acc.iban;
    account.currency = acc.currency;
    account.collTransferMethod = acc.collTransferMethod;
    account.isStandingOrderSupported = acc.isStandingOrderSupported;
    account.noAutomaticQuery = acc.noAutomaticQuery;
    account.userId = acc.userId;
    account.categoryColor = acc.categoryColor;
    account.isHidden = acc.isHidden;
    account.noCatRep = acc.noCatRep;
    account.balance = acc.balance;
    account.plugin = acc.plugin;

    return self;
}

- (void)awakeFromNib {
    NSMutableArray *types = [[PluginRegistry getPluginList] mutableCopy];
    [types insertObject: @{ @"id": @"hbci", @"name": NSLocalizedString(@"AP146", nil) } atIndex: 0];
    accountTypesController.content = types;
    if ([changedAccount.isManual boolValue]) {
        
        // add special User
        BankUser *noUser  = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser" inManagedObjectContext: moc];
        noUser.name = NSLocalizedString(@"AP813", nil);
        [usersController addObject:noUser];
        [usersButton setEnabled:NO];
        
        int deltaHeight = [manAccountAddView frame].size.height - [accountAddView frame].size.height;

        // change window size
        NSRect frame = [[self window] frame];
        frame.size.height += deltaHeight;
        [[self window] setFrame: frame display: YES];

        manAccountAddView.frame = accountAddView.frame;
        [boxView replaceSubview: accountAddView with: manAccountAddView];

        [predicateEditor addRow: self];
        NSString *s = changedAccount.rule;
        if (s) {
            NSPredicate *pred = [NSCompoundPredicate predicateWithFormat: s];
            if ([pred class] != [NSCompoundPredicate class]) {
                NSCompoundPredicate *comp = [[NSCompoundPredicate alloc] initWithType: NSOrPredicateType subpredicates: @[pred]];
                pred = comp;
            }
            [predicateEditor setObjectValue: pred];
        }
    } else {
        // no manual account
        [usersController setManagedObjectContext:[[MOAssistant sharedAssistant] context]];
        NSSet *users = [changedAccount mutableSetValueForKey:@"users"];
        if ([users count] > 0) {
            [usersController setContent:[users allObjects]];
            for (BankUser *user in [usersController arrangedObjects]) {
                if ([user.userId isEqualToString: changedAccount.userId]) {
                    [usersController setSelectedObjects:@[user]];
                    break;
                }
            }
        } else {
            // no users are assigned to account - get users with same bank code
            for (BankUser *user in [BankUser allUsers]) {
                if ([user.bankCode isEqualToString:account.bankCode]) {
                    [usersController addObject:user];
                }
            }
        }
        
        // check if collective transfers are available - if not, disable collection transfer method popup
        BOOL collTransferSupported = [[HBCIController controller] isTransferSupported: TransferTypeCollectiveCreditSEPA forAccount: changedAccount];
        if (collTransferSupported == NO) {
            NSMenuItem *item = [collTransferButton itemAtIndex: 0];
            [item setTitle: NSLocalizedString(@"AP428", nil)];
            [collTransferButton setEnabled: NO];
        }
    }

    // Manually set up properties which cannot be set via user defined runtime attributes
    // (Color type is not available pre 10.7).
    topGradient.fillStartingColor = [NSColor colorWithCalibratedWhite: 59 / 255.0 alpha: 1];
    topGradient.fillEndingColor = [NSColor colorWithCalibratedWhite: 99 / 255.0 alpha: 1];
    backgroundGradient.fillColor = [NSColor whiteColor];
}

- (IBAction)cancel: (id)sender {
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }
    [self close];
    [moc reset];
    [NSApp stopModalWithCode: 0];
}

- (IBAction)ok: (id)sender {
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }

    [accountController commitEditing];
    if (![self check]) {
        return;
    }
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

    // update common data
    changedAccount.iban = account.iban;
    changedAccount.bic = account.bic;
    changedAccount.owner = account.owner;
    changedAccount.name = account.name;
    changedAccount.collTransferMethod = account.collTransferMethod;
    changedAccount.isStandingOrderSupported = account.isStandingOrderSupported;
    changedAccount.noAutomaticQuery = account.noAutomaticQuery;
    changedAccount.categoryColor = account.categoryColor;
    changedAccount.isHidden = account.isHidden;
    changedAccount.noCatRep = account.noCatRep;
    changedAccount.plugin = account.plugin;
    
    NSString *oldUserId = changedAccount.userId;

    if ([changedAccount.isManual boolValue] == YES) {
        NSPredicate *predicate = [predicateEditor objectValue];
        if (predicate) {
            changedAccount.rule = [predicate description];
        }
        if ([changedAccount.balance compare: account.balance] != NSOrderedSame) {
            [changedAccount updateBalanceWithValue:account.balance];
            [[BankingCategory bankRoot] updateCategorySums];
        }
    } else {
        changedAccount.accountSuffix = account.accountSuffix;
        
        // update userId
        NSArray *selectedUser = [usersController selectedObjects];
        if (selectedUser && [selectedUser count]>0) {
            BankUser *user = [selectedUser lastObject];
            if (oldUserId == nil || ![oldUserId isEqualToString:user.userId]) {
                changedAccount.userId = user.userId;
            }
        }
    }

    NSDictionary *info = @{CategoryKey: changedAccount};
    [NSNotificationCenter.defaultCenter postNotificationName: CategoryColorNotification
                                                      object: self
                                                    userInfo: info];
    [self close];

    // save all
    NSError *error = nil;
    if ([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
    }

    if (changedAccount.userId) {
        if (oldUserId && [changedAccount.userId isEqualToString:oldUserId]) {
            [[HBCIController controller] changeAccount: changedAccount];
        } else {
            [[HBCIController controller] setAccounts:@[changedAccount]];
        }
    }

    [moc reset];
    [NSApp stopModalWithCode: 1];
}

- (IBAction)predicateEditorChanged: (id)sender {
    // If the user deleted the first row, then add it again - no sense leaving the user with no rows.
    if ([predicateEditor numberOfRows] == 0) {
        [predicateEditor addRow: self];
    }
}

- (BOOL)check {
    if (account.iban.length > 0 && ![IBANtools isValidIBAN: account.iban]) {
        NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                        NSLocalizedString(@"AP70", nil),
                        NSLocalizedString(@"AP61", nil), nil, nil);
        return NO;
    }

    if (![changedAccount.accountSuffix isEqualToString: account.accountSuffix]) {
        if (changedAccount.accountSuffix != nil || account.accountSuffix != nil) {
            int result = NSRunAlertPanel(NSLocalizedString(@"AP814", nil),
                                         NSLocalizedString(@"AP205", nil),
                                         NSLocalizedString(@"AP4", nil),
                                         NSLocalizedString(@"AP3", nil), nil);
            if (result == NSAlertDefaultReturn) {
                account.accountSuffix = changedAccount.accountSuffix;
                return NO;
            }
        }
    }

    return YES;
}

- (IBAction)showSupportedBusinessTransactions: (id)sender {
    NSArray *result = [[HBCIController controller] getSupportedBusinessTransactions: account];
    if (result != nil) {
        if (supportedTransactionsSheet == nil) {
            transactionsController = [[BusinessTransactionsController alloc] initWithTransactions: result];
            supportedTransactionsSheet = [transactionsController window];
        }

        [NSApp  beginSheet: supportedTransactionsSheet
            modalForWindow: [self window]
             modalDelegate: nil
            didEndSelector: nil
               contextInfo: nil];
    }
}

@end
