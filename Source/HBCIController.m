/**
 * Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
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

#import "HBCIController.h"

#import "PecuniaError.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "MOAssistant.h"
#import "User.h"
#import "BankUser.h"
#import "HBCIBridge.h"
#import "Account.h"
#import "TransactionLimits.h"

#import "Country.h"
#import "ShortDate.h"
#import "CustomerMessage.h"
#import "TanMediaList.h"
#import "StatusBarController.h"
#import "SigningOptionsController.h"
#import "CallbackHandler.h"
#import "SystemNotification.h"
#import "NSString+PecuniaAdditions.h"
#import "AccountStatement.h"
#import "ResultWindowController.h"

static HBCIController *controller = nil;

@interface HBCIController () {
    HBCIBridge          *bridge;
    NSMutableDictionary *bankInfo;
    NSMutableDictionary *countries;

    NSInteger           pluginsRunning; // The count of currently running plugins.
    NSMutableDictionary *userList;      // Temporary storage when retrieving new statements.
    BOOL                retrieveStandingOrders; // Flag to indicate what we are currently retrieving
                                                // (statements or standing orders).
}

@end

@implementation HBCIController (Private)

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    bridge = [[HBCIBridge alloc] init];
    [bridge startup];
    
    bankInfo = [[NSMutableDictionary alloc] initWithCapacity: 10];
    countries = [[NSMutableDictionary alloc] initWithCapacity: 50];
    [self readCountryInfos];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(bankMessageReceived:)
                                                 name: PecuniaInstituteMessageNotification
                                               object: nil];
    return self;
}

@end

@implementation HBCIController


+ (id<HBCIBackend>)controller
{
    if (controller == nil) {
        controller = [HBCIController new];
    }
    return controller;
}

- (void)startProgress
{
    // TODO: see if we can reuse that in a different way (like showing a progress indicator).
    MessageLog.log.hasError = NO;
    [MessageLog.log.resultWindow clear];
}

- (void)stopProgress
{
    // TODO: see if we can reuse that in a different way.
    if (MessageLog.log.hasError) {
        [SystemNotification showMessage: NSLocalizedString(@"AP127", nil)
                              withTitle: NSLocalizedString(@"AP128", nil)];
    }
    [MessageLog.log.resultWindow showOnError];
}

- (void)readCountryInfos
{
    NSError *error = nil;

    NSString *path = [[NSBundle mainBundle] pathForResource: @"CountryInfo" ofType: @"txt"];
    NSString *data = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    NSArray  *lines = [data componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    NSString *line;
    for (line in lines) {
        NSArray *infos = [line componentsSeparatedByString: @";"];
        Country *country = [[Country alloc] init];
        country.code = infos[2];
        country.name = infos[0];
        country.currency = infos[3];
        countries[country.code] = country;
    }
}

- (NSDictionary *)countries
{
    return countries;
}

- (NSArray *)supportedVersions
{
    NSMutableArray *versions = [NSMutableArray arrayWithCapacity: 2];
    [versions addObject: @"220"];
    [versions addObject: @"300"];
    return versions;
}

- (void)appendTag: (NSString *)tag withValue: (NSString *)val to: (NSMutableString *)cmd
{
    if (val == nil) {
        return;
    }
    NSString *s = [val stringByEscapingXmlCharacters];
    if (val) {
        [cmd appendFormat: @"<%@>%@</%@>", tag, s, tag];
    }
}

- (PecuniaError *)initalizeHBCI
{
    PecuniaError *error = nil;
    NSString     *ppDir = [[MOAssistant sharedAssistant] passportDirectory];
    NSString     *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString     *libPath = [bundlePath stringByAppendingString: @"/Contents/"];

    NSMutableString *cmd = [NSMutableString stringWithString: @"<command name=\"init\">"];
    [self appendTag: @"passportPath" withValue: ppDir to: cmd];
    [self appendTag: @"path" withValue: ppDir to: cmd];
    [self appendTag: @"ddvLibPath" withValue: libPath to: cmd];
    [cmd appendString: @"</command>"];

    [bridge syncCommand: cmd error: &error];
    return error;
}

- (InstituteInfo *)infoForBankCode: (NSString *)bankCode
{
    if (bankCode == nil) {
        return nil;
    }

    NSDictionary *bicInfo = [IBANtools bicForBankCode: bankCode countryCode: @"de"];
    IBANToolsResult result = [bicInfo[@"result"] intValue];
    if (result == IBANToolsResultNoBIC || result == IBANToolsResultWrongValue) {
        return nil;
    }
    return [IBANtools instituteDetailsForBIC: bicInfo[@"bic"]];
}

- (InstituteInfo *)infoForIBAN: (NSString *)iban
{
    if (iban == nil || iban.length == 0) {
        return nil;
    }

    NSDictionary *bicInfo = [IBANtools bicForIBAN: iban];
    IBANToolsResult result = [bicInfo[@"result"] intValue];
    if (result == IBANToolsResultNoBIC || result == IBANToolsResultWrongValue) {
        return nil;
    }
    return [IBANtools instituteDetailsForBIC: bicInfo[@"bic"]];
}

- (BankParameter *)getBankParameterForUser: (BankUser *)user
{
    PecuniaError  *error = nil;
    BankParameter *bp = nil;

    if ([self registerBankUser: user error: &error]) {
        NSString *cmd = [NSString stringWithFormat: @"<command name=\"getBankParameterRaw\"><userBankCode>%@</userBankCode><userId>%@</userId></command>", user.bankCode, user.userId];
        bp = [bridge syncCommand: cmd error: &error];
    }
    if (error) {
        [error alertPanel];
        return nil;
    }
    return bp;
}

- (BankSetupInfo *)getBankSetupInfo: (NSString *)bankCode
{
    PecuniaError *error = nil;

    NSString      *cmd = [NSString stringWithFormat: @"<command name=\"getInitialBPD\"><bankCode>%@</bankCode></command>", bankCode];
    BankSetupInfo *info = [bridge syncCommand: cmd error: &error];
    if (error) {
        [error alertPanel];
        return nil;
    }
    return info;
}

- (NSString *)bankNameForCode: (NSString *)bankCode
{
    NSDictionary *bicInfo = [IBANtools bicForBankCode: bankCode countryCode: @"de"];
    IBANToolsResult result = [bicInfo[@"result"] intValue];
    if (result == IBANToolsResultNoBIC || result == IBANToolsResultWrongValue) {
        return NSLocalizedString(@"AP13", nil);
    }
    InstituteInfo *info = [IBANtools instituteDetailsForBIC: bicInfo[@"bic"]];
    return info.name.length > 0 ? info.name : NSLocalizedString(@"AP13", nil);
}

- (NSString *)bankNameForIBAN: (NSString *)iban
{
    NSDictionary *bicInfo = [IBANtools bicForIBAN: iban];
    IBANToolsResult result = [bicInfo[@"result"] intValue];
    if (result == IBANToolsResultNoBIC) {
        return NSLocalizedString(@"AP13", nil);
    }
    InstituteInfo *info = [IBANtools instituteDetailsForBIC: bicInfo[@"bic"]];
    return info.name.length > 0 ? info.name : NSLocalizedString(@"AP13", nil);
}

- (NSString *)bicForIBAN: (NSString*)iban
{
    NSDictionary *bicInfo = [IBANtools bicForIBAN: iban];
    IBANToolsResult result = [bicInfo[@"result"] intValue];
    if (result == IBANToolsResultNoBIC) {
        return nil;
    }
    return bicInfo[@"bic"];
}

- (NSArray *)getAccountsForUser: (BankUser *)user
{
    PecuniaError *error = nil;
    NSArray      *accs = nil;
    if ([self registerBankUser: user error: &error]) {
        NSString *cmd = [NSString stringWithFormat: @"<command name=\"getAccounts\"><userBankCode>%@</userBankCode><userId>%@</userId></command>", user.bankCode, user.userId];
        accs = [bridge syncCommand: cmd error: &error];
    }
    if (error != nil) {
        [error alertPanel];
        return nil;
    }
    return accs;
}

- (PecuniaError *)addAccount: (BankAccount *)account forUser: (BankUser *)user
{
    account.customerId = user.customerId;
    return [self setAccounts: @[account]];
}

- (PecuniaError *)setAccounts: (NSArray *)bankAccounts
{
    PecuniaError *error = nil;

    BankAccount *acc;
    for (acc in bankAccounts) {
        NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"setAccount\">"];
        [self appendTag: @"bankCode" withValue: acc.bankCode to: cmd];
        [self appendTag: @"accountNumber" withValue: acc.accountNumber to: cmd];
        [self appendTag: @"subNumber" withValue: acc.accountSuffix to: cmd];
        [self appendTag: @"country" withValue: [acc.country uppercaseString] to: cmd];
        [self appendTag: @"iban" withValue: acc.iban to: cmd];
        [self appendTag: @"bic" withValue: acc.bic to: cmd];
        [self appendTag: @"ownerName" withValue: acc.owner to: cmd];
        [self appendTag: @"name" withValue: acc.name to: cmd];
        [self appendTag: @"customerId" withValue: acc.customerId to: cmd];
        [self appendTag: @"userId" withValue: acc.userId to: cmd];
        [self appendTag: @"currency" withValue: acc.currency to: cmd];
        [cmd appendString: @"</command>"];
        [bridge syncCommand: cmd error: &error];
        if (error != nil) {
            return error;
        }
    }
    return nil;
}

- (PecuniaError *)changeAccount: (BankAccount *)account
{
    PecuniaError *error = nil;

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"changeAccount\">"];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
    [self appendTag: @"iban" withValue: account.iban to: cmd];
    [self appendTag: @"bic" withValue: account.bic to: cmd];
    [self appendTag: @"ownerName" withValue: account.owner to: cmd];
    [self appendTag: @"name" withValue: account.name to: cmd];
    [self appendTag: @"customerId" withValue: account.customerId to: cmd];
    [self appendTag: @"userId" withValue: account.userId to: cmd];
    [cmd appendString: @"</command>"];
    [bridge syncCommand: cmd error: &error];
    if (error != nil) {
        return error;
    }

    return nil;
}

- (NSString *)jobNameForType: (TransferType)tt
{
    switch (tt) {
        case TransferTypeOldStandard: return @"Ueb"; break;

        case TransferTypeOldStandardScheduled: return @"TermUeb"; break;

        case TransferTypeInternalSEPA: return @"Umb"; break;

        case TransferTypeEU: return @"UebForeign"; break;

        case TransferTypeSEPA: return @"UebSEPA"; break;

        case TransferTypeSEPAScheduled: return @"TermUebSEPA"; break;

        default:
            // collective transfers are handled special, only derive job names for supported jobs
            return nil;
    }
}

- (BOOL)isTransactionSupported: (TransactionType)tt forAccount: (BankAccount *)account
{
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSPredicate            *predicate = [NSPredicate predicateWithFormat: @"account = %@ AND type = %d", account, tt];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];

    NSError *error = nil;
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error != nil) {
        return NO;
    }

    if ([result count] == 0) {
        return NO;
    }
    return YES;
}

- (BOOL)isTransactionSupported: (TransactionType)tt forUser: (BankUser *)user
{
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSPredicate            *predicate = [NSPredicate predicateWithFormat: @"user = %@ AND type = %d", user, tt];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];
    
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error != nil) {
        return NO;
    }
    
    if ([result count] == 0) {
        return NO;
    }
    return YES;
}


- (BOOL)isTransferSupported: (TransferType)tt forAccount: (BankAccount *)account
{
    TransactionType transactionType;
    switch (tt) {
        case TransferTypeOldStandard: transactionType = TransactionType_TransferStandard; break;

        case TransferTypeEU: transactionType = TransactionType_TransferEU; break;

        case TransferTypeOldStandardScheduled: transactionType = TransactionType_TransferDated; break;

        case TransferTypeInternalSEPA: transactionType = TransactionType_TransferInternalSEPA; break;

        case TransferTypeCollectiveCreditSEPA: transactionType = TransactionType_TransferCollectiveCreditSEPA; break;
            
        case TransferTypeSEPA: transactionType = TransactionType_TransferSEPA; break;

        case TransferTypeSEPAScheduled: transactionType = TransactionType_TransferSEPAScheduled; break;
            
        default: return NO; // default is needed because of OLD transfer types which are not supported any longer
            
    }
    
    return [self isTransactionSupported:transactionType forAccount:account];
}


- (NSDictionary *)getRestrictionsForJob: (NSString *)jobname account: (BankAccount *)account
{
    NSDictionary *result;
    PecuniaError *error = nil;
    if (account == nil) {
        return nil;
    }

    BankUser *user = [account defaultBankUser];
    if (user == nil) {
        return nil;
    }

    if ([self registerBankUser: user error: &error] == NO) {
        if (error) {
            [error alertPanel];
        }
        return nil;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getJobRestrictions\">"];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"jobName" withValue: jobname to: cmd];
    [cmd appendString: @"</command>"];
    result = [bridge syncCommand: cmd error: &error];
    return result;
}

- (TransactionLimits *)getLimitsForJob: (NSString *)jobName account: (BankAccount *)account
{
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    TransactionLimits      *limits = nil;

    if (account == nil) {
        return nil;
    }

    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"TransactionLimits" inManagedObjectContext: context];
    [fetchRequest setEntity: entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"account = %@ AND user = %@ AND jobName = %@", account, [account defaultBankUser], jobName];
    [fetchRequest setPredicate: predicate];

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest: fetchRequest error: &error];
    if (fetchedObjects == nil || [fetchedObjects count] == 0) {
        // get restrictions and insert
        NSDictionary *restr = [self getRestrictionsForJob: jobName account: account];
        if (restr) {
            limits = (TransactionLimits *)[NSEntityDescription insertNewObjectForEntityForName: @"TransactionLimits" inManagedObjectContext: context];
            limits.jobName = jobName;
            limits.account = account;
            limits.user = [account defaultBankUser];
            [limits setLimitsWithData: restr];

            [context save: &error];
        }
    } else {
        limits = [fetchedObjects lastObject];
    }
    return limits;
}

- (NSArray *)allowedCountriesForAccount: (BankAccount *)account
{
    NSMutableArray *res = [NSMutableArray arrayWithCapacity: 20];
    NSDictionary   *restr = [self getRestrictionsForJob: @"UebForeign" account: account];
    NSArray        *countryInfo = [restr valueForKey: @"countryInfos"];
    NSString       *s;

    // get texts for allowed countries - build up PopUpButton data
    for (s in countryInfo) {
        NSArray *comps = [s componentsSeparatedByString: @";"];
        Country *country = [countries valueForKey: comps[0]];
        if (country != nil) {
            [res addObject: country];
        }
    }
    if ([res count] == 0) {
        return [countries allValues];
    }

    return res;
}

- (TransactionLimits *)limitsForType: (TransferType)tt account: (BankAccount *)account country: (NSString *)ctry
{
    NSString *jobName = [self jobNameForType: tt];
    return [self getLimitsForJob: jobName account: account];
}

- (TransactionLimits *)standingOrderLimitsForAccount: (BankAccount *)account action: (StandingOrderAction)action
{
    NSString *jobName = nil;

    switch (action) {
        case stord_change: jobName = @"DauerSEPAEdit"; break;

        case stord_create: jobName = @"DauerSEPANew"; break;

        case stord_delete: jobName = @"DauerSEPADel"; break;
    }
    if (jobName == nil) {
        return nil;
    }
    return [self getLimitsForJob: jobName account: account];
}

- (PecuniaError *)sendCollectiveTransfer: (NSArray *)transfers
{
    PecuniaError *err = nil;
    Transfer     *transfer;

    if ([transfers count] == 0) {
        return nil;
    }

    // Prüfen ob alle Überweisungen das gleiche Konto betreffen
    transfer = [transfers lastObject];
    for (Transfer *transf in transfers) {
        if (transfer.account != transf.account) {
            return [PecuniaError errorWithMessage: NSLocalizedString(@"424", nil) title: NSLocalizedString(@"AP423", nil)];
        }
    }
    SigningOption *option = [self signingOptionForAccount: transfer.account];
    if (option == nil) {
        return nil;
    }
    Security.currentSigningOption = option;

    // Registriere gewählten User
    BankUser *user = [self getBankUserForId: option.userId bankCode: transfer.account.bankCode];
    if (user == nil) {
        return [PecuniaError errorWithMessage: [NSString stringWithFormat: NSLocalizedString(@"424", nil), option.userId] title: NSLocalizedString(@"AP355", nil)];
    }

    if ([user.tanMediaFetched boolValue] == NO) {
        [self updateTanMediaForUser: user];
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"sendCollectiveTransfer\">"];
    [self appendTag: @"bankCode" withValue: transfer.account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: transfer.account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: transfer.account.accountSuffix to: cmd];
    [self appendTag: @"customerId" withValue: transfer.account.customerId to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [cmd appendString: @"<transfers type=\"list\">"];
    for (transfer in transfers) {
        [cmd appendString: @"<transfer>"];
        [self appendTag: @"remoteAccount" withValue: transfer.remoteAccount to: cmd];
        [self appendTag: @"remoteBankCode" withValue: transfer.remoteBankCode to: cmd];
        [self appendTag: @"remoteName" withValue: transfer.remoteName to: cmd];
        [self appendTag: @"purpose1" withValue: transfer.purpose1 to: cmd];
        [self appendTag: @"purpose2" withValue: transfer.purpose2 to: cmd];
        [self appendTag: @"purpose3" withValue: transfer.purpose3 to: cmd];
        [self appendTag: @"purpose4" withValue: transfer.purpose4 to: cmd];
        [self appendTag: @"currency" withValue: transfer.currency to: cmd];
        [self appendTag: @"remoteBIC" withValue: transfer.remoteBIC to: cmd];
        [self appendTag: @"remoteIBAN" withValue: transfer.remoteIBAN to: cmd];
        [self appendTag: @"currency" withValue:transfer.currency to:cmd];
        [self appendTag: @"remoteCountry" withValue: transfer.remoteCountry == nil ? @"DE": [transfer.remoteCountry uppercaseString] to: cmd];

        [self appendTag: @"value" withValue: [[transfer.value outboundNumber] stringValue] to: cmd];
        [cmd appendString: @"</transfer>"];
    }
    [cmd appendString: @"</transfers></command>"];

    [self startProgress];
    NSNumber *isOk = [bridge syncCommand: cmd error: &err];
    [self stopProgress];
    if (err == nil && [isOk boolValue] == YES) {
        for (transfer in transfers) {
            transfer.isSent = @YES;
        }
    }
    return err;
}

/**
 * Sends out the given transfer by grouping them by bank and issuing one command per bank.
 * TODO: If supported by the bank grouped transfers should use consolidated transfers instead individual ones.
 */
