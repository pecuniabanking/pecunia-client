/**
 * Copyright (c) 2007, 2013, Pecunia Project. All rights reserved.
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

#import "SupportedTransactionInfo.h"
#import "MOAssistant.h"
#import "MessageLog.h"
#import "PecuniaError.h"

@implementation SupportedTransactionInfo

@dynamic allowsChange;
@dynamic allowsCollective;
@dynamic allowsDated;
@dynamic allowsList;
@dynamic type;
@dynamic allowesDelete;

@dynamic account;
@dynamic user;

+ (SupportedTransactionInfo*)infoForType:(TransactionType)type account:(BankAccount*)account
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSPredicate            *predicate = [NSPredicate predicateWithFormat: @"account = %@ AND type = %d", account, type];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];
    
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error != nil) {
        return nil;
    }
    
    if ([result count] == 0) {
        return nil;
    }
    return result.lastObject;
}

+ (NSArray*)supportedTransactionsForAccount: (BankAccount*)account
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSPredicate            *predicate = [NSPredicate predicateWithFormat: @"account = %@", account];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];
    
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error != nil) {
        return nil;
    }
    return result;
}

+ (PecuniaError*)updateSupportedTransactionInfoForUser: (BankUser*)user account: (BankAccount*)account withJobs:(NSArray*)supportedJobNames
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];

    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    
    NSPredicate    *predicate = [NSPredicate predicateWithFormat: @"user = %@ AND account = %@", user, account];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];
    
    // remove existing
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error) {
        return [PecuniaError errorWithMessage: [error localizedDescription] title: NSLocalizedString(@"AP204", nil)];
    }
    
    for (SupportedTransactionInfo *tinfo in result) {
        [context deleteObject: tinfo];
    }
    
    if ([supportedJobNames containsObject: @"Ueb"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferStandard);
        
        // Parameters
        if ([supportedJobNames containsObject: @"TermUeb"] == YES) {
            tinfo.allowsDated = @YES;
        } else {
            tinfo.allowsDated = @NO;
        }
        if ([supportedJobNames containsObject: @"MultiUeb"] == YES) {
            tinfo.allowsCollective = @YES;
        } else {
            tinfo.allowsCollective = @NO;
        }
        LogDebug(@"Add supported transaction UEB");
    }
    
    // todo as soon as we support management of dated transfers
    if ([supportedJobNames containsObject: @"TermUeb"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferDated);
        LogDebug(@"Add supported transaction TERMUEB");
    }
    
    if ([supportedJobNames containsObject: @"UebForeign"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferEU);
        LogDebug(@"Add supported transaction UEBFOREIGN");
        
    }
    
    if ([supportedJobNames containsObject: @"UebSEPA"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferSEPA);
        
        // Parameters
        if ([supportedJobNames containsObject: @"TermUebSEPA"] == YES) {
            tinfo.allowsDated = @YES;
        } else {
            tinfo.allowsDated = @NO;
        }
        
        if ([supportedJobNames containsObject: @"MulitUebSEPA"] == YES) {
            tinfo.allowsCollective = @YES;
        } else {
            tinfo.allowsCollective = @NO;
        }
        
        LogDebug(@"Add supported transaction UEBSEPA");
    }
    
    if ([supportedJobNames containsObject: @"TermUebSEPA"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferSEPAScheduled);
        
        LogDebug(@"Add supported transaction TERMUEBSEPA");
    }
        
    if ([supportedJobNames containsObject: @"Umb"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferInternal);
        LogDebug(@"Add supported transaction UMB");
    }
    
    if ([supportedJobNames containsObject: @"Last"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferDebit);
        LogDebug(@"Add supported transaction LAST");
    }
    
    if ([supportedJobNames containsObject: @"DauerSEPANew"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_StandingOrderSEPA);
        LogDebug(@"Add supported transaction DAUERSEPANEW");
        
        // Parameters
        if ([supportedJobNames containsObject: @"DauerSEPAEdit"] == YES) {
            tinfo.allowsChange = @YES;
            LogDebug(@"Add supported transaction DAUERSEPAEDIT");
        } else {
            tinfo.allowsChange = @NO;
        }
        if ([supportedJobNames containsObject: @"DauerSEPADel"] == YES) {
            tinfo.allowesDelete = @YES;
            LogDebug(@"Add supported transaction DAUERSEPADEL");
            
        } else {
            tinfo.allowesDelete = @NO;
        }
        if ([supportedJobNames containsObject: @"DauerSEPAList"] == YES) {
            tinfo.allowsList = @YES;
            LogDebug(@"Add supported transaction DAUERSEPALIST");
        } else {
            tinfo.allowsList = @NO;
        }
    }
    
    
    if ([supportedJobNames containsObject: @"KUmsAll"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_BankStatements);
        LogDebug(@"Add supported transaction KUMSALL");
    }
    
    if ([supportedJobNames containsObject: @"KKUmsAll"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_CCStatements);
        LogDebug(@"Add supported transaction KKUMSALL");
    }
    
    if ([supportedJobNames containsObject: @"KKSettleList"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_CCSettlementList);
        LogDebug(@"Add supported transaction KKSETTLELIST");
    }
    
    if ([supportedJobNames containsObject: @"KKSettleReq"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_CCSettlement);
        LogDebug(@"Add supported transaction KKSETTLEREQ");
    }
    
    if ([supportedJobNames containsObject: @"ChangePin"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_ChangePin);
        LogDebug(@"Add supported transaction ChangePin");
    }
    return nil;
}

- (NSString*)description
{
    return [self descriptionWithIndent:@""];
}

- (NSString*)descriptionWithIndent:(NSString*)indent
{
    NSMutableString *descr = [[NSMutableString alloc] init];
    NSString *s = nil;
    switch ([self.type intValue]) {
        case TransactionType_TransferStandard: s = NSLocalizedString(@"AP1200", @""); break;
        case TransactionType_TransferEU: s = NSLocalizedString(@"AP1201", @""); break;
        case TransactionType_TransferDated: s = NSLocalizedString(@"AP1202", @""); break;
        case TransactionType_TransferInternal: s = NSLocalizedString(@"AP1203", @""); break;
        case TransactionType_TransferDebit: s = NSLocalizedString(@"AP1204", @""); break;
        case TransactionType_TransferSEPA: s = NSLocalizedString(@"AP1205", @""); break;
        case TransactionType_StandingOrder: s = NSLocalizedString(@"AP1206", @""); break;
        case TransactionType_BankStatements: s = NSLocalizedString(@"AP1207", @""); break;
        case TransactionType_CCStatements: s = NSLocalizedString(@"AP1208", @""); break;
        case TransactionType_CCSettlementList: s = NSLocalizedString(@"AP1209", @""); break;
        case TransactionType_CCSettlement: s = NSLocalizedString(@"AP1210", @""); break;
        case TransactionType_ChangePin: s = NSLocalizedString(@"AP1211", @""); break;
        case TransactionType_StandingOrderSEPA: s = NSLocalizedString(@"AP1212", @""); break;
        case TransactionType_TransferSEPAScheduled: s = NSLocalizedString(@"AP1213", @""); break;
            
        default: s = NSLocalizedString(@"AP1299", @"");
    }
    
    [descr appendString:indent];
    [descr appendString:s];
    
    if ([self.allowsChange boolValue]) {
        [descr appendString:NSLocalizedString(@"AP1011", @"")];
    }
    if ([self.allowsCollective boolValue]) {
        [descr appendString:NSLocalizedString(@"AP1012", @"")];
    }
    if ([self.allowsDated boolValue]) {
        [descr appendString:NSLocalizedString(@"AP1013", @"")];
    }
    if ([self.allowesDelete boolValue]) {
        [descr appendString:NSLocalizedString(@"AP1014", @"")];
    }
    if ([self.allowsList boolValue]) {
        [descr appendString:NSLocalizedString(@"AP1015", @"")];
    }
    [descr appendString:@"\n"];
    return descr;
}

@end
