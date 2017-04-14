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

#import "TransactionController.h"
#import "BankingCategory.h"
#import "Transfer.h"
#import "BankStatement.h"
#import "TransactionLimits.h"
#import "MOAssistant.h"
#import "BankAccount.h"
#import "TransferTemplate.h"

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
    [templateController setSortDescriptors: @[sd]];
}

- (void)setManagedObjectContext: (NSManagedObjectContext *)context {
    [templateController setManagedObjectContext: context];
    [templateController prepareContent];
    [currentTransferController setManagedObjectContext: context];

    [self performSelector: @selector(checkTemplates) withObject: nil afterDelay: 0.2];
}

- (void)checkTemplates {
    // Convert old style of templates.
    for (TransferTemplate *template in templateController.arrangedObjects) {
        if (template.type.intValue == TransferTypeOldStandard
            || template.type.intValue == TransferTypeOldStandardScheduled
            || template.remoteIBAN == nil) { // Try again if a previous conversion failed.
            {
                if (template.type.intValue == TransferTypeOldStandard) {
                    template.type = @(TransferTypeSEPA);
                }

                if (template.type.intValue == TransferTypeOldStandardScheduled) {
                    template.type = @(TransferTypeSEPAScheduled);
                }

                NSDictionary *ibanResult = [IBANtools convertToIBAN: template.remoteAccount
                                                           bankCode: template.remoteBankCode
                                                        countryCode: @"de"
                                                    validateAccount: YES];
                if ([ibanResult[@"result"] intValue] == IBANToolsResultDefaultIBAN ||
                    [ibanResult[@"result"] intValue] == IBANToolsResultOk) {
                    template.remoteIBAN = ibanResult[@"iban"];
                }
            }
        }

        if (template.remoteBIC == nil || template.remoteBankName == nil) {
            InstituteInfo *info = nil;
            if (template.remoteIBAN != nil) {
                info = [HBCIBackend.backend infoForIBAN: template.remoteIBAN];
            } else {
                if (template.remoteBankCode != nil) {
                    info = [HBCIBackend.backend infoForBankCode: template.remoteBankCode];
                }
            }

            if (info != nil) {
                template.remoteBIC = info.bic;
                template.remoteBankName  = info.name;
            }
        }
    }
}

- (void)updateLimits {
    if (account != nil) {
        limits = [[HBCIBackend backend] transferLimits: account.defaultBankUser type: currentTransfer.type.intValue];
    }
}

- (void)prepareTransfer {
    // Update limits.
    [self updateLimits];

    // set default values
    NSDate *date;
    if (currentTransfer.type.intValue == TransferTypeOldStandardScheduled) {
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
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

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
    currentTransfer = [NSEntityDescription insertNewObjectForEntityForName: @"Transfer" inManagedObjectContext: context];
    currentTransfer.type = @((int)type);
    currentTransfer.changeState = TransferChangeNew;
    [self prepareTransfer];
    [currentTransferController setContent: currentTransfer];

    return YES;
}

- (BOOL)editExistingTransfer: (Transfer *)transfer {
    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    // Save any previous change.
    if ([context  hasChanges]) {
        if ([context save: &error] == NO) {
            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return NO;
        }
    }

    account = transfer.account;

    currentTransfer = transfer;
    [self prepareTransfer];
    currentTransfer.changeState = TransferChangeEditing;

    [currentTransferController setContent: transfer];

    return YES;
}

- (TransferType)convertTransferType: (TransferType)oldType {
    TransferType type;
    
    switch (oldType) {
        case TransferTypeOldStandard:
            type = TransferTypeSEPA; break;
        case TransferTypeOldStandardScheduled:
            type = TransferTypeSEPAScheduled; break;
        case TransferTypeInternal:
            type = TransferTypeInternalSEPA; break;
        default:
            type = oldType;
    }
    return type;
}

- (BOOL)newTransferFromExistingTransfer: (Transfer *)transfer {
    TransferType type;
    
    switch (transfer.type.intValue) {
        case TransferTypeOldStandard:
        case TransferTypeEU:
            type = TransferTypeSEPA; break;
        case TransferTypeOldStandardScheduled:
            type = TransferTypeSEPAScheduled; break;
        case TransferTypeInternal:
            type = TransferTypeInternalSEPA; break;
        default:
            type = transfer.type.intValue;
    }
    
    if (![self newTransferOfType: [self convertTransferType: transfer.type.intValue ]]) {
        return NO;
    }

    account = transfer.account;

    [currentTransfer copyFromTransfer: transfer withLimits: limits];
    currentTransfer.changeState = TransferChangeNew;

    // Determine the remote bank name again.
    NSString *bankName;
    if ([currentTransfer isSEPAorEU]) {
        bankName = [[HBCIBackend backend] bankNameForIBAN: currentTransfer.remoteIBAN];
    } else {
        bankName = [[HBCIBackend backend] bankNameForCode: currentTransfer.remoteBankCode];
    }
    if (bankName != nil) {
        currentTransfer.remoteBankName = bankName;
    }
    return YES;
}

- (BOOL)newTransferFromTemplate: (TransferTemplate *)template {
    if (![self newTransferOfType: [self convertTransferType:template.type.intValue]]) {
        return NO;
    }

    [currentTransfer copyFromTemplate: template withLimits: nil];
    currentTransfer.changeState = TransferChangeNew;

    // Determine the remote bank name again.
    NSString *bankName;
    if ([currentTransfer isSEPAorEU]) {
        bankName = [[HBCIBackend backend] bankNameForIBAN: currentTransfer.remoteIBAN];
    } else {
        bankName = [[HBCIBackend backend] bankNameForCode: currentTransfer.remoteBankCode];
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
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

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
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
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
    TransferType transferType;

    if (currentTransfer.valutaDate != nil) {
        switch (currentTransfer.type.intValue) {
            case TransferTypeSEPA: currentTransfer.type = @(TransferTypeSEPAScheduled); break;
            default: break;
        }
    }
    
    transferType = currentTransfer.type.intValue;

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
    if (transferType != TransferTypeSEPA && transferType != TransferTypeSEPAScheduled) {
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

        if (![IBANtools isValidIBAN: currentTransfer.remoteIBAN]) {
            NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                            NSLocalizedString(@"AP70", nil),
                            NSLocalizedString(@"AP61", nil), nil, nil);
            return NO;
        }

    }

    if (transferType == TransferTypeSEPA || transferType == TransferTypeSEPAScheduled) {
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
    if (transferType == TransferTypeSEPAScheduled) {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
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

    // Verify account/bank information.
    switch (transferType) {
        case TransferTypeEU:
            break;

        case TransferTypeSEPA:
        case TransferTypeSEPAScheduled:
        case TransferTypeInternalSEPA:
            if (![IBANtools isValidIBAN: currentTransfer.remoteIBAN]) {
                NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                                NSLocalizedString(@"AP70", nil),
                                NSLocalizedString(@"AP61", nil), nil, nil);
                return NO;
            }
            break;

        default: {
            // TODO: is it still necessary to limit account check to those countries?
            bool valid = [IBANtools isValidAccount: currentTransfer.remoteAccount
                                          bankCode: currentTransfer.remoteBankCode
                                       countryCode: currentTransfer.remoteCountry
                                           forIBAN: false];

            if (!valid) {
                NSRunAlertPanel(NSLocalizedString(@"AP59", nil),
                                NSLocalizedString(@"AP60", nil),
                                NSLocalizedString(@"AP61", nil), nil, nil);
                return NO;
            }
        }
    }
    return YES;
}

@end