- (BOOL)sendTransfers: (NSArray *)transfers
{
    PecuniaError *err = nil;
    Transfer     *transfer;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"y-MM-dd";

    NSMutableDictionary *accountTransferRegister = [NSMutableDictionary dictionaryWithCapacity: 10];

    // Group transfers by BankAccount
    for (transfer in transfers) {
        BankAccount    *account = transfer.account;
        NSMutableArray *accountTransfers = accountTransferRegister[account];
        if (accountTransfers == nil) {
            accountTransfers = [NSMutableArray arrayWithCapacity: 10];
            accountTransferRegister[account] = accountTransfers;
        }
        [accountTransfers addObject: transfer];
    }
    // Now go for each bank.
    BOOL allSent = YES;

    for (BankAccount *account in [accountTransferRegister allKeys]) {
        SigningOption *option = [self signingOptionForAccount: account];
        if (option == nil) {
            continue;
        }
        Security.currentSigningOption = option;

        // Registriere gewählten User
        BankUser *user = [self getBankUserForId: option.userId bankCode: account.bankCode];
        if (user == nil) {
            continue;
        }

        if ([user.tanMediaFetched boolValue] == NO) {
            [self updateTanMediaForUser: user];
        }

        for (transfer in accountTransferRegister[account]) {
            NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"sendTransfer\">"];
            [self appendTag: @"bankCode" withValue: transfer.account.bankCode to: cmd];
            [self appendTag: @"accountNumber" withValue: transfer.account.accountNumber to: cmd];
            [self appendTag: @"subNumber" withValue: transfer.account.accountSuffix to: cmd];
            [self appendTag: @"customerId" withValue: transfer.account.customerId to: cmd];
            [self appendTag: @"userId" withValue: user.userId to: cmd];
            [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
            [self appendTag: @"remoteAccount" withValue: transfer.remoteAccount to: cmd];
            [self appendTag: @"remoteBankCode" withValue: transfer.remoteBankCode to: cmd];
            [self appendTag: @"remoteName" withValue: transfer.remoteName to: cmd];
            [self appendTag: @"purpose1" withValue: transfer.purpose1 to: cmd];
            [self appendTag: @"purpose2" withValue: transfer.purpose2 to: cmd];
            [self appendTag: @"purpose3" withValue: transfer.purpose3 to: cmd];
            [self appendTag: @"purpose4" withValue: transfer.purpose4 to: cmd];
            [self appendTag: @"currency" withValue: transfer.currency to: cmd];
            [self appendTag: @"remoteBIC" withValue: transfer.remoteBIC to: cmd];
            [self appendTag: @"remoteIBAN" withValue: transfer.remoteIBAN to: cmd];
            [self appendTag: @"remoteCountry" withValue: transfer.remoteCountry == nil ? @"DE": [transfer.remoteCountry uppercaseString] to: cmd];
            if ([transfer.type intValue] == TransferTypeOldStandardScheduled || transfer.type.intValue == TransferTypeSEPAScheduled) {
                NSString *fromString = [dateFormatter stringFromDate: transfer.valutaDate];
                [self appendTag: @"valutaDate" withValue: fromString to: cmd];
            }
            TransferType tt = [transfer.type intValue];
            NSString     *type;
            switch (tt) {
                case TransferTypeOldStandard:
                    type = @"standard";
                    break;

                case TransferTypeOldStandardScheduled:
                case TransferTypeSEPAScheduled: // XXX: make this an own string type.
                    type = @"dated";
                    break;

                case TransferTypeInternalSEPA:
                    type = @"internal";
                    break;

                case TransferTypeDebit:
                    type = @"last";
                    break;

                case TransferTypeSEPA:
                    type = @"sepa";
                    break;

                case TransferTypeEU:
                    type = @"foreign";
                    [self appendTag: @"chargeTo" withValue: [transfer.chargedBy description]  to: cmd];
                    [self appendTag:@"bankName" withValue:transfer.remoteBankName to:cmd];
                    break;

                case TransferTypeCollectiveCredit:
                case TransferTypeCollectiveDebit:
                case TransferTypeCollectiveCreditSEPA:
                    LogError(@"Collective transfer must be sent with 'sendCollectiveTransfer'");
                    continue;
                    break;
                    
                default:
                    // not supported
                    LogError(@"Transfer %d type not supported any longer", tt);
                    return false;
            }

            [self appendTag: @"type" withValue: type to: cmd];
            [self appendTag: @"value" withValue: [[transfer.value outboundNumber] stringValue] to: cmd];

            NSURL *uri = [[transfer objectID] URIRepresentation];
            [self appendTag: @"transferId" withValue: [uri absoluteString] to: cmd];
            [cmd appendString: @"</command>"];

            [self startProgress];
            NSNumber *isOk = [bridge syncCommand: cmd error: &err];
            if (err) {
                [err logMessage];
            }
            [self stopProgress];
            
            if (err == nil && [isOk boolValue] == YES) {
                transfer.isSent = @YES;
            } else {
                allSent = NO;
            }
        }
    }
    return allSent;
}

