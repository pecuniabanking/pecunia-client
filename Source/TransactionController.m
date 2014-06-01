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

#import "TransactionController.h"
#import "Category.h"
#import "Transfer.h"
#include "BankStatement.h"
#import "TransactionLimits.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "HBCIController.h"
#import "Country.h"
#import "TransferTemplate.h"
#import "NSDecimalNumber+PecuniaAdditions.h"

/**
 * Transform zero-based selector indices to one-based chargedBy property values for transfers.
 */
@implementation ChargeByValueTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue: (id)value {
    if (value == nil) {
        return nil;
    }

    if ([value intValue] == 0) {
        return value;
    }

    return @([value intValue] - 1);
}

- (id)reverseTransformedValue: (id)value {
    if (value == nil) {
        return nil;
    }

    return @([value intValue] + 1);
}

@end

@implementation TransactionController

@synthesize currentTransfer;
@synthesize currentTransferController;
@synthesize templateController;

- (void)awakeFromNib {
    // sort descriptor for transactions view
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
    NSArray          *sds = @[sd];
    [countryController setSortDescriptors: sds];

    // sort descriptor for template view
    sd = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
    sds = @[sd];
    [templateController setSortDescriptors: sds];
}

- (void)setManagedObjectContext: (NSManagedObjectContext *)context {
    [templateController setManagedObjectContext: context];
    [templateController prepareContent];
    [currentTransferController setManagedObjectContext: context];
}

- (void)updateLimits {
    limits = [[HBCIController controller] limitsForType: transferType account: account country: selectedCountry];
}

- (void)prepareTransfer {
    // Update limits.
    if (transferType != TransferTypeEU) {
        selectedCountry = nil;
        [self updateLimits];
        currentTransfer.remoteCountry = account.country;
    } else {
        NSArray *allowedCountries = [[HBCIController controller] allowedCountriesForAccount: account];
        [countryController setContent: allowedCountries];
        // sort descriptor for transactions view
        [countryController rearrangeObjects];

        if (selectedCountry) {
            int  idx = 0;
            BOOL found = NO;
            for (Country *country in [countryController arrangedObjects]) {
                if (country.code == selectedCountry) {
                    found = YES;
                    break;
                } else {
                    idx = idx + 1;
                }
            }
            if (found) {
                [countryController setSelectionIndex: idx];
            }
        } else {
            selectedCountry = [(Country *)[countryController arrangedObjects][0] code];
            [countryController setSelectionIndex: 0];
        }
        [self updateLimits];
        currentTransfer.remoteCountry = selectedCountry;

    }

    // set default values
    NSDate *date;
    if (transferType == TransferTypeOldStandardScheduled) {
        int setupTime;
        if (limits) {
            setupTime = [limits minSetupTime];
        } else {
            setupTime = 2;
        }
        date = [NSDate dateWithTimeIntervalSinceNow: setupTime * 86400];
        NSDate *transferDate = currentTransfer.valutaDate;
        if (transferDate == nil || [transferDate compare: date] == NSOrderedAscending) {
            currentTransfer.valutaDate = date;
        }
        setupTime = [limits maxSetupTime];
        if (setupTime > 0) {
            date = [NSDate dateWithTimeIntervalSinceNow: setupTime * 86400];
        }
    } else {
        date = NSDate.date;
    }

    // set date
    currentTransfer.date = date;
}

- (BOOL)newTransferOfType: (TransferType)type {
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    // Save any previous change.
    if ([context  hasChanges]) {
        NSError *error = nil;
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return NO;
        }
    }

    account = nil;
    transferType = type;
    currentTransfer = [NSEntityDescription insertNewObjectForEntityForName: @"Transfer" inManagedObjectContext: context];
    currentTransfer.type = @((int)transferType);
    currentTransfer.changeState = TransferChangeNew;
    [self prepareTransfer];
    [currentTransferController setContent: currentTransfer];

    return YES;
}

