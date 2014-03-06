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

#define INSERT_INFO(tt) tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context]; \
                        tinfo.user = user; \
                        tinfo.account = account; \
                        tinfo.type = @(tt); \
                        [[MessageLog log] addMessage: [NSString stringWithFormat:@"Add supported transaction %@", jobName] withLevel: LogLevel_Debug];



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
    NSError                     *error = nil;
    NSManagedObjectContext      *context = [[MOAssistant assistant] context];
    SupportedTransactionInfo    *tinfo = nil;
    NSEntityDescription         *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    
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
    
    for (NSString *jobName in supportedJobNames) {
        if ([jobName isEqualToString:@"Ueb"]) {
            INSERT_INFO(TransactionType_TransferStandard)
            // Parameters
            if ([supportedJobNames containsObject: @"TermUeb"] == YES) {
                tinfo.allowsDated = @YES;
            }
            if ([supportedJobNames containsObject: @"MultiUeb"] == YES) {
                tinfo.allowsCollective = @YES;
            }
        }
        
        if ([jobName isEqualToString:@"TermUeb"]) {
            INSERT_INFO(TransactionType_TransferDated)
        }
        if ([jobName isEqualToString:@"UebForeign"]) {
            INSERT_INFO(TransactionType_TransferEU)
        }
        if ([jobName isEqualToString:@"UebSEPA"]) {
            INSERT_INFO(TransactionType_TransferSEPA)
            
            // Parameters
            if ([supportedJobNames containsObject: @"TermUebSEPA"] == YES) {
                tinfo.allowsDated = @YES;
            }
            if ([supportedJobNames containsObject: @"MulitUebSEPA"] == YES) {
                tinfo.allowsCollective = @YES;
            }
        }
        if ([jobName isEqualToString:@"TermUebSEPA"]) {
            INSERT_INFO(TransactionType_TransferSEPAScheduled)
        }
        if ([jobName isEqualToString:@"MultiUebSEPA"]) {
            INSERT_INFO(TransactionType_TransferCollectiveCreditSEPA)
        }
        if ([jobName isEqualToString:@"Umb"]) {
            INSERT_INFO(TransactionType_TransferInternal)
        }
        if ([jobName isEqualToString:@"DauerSEPANew"]) {
            INSERT_INFO(TransactionType_StandingOrderSEPA)
            // Parameters
            if ([supportedJobNames containsObject: @"DauerSEPAEdit"] == YES) {
                tinfo.allowsChange = @YES;
                [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPAEDIT" withLevel: LogLevel_Debug];
            }
            if ([supportedJobNames containsObject: @"DauerSEPADel"] == YES) {
                tinfo.allowesDelete = @YES;
                [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPADEL" withLevel: LogLevel_Debug];
            }
            if ([supportedJobNames containsObject: @"DauerSEPAList"] == YES) {
                tinfo.allowsList = @YES;
                [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPALIST" withLevel: LogLevel_Debug];
            }
        }
        if ([jobName isEqualToString:@"KUmsAll"]) {
            INSERT_INFO(TransactionType_BankStatements)
        }
        if ([jobName isEqualToString:@"KKUmsAll"]) {
            INSERT_INFO(TransactionType_CCStatements)
        }
        if ([jobName isEqualToString:@"KKSettleList"]) {
            INSERT_INFO(TransactionType_CCSettlementList)
        }
        if ([jobName isEqualToString:@"KKSettleReq"]) {
            INSERT_INFO(TransactionType_CCSettlement)
        }
        if ([jobName isEqualToString:@"ChangePin"]) {
            INSERT_INFO(TransactionType_ChangePin)
        }
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
        case TransactionType_TransferCollectiveCreditSEPA: s = NSLocalizedString(@"AP1214", @""); break;
            
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