- (PecuniaError *)addBankUser: (BankUser *)user
{
    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"addUser\">"];

    [self appendTag: @"name" withValue: user.name to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"version" withValue: user.hbciVersion to: cmd];

    SecurityMethod secMethod = [user.secMethod intValue];
    if (secMethod == SecMethod_PinTan) {
        [self appendTag: @"host" withValue: [user.bankURL stringByReplacingOccurrencesOfString: @"https://" withString: @""] to: cmd];
        [self appendTag: @"port" withValue: @"443" to: cmd];
        [self appendTag: @"passportType" withValue: @"PinTan" to: cmd];
        if ([user.noBase64 boolValue] == NO) {
            [self appendTag: @"filter" withValue: @"Base64" to: cmd];
        }
    }

    if (secMethod == SecMethod_DDV) {
        [self appendTag: @"ddvReaderIdx" withValue: [user.ddvReaderIdx stringValue] to: cmd];
        [self appendTag: @"ddvPortIdx" withValue: [user.ddvPortIdx stringValue] to: cmd];
        [self appendTag: @"passportType" withValue: @"DDV" to: cmd];
        [self appendTag: @"host" withValue: user.bankURL to: cmd];
    }

    [cmd appendString: @"</command>"];

    [self startProgress];

    // create bank user at the bank
    if (secMethod != SecMethod_Script) {
        User *usr = [bridge syncCommand: cmd error: &error];
        if (error) {
            [self stopProgress];
            return error;
        }
        
        // update external user data
        if (secMethod == SecMethod_DDV) {
            user.bankCode = usr.bankCode;
            user.bankName = usr.bankName;
            user.customerId = usr.customerId;
            user.hbciVersion = usr.hbciVersion;
            user.country = usr.country;
            user.chipCardId = usr.chipCardId;
        }
        
        if (secMethod == SecMethod_PinTan) {
            user.hbciVersion = usr.hbciVersion;
            user.bankName = usr.bankName;
            user.customerId = usr.customerId;
        }
    
        // Update user's accounts
        [self updateBankAccounts: usr.accounts forUser: user];
        
        // update supported transactions
        error = [self updateSupportedTransactionsForAccounts: usr.accounts user: user];
        if (error != nil) {
            [self stopProgress];
            return error;
        }
        
        // also update TAN media and TAN methods
        if (secMethod == SecMethod_PinTan) {
            error = [self updateTanMethodsForUser: user];
            if (error != nil) {
                [self stopProgress];
                return error;
            }
            error = [self updateTanMediaForUser: user];
            if (error != nil) {
                [self stopProgress];
                return error;
            }
        }
    }
    return nil;
}