- (BOOL)editExistingTransfer: (Transfer *)transfer {
    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    // Save any previous change.
    if ([context  hasChanges]) {
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return NO;
        }
    }

    transferType = [transfer.type intValue];
    account = transfer.account;

    if (transferType == TransferTypeEU) {
        [self setValue: transfer.remoteCountry forKey: @"selectedCountry"];
    }

    currentTransfer = transfer;
    [self prepareTransfer];
    currentTransfer.changeState = TransferChangeEditing;

    [currentTransferController setContent: transfer];

    return YES;
}

- (BOOL)newTransferFromExistingTransfer: (Transfer *)transfer {
    if (![self newTransferOfType: [transfer.type intValue]]) {
        return NO;
    }

    transferType = [transfer.type intValue];
    account = transfer.account;

    if (transferType == TransferTypeEU) {
        [self setValue: transfer.remoteCountry forKey: @"selectedCountry"];
    }

    [self prepareTransfer];
    [currentTransfer copyFromTransfer: transfer withLimits: limits];
    currentTransfer.changeState = TransferChangeNew;

    // Determine the remote bank name again.
    NSString *bankName;
    if ([currentTransfer isSEPAorEU]) {
        bankName = [[HBCIController controller] bankNameForIBAN: currentTransfer.remoteIBAN];
    } else {
        bankName = [[HBCIController controller] bankNameForCode: currentTransfer.remoteBankCode];
    }
    if (bankName != nil) {
        currentTransfer.remoteBankName = bankName;
    }
    return YES;
}

- (BOOL)newTransferFromTemplate: (TransferTemplate *)template {
    if (![self newTransferOfType: [template.type intValue]]) {
        return NO;
    }

    transferType = [template.type intValue];

    [self prepareTransfer];
    [currentTransfer copyFromTemplate: template withLimits: nil];
    currentTransfer.changeState = TransferChangeNew;

    // Determine the remote bank name again.
    NSString *bankName;
    if ([currentTransfer isSEPAorEU]) {
        bankName = [[HBCIController controller] bankNameForIBAN: currentTransfer.remoteIBAN];
    } else {
        bankName = [[HBCIController controller] bankNameForCode: currentTransfer.remoteBankCode];
    }
    if (bankName != nil) {
        currentTransfer.remoteBankName = bankName;
    }
    return YES;
}

- (void)saveTransfer: (Transfer *)transfer asTemplateWithName: (NSString *)name {
    if (name == nil) {
        return;
    }
    name = [name stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length == 0) {
        return;
    }

    NSManagedObjectContext *context = templateController.managedObjectContext;
    TransferTemplate       *template = [NSEntityDescription insertNewObjectForEntityForName: @"TransferTemplate" inManagedObjectContext: context];
    template.name = name;
    template.type = transfer.type;

    // Make the template an unscheduled transfer.
    switch (template.type.intValue) {
        case TransferTypeSEPAScheduled:
            template.type = @(TransferTypeSEPA);
            break;

        case TransferTypeOldStandardScheduled:
            template.type = @(TransferTypeOldStandard);
            break;
    }

    template.remoteAccount = transfer.remoteAccount;
    template.remoteBankCode = transfer.remoteBankCode;
    template.remoteBankName = transfer.remoteBankName;
    template.remoteName = transfer.remoteName;
    template.purpose1 = transfer.purpose1;
    template.purpose2 = transfer.purpose2;
    template.purpose3 = transfer.purpose3;
    template.purpose4 = transfer.purpose4;
    template.remoteIBAN = transfer.remoteIBAN;
    template.remoteBIC = transfer.remoteBIC;
    template.remoteCountry = transfer.remoteCountry;
    template.value = transfer.value;
    template.currency = transfer.currency;
}