- (BOOL)deleteBankUser: (BankUser *)user
{
    PecuniaError *error = nil;

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"deletePassport\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];

    SecurityMethod secMethod = [user.secMethod intValue];
    if (secMethod == SecMethod_PinTan) {
        [self appendTag: @"passportType" withValue: @"PinTan" to: cmd];
    } else {
        if (user.chipCardId == nil) {
            // allow deletion if chipCardId is empty
            return YES;
        }
        [self appendTag: @"passportType" withValue: @"DDV" to: cmd];
        [self appendTag: @"chipCardId" withValue: user.chipCardId to: cmd];
    }

    [cmd appendString: @"</command>"];

    [bridge syncCommand: cmd error: &error];
    if (error == nil) {
        NSString *s = [NSString stringWithFormat: @"PIN_%@_%@", user.bankCode, user.userId];
        [Security deletePasswordForService: @"Pecunia PIN" account: s];
    } else {
        [error alertPanel];
        return NO;
    }
    return YES;
}

- (PecuniaError *)setLogLevel: (HBCILogLevel)level
{
    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"setLogLevel\"><logLevel>%d</logLevel></command>", (int)level];
    [bridge syncCommand: cmd error: &error];
    return error;
}

- (CCSettlementList *)getCCSettlementListForAccount: (BankAccount *)account
{
    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithString: @"<command name=\"getCCSettlementList\">"];

    [self startProgress];

    BankUser *user = [account defaultBankUser];
    if (user == nil) {
        return nil;
    }

    // BankUser registrieren
    if ([self registerBankUser: user error: &error] == NO) {
        [error alertPanel];
        return nil;
    }

    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [cmd appendString: @"</command>"];

    CCSettlementList *result = [bridge syncCommand: cmd error: &error];
    [self stopProgress];

    if (error) {
        [error alertPanel];
        return nil;
    }
    if (result == nil) {
        LogError(@"Unexpected result for getCCSettlementList: nil");
        return nil;
    }
    return result;
}

- (AccountStatementParameters *)getAccountStatementParametersForUser: (BankUser *)user {
    LogEnter;
    
    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getAccountStatementParameters\">"];
    
    // BankUser registrieren
    if ([self registerBankUser: user error: &error] == NO) {
        [error alertPanel];
        return nil;
    }

    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [cmd appendString: @"</command>"];

    AccountStatementParameters *result = [bridge syncCommand: cmd error: &error];
    
    if (error) {
        [error alertPanel];
        
        LogLeave;
        return nil;
    }

    LogLeave;
    return result;
}

- (AccountStatement *)getAccountStatement: (int)number year: (int)year account: (BankAccount *)account {
    LogEnter;
    
    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getAccountStatement\">"];
    
    BankUser *user = [account defaultBankUser];
    if (user == nil) {
        return nil;
    }
    
    // BankUser registrieren
    if ([self registerBankUser: user error: &error] == NO) {
        [error alertPanel];
        return nil;
    }
    
    // which format?
    AccountStatementParameters *params = [self getAccountStatementParametersForUser:user];
    if (params == nil) {
        return nil;
    }
    if ([params supportsFormat:AccountStatement_PDF]) {
        [self appendTag: @"format" withValue: @"3" to:cmd];
    } else {
        if ([params supportsFormat:AccountStatement_MT940]) {
            [self appendTag: @"format" withValue: @"1" to:cmd];
        } else {
            // todo: Alert
            LogError(@"Account statement format is not supported");
        }
    }
    
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    if (year > 0 && number > 0) {
        [self appendTag: @"number" withValue: [NSString stringWithFormat:@"%d", number] to:cmd];
        [self appendTag: @"year" withValue: [NSString stringWithFormat:@"%d", year] to:cmd];
    }
    
    [cmd appendString: @"</command>"];
    
    [self startProgress];
    
    AccountStatement *result = [bridge syncCommand: cmd error: &error];
    [self stopProgress];
    
    if (error) {
        [error alertPanel];
        
        LogLeave;
        return nil;
    }
    if (result == nil) {
        LogError(@"Unexpected result for getAccountStatement: nil");
    }

    result.number = @(number);
    if (result.format.intValue == AccountStatement_MT940) {
        [result convertStatementsToPDFForAccount:account ];
    }
    
    LogLeave;
    return result;
}

- (CreditCardSettlement *)getCreditCardSettlement: (NSString *)settleId forAccount: (BankAccount *)account
{
    LogEnter;

    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getCCSettlement\">"];

    BankUser *user = [account defaultBankUser];
    if (user == nil) {
        return nil;
    }

    // BankUser registrieren
    if ([self registerBankUser: user error: &error] == NO) {
        [error alertPanel];
        return nil;
    }

    [self appendTag: @"settleID" withValue: settleId to: cmd];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [cmd appendString: @"</command>"];

    [self startProgress];

    CreditCardSettlement *result = [bridge syncCommand: cmd error: &error];
    [self stopProgress];

    if (error) {
        [error alertPanel];

        LogLeave;
        return nil;
    }
    if (result == nil) {
        LogError(@"Unexpected result for getCCSettlement: nil");
    }

    LogLeave;
    return result;
}

- (void)handleQueryResults: (NSArray *)results {
    for (BankQueryResult *queryResult in results) {
        if (queryResult.type == BankQueryTypeCreditCard) {
            // Credit Card Statements, balance field is filled with current account balance.
            // Check if order needs to be reversed.
            if (queryResult.statements.count > 0) {
                BankStatement *first = queryResult.statements.firstObject;
                BankStatement *last = queryResult.statements.lastObject;

                if ([first.date compare: last.date] == NSOrderedDescending) {
                    NSMutableArray *statements = [NSMutableArray arrayWithCapacity: queryResult.statements.count];
                    for (NSInteger i = queryResult.statements.count - 1; i >= 0; --i) {
                        [statements addObject: queryResult.statements[i]];
                    }
                    queryResult.statements = statements;
                }
            }

            // Calculate balances.
            NSDecimalNumber *balance = queryResult.balance;
            for (NSInteger i = queryResult.statements.count - 1; i >= 0; --i) {
                BankStatement *statement = queryResult.statements[i];
                statement.saldo = balance;
                balance = [balance decimalNumberBySubtracting: statement.value];
            }
        } else {
            // Standard Statements.
            // Saldo of the last statement which is not preliminary becomes the current saldo.
            NSInteger i = queryResult.statements.count - 1;
            while (i >= 0) {
                BankStatement *statement = queryResult.statements[i];
                if (!statement.isPreliminary.boolValue) {
                    queryResult.balance = statement.saldo;
                    break;
                }
                --i;
            }
        }
    }
}

- (void)asyncCommandCompletedWithResult: (id)result error: (PecuniaError *)err {

    // Statement/standing order retrieval doesn't set the account a query result is for (TODO)
    // so we use the original accounts list to do the assignments, assuming that the results
    // are in the same order as the accounts for which they had been requested.
    // Plugin results don't need this extra handling.
    if (err == nil && [result count] > 0) {
        if ([result[0] account] == nil) {
            NSUInteger currentAccount = 0;
            NSArray *accounts = userList[userList.allKeys[0]];
            if (accounts.count != [result count]) {
                LogWarning(@"asyncCommandCompletedWithResult: account list size and result list size differ.");
            }
            for (BankQueryResult *queryResult in result) {
                if (currentAccount < accounts.count) {
                    queryResult.account = accounts[currentAccount++];
                }
            }
        }
        [self handleQueryResults: result];
    }

    if (err) {
        [err logMessage];
    } else {
        NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsNotification object: result];
        [[NSNotificationCenter defaultCenter] postNotification: notification];
    }

    // Done with this user, continue with next one.
    // Synchronize access with the plugin calls running in parallel.
    @synchronized(userList) {
        NSString *userId = userList.allKeys[0];
        [userList removeObjectForKey: userId];

        if (userList.count > 0) {
            userId = userList.allKeys[0];

            // Delay execution to next run loop, so we can finish the task at hand properly first.
            if (retrieveStandingOrders) {
                [self performSelector: @selector(getUserStandingOrders:) withObject: userList[userId] afterDelay: 0.0];
            } else {
                [self performSelector: @selector(getUserStatements:) withObject: userList[userId] afterDelay: 0.0];
            }
            return;
        }

        if (pluginsRunning == 0) {
            NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsFinalizeNotification object: nil];
            [[NSNotificationCenter defaultCenter] postNotification: notification];
            [self stopProgress];
        }
    }
}

/**
 * Triggers retrieval of statements for all accounts for a given user (all accounts have the same
 * user id) using the HBCI path.
 */