- (void)saveStatement: (BankStatement *)statement withType: (TransferType)type asTemplateWithName: (NSString *)name {
    if (name == nil) {
        return;
    }
    name = [name stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length == 0) {
        return;
    }

    NSManagedObjectContext *context = templateController.managedObjectContext;
    TransferTemplate       *template = [NSEntityDescription insertNewObjectForEntityForName: @"TransferTemplate" inManagedObjectContext: context];
    template.name = name;
    template.type = @(type);
    template.remoteAccount = statement.remoteAccount;
    template.remoteBankCode = statement.remoteBankCode;
    template.remoteBankName = statement.remoteBankName;
    template.remoteName = statement.remoteName;
    template.purpose1 = statement.floatingPurpose;
    template.remoteIBAN = statement.remoteIBAN;
    template.remoteBIC = statement.remoteBIC;
    template.remoteCountry = statement.remoteCountry;
    template.value = [statement.value abs];
    template.currency = statement.currency;
}

- (BOOL)editingInProgress {
    return currentTransferController.content != nil;
}

- (void)cancelCurrentTransfer {
    NSManagedObjectContext *context = [[MOAssistant assistant] context];

    [context deleteObject: currentTransfer];
    currentTransfer = nil;
    currentTransferController.content = nil;

}

/**
 * Validates the values entered for the current transfer and if everything seems correct
 * commits the changes. The value however is only validated if valueValidation is YES.
 * Returns YES if the current transfer could be finished, otherwise (e.g. for validation errors) NO.
 */
- (BOOL)finishCurrentTransferValidatingValue: (BOOL)valueValidation {
    [currentTransferController commitEditing];

    // prevent rounding issues
    currentTransfer.value = [currentTransfer.value rounded];

    if (![self validateCurrentTransferValidatingValue: valueValidation]) {
        return NO;
    }

    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return NO;
    }

    currentTransfer.changeState = TransferChangeUnchanged;
    currentTransferController.content = nil;

    return YES;
}

/**
 * Checks if the given string contains any character that is not allowed and alerts the
 * user if so.
 */
- (BOOL)validateCharacters: (NSString *)s {
    NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString: NSLocalizedString(@"AP200", nil)];

    if (s == nil || [s length] == 0) {
        return YES;
    }

    for (NSUInteger i = 0; i < [s length]; i++) {
        if ([cs characterIsMember: [s characterAtIndex: i]] == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP73", nil),
                            NSLocalizedString(@"AP74", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil,
                            nil,
                            [s characterAtIndex: i]);
            return NO;
        }
    }
    return YES;
}

/**
 * Validation of the entered values. Checks for empty or invalid entries.
 * Ignores the value however, if valueValidation is NO.
 * Returns YES if all entries are ok, otherwise NO.
 */