- (void)getUserStatements: (NSArray *)accounts {
    if (accounts.count == 0) {
        [self asyncCommandCompletedWithResult: nil error: nil];
        return;
    }

    // XXX: the accounts array can contain accounts from different banks, hence a single bank user doesn't cut it.
    BankAccount *account = accounts.firstObject;
    BankUser *user = [self getBankUserForId: account.userId bankCode: account.bankCode];
    if (user == nil) {
        [self asyncCommandCompletedWithResult:nil error: nil];
        return;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getAllStatements\"><accinfolist type=\"list\">"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"y-MM-dd";
    
    for (account in accounts) {
        [cmd appendFormat: @"<accinfo><bankCode>%@</bankCode><accountNumber>%@</accountNumber>",
         account.bankCode, account.accountNumber];
        [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];

        NSInteger maxStatDays = 0;
        if ([NSUserDefaults.standardUserDefaults boolForKey: @"limitStatsAge"]) {
            maxStatDays = [[NSUserDefaults standardUserDefaults] integerForKey: @"maxStatDays"];
        }

        if (account.latestTransferDate == nil && maxStatDays > 0) {
            account.latestTransferDate = [[NSDate alloc] initWithTimeInterval: -86400 * maxStatDays sinceDate: NSDate.date];
        }

        if (account.latestTransferDate != nil) {
            NSString *fromString = nil;
            NSDate   *fromDate = [[NSDate alloc] initWithTimeInterval: -605000 sinceDate: account.latestTransferDate];
            fromString = [dateFormatter stringFromDate: fromDate];
            if (fromString) {
                [cmd appendFormat: @"<fromDate>%@</fromDate>", fromString];
            }
        }
        [self appendTag: @"userId" withValue: user.userId to: cmd];
        [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
        [cmd appendString: @"</accinfo>"];
    }
    [cmd appendString: @"</accinfolist></command>"];
    [bridge asyncCommand: cmd sender: self];
}

- (void)getStatements: (NSArray *)accounts {
    if (userList.count > 0 || accounts.count == 0) {
        return; // We are currently retrieving statements or there's nothing to get for.
    }

    retrieveStandingOrders = NO;

    // Organize accounts by user in order to get all statements for all accounts of a given user.
    userList = [NSMutableDictionary new];
    NSMutableDictionary *accountsWithPlugins = [NSMutableDictionary new];
    for (BankAccount *account in accounts) {

        // Take out those accounts and run them through their appropriate plugin if they have
        // one assigned. Since they don't need to use the same mechanism we have for HBCI,
        // we can just use a local list. All plugins run in parallel.
        if (account.plugin.length > 0 && ![account.plugin isEqualToString: @"hbci"]) {
            NSMutableArray *accountsPerPlugin = accountsWithPlugins[account.plugin];
            if (accountsPerPlugin == nil) {
                accountsPerPlugin = [NSMutableArray new];
                accountsWithPlugins[account.plugin] = accountsPerPlugin;
            }
            [accountsPerPlugin addObject: account];
        } else {
            NSMutableArray *accountsPerUser = userList[account.userId];
            if (accountsPerUser == nil) {
                accountsPerUser = [NSMutableArray new];
                userList[account.userId] = accountsPerUser;
            }
            [accountsPerUser addObject: account];
        }
    }

    [self startProgress];
    pluginsRunning = accountsWithPlugins.count;
    for (NSArray *accounts in accountsWithPlugins.allValues) {
        [PluginRegistry getStatements: accounts completion: ^(NSArray *results) {
            @synchronized(userList) {
                [self handleQueryResults: results];
                NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsNotification object: results];
                [NSNotificationCenter.defaultCenter postNotification: notification];

                --pluginsRunning;
                if (pluginsRunning == 0 && userList.count == 0) {
                    NSNotification *notification = [NSNotification notificationWithName: PecuniaStatementsFinalizeNotification
                                                                                 object: nil];
                    [NSNotificationCenter.defaultCenter postNotification: notification];
                    [self stopProgress];
                }
            }
        }];
    }

    // Now start retrieval with first user using HBCI.
    if (userList.count > 0) {
        NSString *userId = userList.allKeys[0];
        [self getUserStatements: userList[userId]];
    }
 }

- (void)getUserStandingOrders: (NSArray*)accounts
{
    if (accounts.count == 0) {
        [self asyncCommandCompletedWithResult: nil error: nil];
        return;
    }

    BankAccount *account = accounts.firstObject;
    BankUser *user = [self getBankUserForId: account.userId bankCode: account.bankCode];
    if (user == nil) {
        [self asyncCommandCompletedWithResult:nil error: nil];
        return;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getAllStandingOrders\"><accinfolist type=\"list\">"];
    
    // Register user.
    user = [self getBankUserForId: account.userId bankCode: account.bankCode];
    if (user == nil) {
        [self asyncCommandCompletedWithResult: nil error: nil];
        return;
    }
    
    for (account in accounts) {
        [cmd appendString: @"<accinfo>"];
        [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
        [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
        [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
        [self appendTag: @"userId" withValue: user.userId to: cmd];
        [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
        [self appendTag: @"iban" withValue: account.iban to: cmd];
        [self appendTag: @"bic" withValue: account.bic to: cmd];
        [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
        [self appendTag: @"isSEPA" withValue: @"yes" to: cmd];
        [cmd appendString: @"</accinfo>"];
    }
    [cmd appendString: @"</accinfolist></command>"];
    [bridge asyncCommand: cmd sender: self];
}

- (void)getStandingOrders: (NSArray *)accounts
{
    if (userList.count > 0 || accounts.count == 0) {
        return; // We are currently retrieving statements or there's nothing to get for.
    }

    retrieveStandingOrders = YES;

    // Organize accounts by user in order to get all statements for all accounts of a given user.
    userList = [NSMutableDictionary new];
    for (BankAccount *account in accounts) {
        NSMutableArray *accountsPerUser = userList[account.userId];
        if (accountsPerUser == nil) {
            accountsPerUser = [NSMutableArray new];
            userList[account.userId] = accountsPerUser;
        }
        [accountsPerUser addObject: account];
    }

    // Now start asynchronous queries with first user. Send requests to the appropriate
    // plugin or down the normal HBCI road.
    [self startProgress];

    NSString *userId = userList.allKeys[0];
    [self getUserStandingOrders: userList[userId]];
}

- (void)prepareCommand: (NSMutableString *)cmd forStandingOrder: (StandingOrder *)stord user: (BankUser *)user
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"y-MM-dd";

    [self appendTag: @"bankCode" withValue: stord.account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: stord.account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: stord.account.accountSuffix to: cmd];
    [self appendTag: @"customerId" withValue: stord.account.customerId to: cmd];
    [self appendTag: @"iban" withValue: stord.account.iban to: cmd];
    [self appendTag: @"bic" withValue: stord.account.bic to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"remoteAccount" withValue: stord.remoteAccount to: cmd];
    [self appendTag: @"remoteBankCode" withValue: stord.remoteBankCode to: cmd];
    [self appendTag: @"remoteIBAN" withValue: stord.remoteIBAN to: cmd];
    [self appendTag: @"remoteBIC" withValue: stord.remoteBIC to: cmd];
    [self appendTag: @"remoteName" withValue: stord.remoteName to: cmd];
    [self appendTag: @"purpose1" withValue: stord.purpose1 to: cmd];
    [self appendTag: @"purpose2" withValue: stord.purpose2 to: cmd];
    [self appendTag: @"purpose3" withValue: stord.purpose3 to: cmd];
    [self appendTag: @"purpose4" withValue: stord.purpose4 to: cmd];
    [self appendTag: @"currency" withValue: stord.currency to: cmd];
    [self appendTag: @"remoteCountry" withValue: @"DE" to: cmd];
    [self appendTag: @"value" withValue: [[stord.value outboundNumber] stringValue] to: cmd];

    [self appendTag: @"firstExecDate" withValue: [dateFormatter stringFromDate: stord.firstExecDate] to: cmd];
    if (stord.lastExecDate) {
        ShortDate *sDate = [ShortDate dateWithDate: stord.lastExecDate];
        if (sDate.year < 2100) {
            [self appendTag: @"lastExecDate" withValue: [dateFormatter stringFromDate: stord.lastExecDate] to: cmd];
        }
    }

    // time unit
    switch ([stord.period intValue]) {
        case stord_weekly:[self appendTag: @"timeUnit" withValue: @"W" to: cmd]; break;

        default:[self appendTag: @"timeUnit" withValue: @"M" to: cmd]; break;
    }

    [self appendTag: @"turnus" withValue: [stord.cycle stringValue] to: cmd];
    [self appendTag: @"executionDay" withValue: [stord.executionDay stringValue] to: cmd];
}

- (PecuniaError *)sendStandingOrders: (NSArray *)orders
{
    PecuniaError           *err = nil;
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

    NSMutableDictionary *accountTransferRegister = [NSMutableDictionary dictionaryWithCapacity: 10];

    // Group transfers by BankAccount
    for (StandingOrder *stord in orders) {
        BankAccount    *account = stord.account;
        NSMutableArray *accountTransfers = accountTransferRegister[account];
        if (accountTransfers == nil) {
            accountTransfers = [NSMutableArray arrayWithCapacity: 10];
            accountTransferRegister[account] = accountTransfers;
        }
        [accountTransfers addObject: stord];
    }
    [self startProgress];

    for (BankAccount *account in [accountTransferRegister allKeys]) {
        SigningOption *option = [self signingOptionForAccount: account];
        if (option == nil) {
            continue;
        }
        Security.currentSigningOption = option;

        // Registriere gewählten User
        BankUser *user = [self getBankUserForId: option.userId bankCode: account.bankCode];
        if (user == nil) {
            continue;
        }

        if ([user.tanMediaFetched boolValue] == NO) {
            [self updateTanMediaForUser: user];
        }

        for (StandingOrder *stord in accountTransferRegister[account]) {
            // todo: don't send unchanged orders
            if ([stord.isChanged boolValue] == NO && [stord.toDelete boolValue] == NO) {
                continue;
            }

            // don't send sent orders without ID
            if ([stord.isSent boolValue] == YES && stord.orderKey == nil) {
                continue;
            }

            if (stord.orderKey == nil) {
                // create standing order
                NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"addStandingOrder\">"];
                [self prepareCommand: cmd forStandingOrder: stord user: user];
                [cmd appendString: @"</command>"];

                NSDictionary *result = [bridge syncCommand: cmd error: &err];
                if (err) {
                    [err logMessage];
                    [self stopProgress];
                    return err;
                }
                stord.isSent = [result valueForKey: @"isOk"];
                stord.orderKey = [result valueForKey: @"orderId"];
                if (stord.isSent) {
                    stord.isChanged = @NO;
                }
            } else if ([stord.toDelete boolValue] == YES) {
                // delete standing order
                NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"deleteStandingOrder\">"];
                [self prepareCommand: cmd forStandingOrder: stord user: user];
                if (stord.orderKey) {
                    [self appendTag: @"orderId" withValue: stord.orderKey to: cmd];
                }
                [cmd appendString: @"</command>"];

                NSNumber *result = [bridge syncCommand: cmd error: &err];
                if (err) {
                    [err logMessage];
                    [self stopProgress];
                    return err;
                }
                stord.isSent = result;
                if ([result boolValue] == YES) {
                    [context deleteObject: stord];
                }
            } else {
                // change standing order
                NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"changeStandingOrder\">"];
                [self prepareCommand: cmd forStandingOrder: stord user: user];
                [self appendTag: @"orderId" withValue: stord.orderKey to: cmd];
                [cmd appendString: @"</command>"];

                NSNumber *result = [bridge syncCommand: cmd error: &err];
                if (err) {
                    [err logMessage];
                    [self stopProgress];
                    return err;
                }
                stord.isSent = result;
                if ([result boolValue] == YES) {
                    stord.isChanged = @NO;
                }
            }
        }
    }
    [self stopProgress];
    return nil;
}

- (BankAccount *)getBankNodeWithAccount: (Account *)acc inAccounts: (NSMutableArray *)bankAccounts
{
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    BankAccount            *bankNode = [BankAccount bankRootForCode: acc.bankCode];

    if (bankNode == nil) {
        BankingCategory *root = [BankingCategory bankRoot];
        if (root == nil) {
            return nil;
        }
        // create bank node
        bankNode = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: context];
        bankNode.name = acc.bankName;
        bankNode.bankCode = acc.bankCode;
        bankNode.currency = acc.currency;
        bankNode.bic = acc.bic;
        bankNode.isBankAcc = @YES;
        bankNode.parent = root;
        if (bankAccounts) {
            [bankAccounts addObject: bankNode];
        }
    }
    return bankNode;
}

- (void)updateBankAccounts: (NSArray *)hbciAccounts forUser: (BankUser *)user
{
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSManagedObjectModel   *model = [[MOAssistant sharedAssistant] model];
    NSError                *error = nil;
    BOOL                   found;

    if (hbciAccounts == nil) {
        hbciAccounts = [self getAccountsForUser: user];
    }

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"allBankAccounts"];
    NSArray        *tmpAccounts = [context executeFetchRequest: request error: &error];
    if (error != nil || tmpAccounts == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    NSMutableArray *bankAccounts = [NSMutableArray arrayWithArray: tmpAccounts];

    for (Account *acc in hbciAccounts) {
        BankAccount *account;

        //lookup
        found = NO;
        for (account in bankAccounts) {
            if ([account.bankCode isEqual: acc.bankCode] && [account.accountNumber isEqual: acc.accountNumber] &&
                ((account.accountSuffix == nil && acc.subNumber == nil) || [account.accountSuffix isEqual: acc.subNumber])) {
                found = YES;
                break;
            }
        }
        if (found) {
            // Update the user id if there is none assigned yet.
            if (account.userId == nil) {
                account.userId = acc.userId;
                account.customerId = acc.customerId;
            } else {
                // check if the account's user id still exists
                BankUser *accUser = [BankUser findUserWithId:account.userId bankCode:account.bankCode];
                if (accUser == nil) {
                    account.userId = acc.userId;
                    account.customerId = acc.customerId;
                }
            }
            // ensure the user is linked to the account
            NSMutableSet *users = [account mutableSetValueForKey: @"users"];
            [users addObject: user];

            if (acc.bic != nil) {
                account.bic = acc.bic;
            }
            if (acc.iban != nil) {
                account.iban = acc.iban;
            }
            if ([account.isManual isEqual:@YES]) {
                // check if account supports statement transfers
                NSArray *jobNames = acc.supportedJobs;
                if (jobNames != nil && [jobNames containsObject: @"KUmsAll"]) {
                    LogInfo(@"Account %@ was previously created manually, changed to automatic update!", account.localName);
                    account.isManual = @NO;
                }
            }
        } else {
            // Account was not found: create it.
            BankAccount *bankRoot = [self getBankNodeWithAccount: acc inAccounts: bankAccounts];
            if (bankRoot == nil) {
                return;
            }
            BankAccount *bankAccount = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount"
                                                                     inManagedObjectContext: context];

            bankAccount.accountNumber = acc.accountNumber;
            bankAccount.name = acc.name;
            bankAccount.bankCode = acc.bankCode;
            bankAccount.bankName = acc.bankName;
            bankAccount.currency = acc.currency;
            bankAccount.country = acc.country;
            bankAccount.owner = acc.ownerName;
            bankAccount.userId = acc.userId;
            bankAccount.customerId = acc.customerId;
            bankAccount.isBankAcc = @YES;
            bankAccount.accountSuffix = acc.subNumber;
            bankAccount.bic = acc.bic;
            bankAccount.iban = acc.iban;
            bankAccount.type = acc.type;
            bankAccount.plugin = [PluginRegistry pluginForAccount: acc.accountNumber bankCode: acc.bankCode];
            if (bankAccount.plugin.length == 0) {
                bankAccount.plugin = @"hbci";
            }

            // links
            bankAccount.parent = bankRoot;
            NSMutableSet *users = [bankAccount mutableSetValueForKey: @"users"];
            [users addObject: user];
        }
    }
    // save updates
    if ([context save: &error] == NO) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (PecuniaError*)clearLimitsForUser:(BankUser*)user
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"TransactionLimits" inManagedObjectContext: context];
    
    NSPredicate    *predicate = [NSPredicate predicateWithFormat: @"user = %@", user];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];
    
    // remove existing
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error) {
        return [PecuniaError errorWithMessage: [error localizedDescription] title: NSLocalizedString(@"AP204", nil)];
    }
    
    for (TransactionLimits *limit in result) {
        [context deleteObject: limit];
    }
    return nil;
}

- (PecuniaError *)updateSupportedTransactionsForAccounts: (NSArray *)accounts user: (BankUser *)user
{
    PecuniaError *error = nil;

    for (Account *acc in accounts) {
        BankAccount *account = [BankAccount findAccountWithNumber: acc.accountNumber subNumber: acc.subNumber bankCode: acc.bankCode];
        if (account == nil) {
            LogError(@"Bankaccount not found: %@ %@ %@", acc.accountNumber, acc.subNumber, acc.bankCode);
            continue;
        }
        error = [SupportedTransactionInfo updateSupportedTransactionInfoForUser:user account:account withJobs:acc.supportedJobs];
        if (error != nil) {
            return error;
        }
    }
    return nil;
}

- (PecuniaError*)updateSupportedTransactionsForUser:(BankUser *)user
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }
    
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getUserData\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];
    
    // communicate with bank to update bank parameters
    User *usr = [bridge syncCommand: cmd error: &error];
    if (error) {
        return error;
    }
    // update supported transactions
    error = [self updateSupportedTransactionsForAccounts: usr.accounts user: user];
    if (error) {
        return error;
    }
    return nil;
}

- (PecuniaError *)updateBankDataForUser: (BankUser *)user
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"updateUserData\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];

    // communicate with bank to update bank parameters
    User *usr = [bridge syncCommand: cmd error: &error];
    if (error) {
        return error;
    }

    // Update user's accounts
    [self updateBankAccounts: usr.accounts forUser: user];

    // update supported transactions
    error = [self updateSupportedTransactionsForAccounts: usr.accounts user: user];
    if (error) {
        return error;
    }
    
    // clear Limits cache
    error = [self clearLimitsForUser:user];
    if (error) {
        return error;
    }

    // also update TAN media and TAN methods
    if ([user.secMethod intValue] == SecMethod_PinTan) {
        error = [self updateTanMethodsForUser: user];
        if (error != nil) {
            return error;
        }
        error = [self updateTanMediaForUser: user];
        if (error != nil) {
            return error;
        }
    }
    return nil;
}

- (PecuniaError *)synchronizeUser: (BankUser *)user
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }
    
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"synchronize\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];
    
    // communicate with bank to update bank parameters
    User *usr = [bridge syncCommand: cmd error: &error];
    if (error) {
        return error;
    }
    
    // Update user's accounts
    [self updateBankAccounts: usr.accounts forUser: user];
    
    // update supported transactions
    error = [self updateSupportedTransactionsForAccounts: usr.accounts user: user];
    if (error) {
        return error;
    }
    
    // clear Limits cache
    error = [self clearLimitsForUser:user];
    if (error) {
        return error;
    }
    
    // also update TAN media and TAN methods
    if ([user.secMethod intValue] == SecMethod_PinTan) {
        error = [self updateTanMethodsForUser: user];
        if (error != nil) {
            return error;
        }
        error = [self updateTanMediaForUser: user];
        if (error != nil) {
            return error;
        }
    }
    return nil;
}

- (PecuniaError *)changePinTanMethodForUser: (BankUser *)user
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"resetPinTanMethod\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];

    [bridge syncCommand: cmd error: &error];
    if (error) {
        return error;
    }
    return nil;
}

- (PecuniaError *)changePinForUser: (BankUser *)user toPin: (NSString *)newPin
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"changePin\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"newPin" withValue: newPin to: cmd];
    [cmd appendString: @"</command>"];
    
    NSNumber *isOk = [bridge syncCommand: cmd error: &error];
    if ([isOk boolValue]) {
        error = [PecuniaError errorWithMessage: NSLocalizedString(@"AP82", nil)
                                         title: NSLocalizedString(@"AP53", nil)];
    }
    
    // remove PIN from Keychain
    NSString *s = [NSString stringWithFormat: @"PIN_%@_%@", user.bankCode, user.userId];
    [Security deletePasswordForService: @"Pecunia PIN" account: s];

    if (error) {
        return error;
    }
    return nil;
}