- (BOOL)validateCurrentTransferValidatingValue: (BOOL)valueValidation {
    BOOL         res;
    TransferType activeType = transferType;
    if (currentTransfer.valutaDate != nil) {
        switch (activeType) {
            case TransferTypeOldStandard: activeType = TransferTypeOldStandardScheduled; break;

            case TransferTypeSEPA: activeType = TransferTypeSEPAScheduled; break;

            default: break;
        }
    }

    if (![self validateCharacters: currentTransfer.purpose1]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.purpose2]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.purpose3]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.purpose4]) {
        return NO;
    }
    if (![self validateCharacters: currentTransfer.remoteName]) {
        return NO;
    }

    if (currentTransfer.remoteName == nil) {
        NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                        NSLocalizedString(@"AP54", nil),
                        NSLocalizedString(@"AP1", nil), nil, nil);
        return NO;
    }
    // Don't check remote account for EU transfers, instead IBAN.
    if (activeType != TransferTypeEU && activeType != TransferTypeSEPA && activeType != TransferTypeSEPAScheduled) {
        if (currentTransfer.remoteAccount == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP55", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    } else {
        // EU or SEPA transfer-
        if (currentTransfer.remoteIBAN == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP68", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }

        // Convert IBAN & BIC to uppercase.
        currentTransfer.remoteIBAN = [currentTransfer.remoteIBAN uppercaseString];
        currentTransfer.remoteBIC = [currentTransfer.remoteBIC uppercaseString];

        if ([[HBCIController controller] checkIBAN: currentTransfer.remoteIBAN] == NO) {
            NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                            NSLocalizedString(@"AP70", nil),
                            NSLocalizedString(@"AP61", nil), nil, nil);
            return NO;
        }

    }

    if (activeType == TransferTypeOldStandard || activeType == TransferTypeOldStandardScheduled) {
        if (currentTransfer.remoteBankCode == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP56", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    }

    if (activeType == TransferTypeSEPA || activeType == TransferTypeSEPAScheduled) {
        if (currentTransfer.remoteBIC == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP69", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    }

    if (valueValidation) {
        NSNumber *value = currentTransfer.value;
        if (value == nil) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP57", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
        if (value.doubleValue <= 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP50", nil),
                            NSLocalizedString(@"AP58", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    }
    // Purpose is not checked because it is not mandatory.

    // Check if the target date touches a weekend.
    if (transferType == TransferTypeOldStandardScheduled || transferType == TransferTypeSEPAScheduled) {
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier: NSGregorianCalendar];
        NSDateComponents *weekdayComponents =
            [gregorian components: NSCalendarUnitWeekday fromDate: currentTransfer.valutaDate];
        int weekday = [weekdayComponents weekday];
        if (weekday == 1 || weekday == 7) {
            NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                            NSLocalizedString(@"AP425", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }
    }

    if (activeType == TransferTypeEU) {
        currentTransfer.currency = [currentTransfer.currency uppercaseString];
        NSString *foreignCurr = [[[countryController selectedObjects] lastObject] currency];
        NSString *curr = currentTransfer.currency;
        //double   limit = 0.0;

        if (![curr isEqual: foreignCurr] && ![curr isEqual: @"EUR"] && ![curr isEqual: account.currency]) {
            NSRunAlertPanel(NSLocalizedString(@"AP67", nil), NSLocalizedString(@"AP63", nil),
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
        }

        /* todo
           if ([curr isEqual: foreignCurr] && limits) {
            limit = [limits foreignLimit];
           } else {limit = [limits localLimit]; }
           if (limit > 0 && [value doubleValue] > limit) {
            NSRunAlertPanel(NSLocalizedString(@"AP66", nil),
                            [NSString stringWithFormat: NSLocalizedString(@"AP62", nil), [limits localLimit]],
                            NSLocalizedString(@"AP1", nil), nil, nil);
            return NO;
           }
         */
    }


    // Verify account/bank information.
    switch (activeType) {
        case TransferTypeEU:
            break;

        case TransferTypeSEPA:
        case TransferTypeSEPAScheduled:
            res = [[HBCIController controller] checkIBAN: currentTransfer.remoteIBAN];
            if (!res) {
                NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                                NSLocalizedString(@"AP70", nil),
                                NSLocalizedString(@"AP61", nil), nil, nil);
                return NO;
            }
            break;

        default:
            // TODO: is it still necessary to limit account check to those countries?
            if ([currentTransfer.remoteCountry caseInsensitiveCompare: @"de"] == NSOrderedSame ||
                [currentTransfer.remoteCountry caseInsensitiveCompare: @"at"] == NSOrderedSame ||
                [currentTransfer.remoteCountry caseInsensitiveCompare: @"ch"] == NSOrderedSame ||
                [currentTransfer.remoteCountry caseInsensitiveCompare: @"ca"] == NSOrderedSame) {
                res = [[HBCIController controller] checkAccount: currentTransfer.remoteAccount
                                                        forBank: currentTransfer.remoteBankCode];

                if (!res) {
                    NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                                    NSLocalizedString(@"AP60", nil),
                                    NSLocalizedString(@"AP61", nil), nil, nil);
                    return NO;
                }
            }
    }
    return YES;
}

- (IBAction)countryDidChange: (id)sender {
    selectedCountry = [(Country *)[[countryController selectedObjects] lastObject] code];
    [self updateLimits];
    currentTransfer.remoteCountry = selectedCountry;
}

@end