- (PecuniaError *)sendCustomerMessage: (CustomerMessage *)msg
{
    PecuniaError *error = nil;

    [self startProgress];

    BankUser *user = [BankUser findUserWithId: msg.account.userId bankCode: msg.account.bankCode];
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }

    if ([user.tanMediaFetched boolValue] == NO) {
        [self updateTanMediaForUser: user];
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"customerMessage\">"];
    [self appendTag: @"bankCode" withValue: msg.account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: msg.account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: msg.account.accountSuffix to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"head" withValue: msg.header to: cmd];
    [self appendTag: @"body" withValue: msg.message to: cmd];
    [self appendTag: @"recpt" withValue: msg.receipient to: cmd];
    [cmd appendString: @"</command>"];

    NSNumber *result = [bridge syncCommand: cmd error: &error];
    [self stopProgress];

    if (error) {
        return error;
    }

    if ([result boolValue] == YES) {
        msg.isSent = @YES;
    } else {
        error = [PecuniaError errorWithCode: 0 message: NSLocalizedString(@"AP158", nil)];
    }
    return error;
}

- (PecuniaError *)getBalanceForAccount: (BankAccount *)account
{
    PecuniaError *error = nil;

    [self startProgress];

    BankUser *user = [account defaultBankUser];
    if (user == nil) {
        return nil;
    }

    // BankUser registrieren
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getBalance\">"];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [cmd appendString: @"</command>"];

    NSDictionary *result = [bridge syncCommand: cmd error: &error];
    [self stopProgress];

    if (error) {
        return error;
    }
    if (result == nil) {
        LogError(@"Unexpected result for getBalance: nil");
        return nil;
    }
    NSNumber *isOk = [result valueForKey: @"isOk"];
    if (isOk != nil) {
        NSDecimalNumber *value = [result valueForKey: @"balance"];
        if (value != nil) {
            [account updateBalanceWithValue: value];
        } else {
            LogError(@"getBalance: no balance delivered");
            return nil;
        }
    } else {
        error = [PecuniaError errorWithCode: 0 message: NSLocalizedString(@"AP402", nil)];
    }
    return error;
}

- (PecuniaError *)updateTanMethodsForUser: (BankUser *)user
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getTANMethods\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];

    NSArray *methods = [bridge syncCommand: cmd error: &error];
    if (error) {
        return error;
    }
    [user updateTanMethods: methods];
    return nil;
}

- (NSArray *)getSupportedBusinessTransactions: (BankAccount *)account
{
    PecuniaError *error = nil;

    BankUser *user = [account defaultBankUser];
    if (user == nil) {
        return nil;
    }

    // BankUser registrieren
    if ([self registerBankUser: user error: &error] == NO) {
        if (error) {
            [error alertPanel];
        }
        return nil;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getSupportedBusinessTransactions\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"subNumber" withValue: account.accountSuffix to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];

    NSArray *result = [bridge syncCommand: cmd error: &error];
    if (error) {
        [error alertPanel];
        return nil;
    }

    return result;
}

- (PecuniaError *)updateTanMediaForUser: (BankUser *)user
{
    PecuniaError *error = nil;
    if ([self registerBankUser: user error: &error] == NO) {
        return error;
    }

    StatusBarController *sbController = [StatusBarController controller];
    NSMutableString     *cmd = [NSMutableString stringWithFormat: @"<command name=\"getTANMediaList\">"];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [cmd appendString: @"</command>"];

    [sbController setMessage: NSLocalizedString(@"AP213", nil) removeAfter: 0];
    [sbController startSpinning];
    TanMediaList *mediaList = [bridge syncCommand: cmd error: &error];
    [sbController stopSpinning];
    [sbController clearMessage];
    if (error) {
        return error;
    }
    [user updateTanMedia: mediaList.mediaList];
    user.tanMediaFetched = @YES;
    return nil;
}

- (BankUser *)getBankUserForId: (NSString *)userId bankCode: (NSString *)bankCode
{
    BankUser *user = [BankUser findUserWithId: userId bankCode: bankCode];
    if (user == nil) {
        return nil;
    }

    if (user.secMethod.intValue == SecMethod_DDV) {
        if (![[ChipcardManager manager] requestCardForUser:user]) {
            return nil;
        }
    }

    PecuniaError *err = nil;
    if (![self registerBankUser: user error: &err]) {
        if (err) {
            [err alertPanel];
        }
        return nil;
    }
    return user;
}

- (BOOL)registerBankUser: (BankUser *)user error: (PecuniaError **)error
{
    if (user.isRegistered) {
        return YES;
    }

    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"registerUser\">"];

    SecurityMethod secMethod = [user.secMethod intValue];
    if (secMethod == SecMethod_DDV) {
        [self appendTag: @"passportType" withValue: @"DDV" to: cmd];
        user.tanMediaFetched = @YES;
        [self appendTag: @"ddvPortIdx" withValue: [user.ddvPortIdx stringValue] to: cmd];
        [self appendTag: @"ddvReaderIdx" withValue: [user.ddvReaderIdx stringValue] to: cmd];
        [self appendTag: @"host" withValue: user.bankURL to: cmd];
    } else {
        [self appendTag: @"passportType" withValue: @"PinTan" to: cmd];
        [self appendTag: @"host" withValue: [user.bankURL stringByReplacingOccurrencesOfString: @"https://" withString: @""] to: cmd];
        [self appendTag: @"port" withValue: @"443" to: cmd];
        if ([user.noBase64 boolValue] == NO) {
            [self appendTag: @"filter" withValue: @"Base64" to: cmd];
        }
    }
    [self appendTag: @"version" withValue: user.hbciVersion to: cmd];
    [self appendTag: @"userId" withValue: user.userId to: cmd];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd];
    [self appendTag: @"userBankCode" withValue: user.bankCode to: cmd];
    [cmd appendString: @"</command>"];

    NSNumber *isOk = [bridge syncCommand: cmd error: error];

    if (*error == nil && [isOk boolValue] == YES) {
        user.isRegistered = YES;
        return YES;
    } else {
        if (*error == nil) {
            *error = [PecuniaError errorWithMessage: [NSString stringWithFormat: NSLocalizedString(@"AP356", nil), user.userId] title: NSLocalizedString(@"AP355", nil)];
        }
        return NO;
    }
}

- (NSArray *)getOldBankUsers
{
    PecuniaError    *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getOldBankUsers\"></command>"];
    NSArray         *users = [bridge syncCommand: cmd error: &error];
    if (error) {
        [error alertPanel];
        return nil;
    }
    return users;
}

- (SigningOption *)signingOptionForAccount: (BankAccount *)account
{
    NSMutableArray *options = [NSMutableArray arrayWithCapacity: 10];
    NSSet          *users = account.users;
    if (users == nil || [users count] == 0) {
        LogError(@"signingOptionForAccount: no users assigned to account");
        return nil;
    }
    for (BankUser *user in users) {
        SigningOption *option =  [user preferredSigningOption];
        if (option) {
            [options addObject: option];
        } else {
            [options addObjectsFromArray: [user getSigningOptions]];
        }
    }
    if ([options count] == 0) {
        LogDebug(@"signingOptionForAccount: no signing options defined by bank - use default");
        return [SigningOption defaultOptionForUser: [users allObjects][0]];
    }
    if ([options count] == 1) {
        return [options lastObject];
    }

    SigningOptionsController *controller = [[SigningOptionsController alloc] initWithSigningOptions: options forAccount: account];
    int                      res = [NSApp runModalForWindow: [controller window]];
    if (res > 0) {
        return nil;
    }
    return [controller selectedOption];
}

- (void)bankMessageReceived: (NSNotification *)notification
{
    NSDictionary *info = notification.object;
    NSString *bankCode = info[@"bankCode"];
    NSString *title = nil;
    NSError  *error = nil;
    
    if (bankCode != nil) {
        NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
        NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankUser" inManagedObjectContext: context];
        NSFetchRequest         *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"bankCode = %@", bankCode];
        [request setPredicate: predicate];
        NSArray *bankUsers = [context executeFetchRequest: request error: &error];
        if (error) {
            return;
        }
        if ([bankUsers count] == 0) {
            return;
        }
        
        BankUser *user = bankUsers[0];
        title = NSLocalizedString(@"AP502", "");
        if (user.bankName != nil) {
            title = [title stringByAppendingString:user.bankName];
        }
    }
    NSString *message = info[@"message"];
    if (message != nil) {
        [SystemNotification showMessage: message
                              withTitle: title];

    }
}

@end
