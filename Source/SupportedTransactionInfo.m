/**
 * Copyright (c) 2007, 2014, Pecunia Project. All rights reserved.
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

+ (SupportedTransactionInfo *)insertInContext: (NSManagedObjectContext *)context
                                         user: (BankUser *)user
                                      account: (BankAccount *)account
                                         type: (TransactionType)type
                                      jobName: (NSString *)job
{
    SupportedTransactionInfo *info = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo"
                                                                   inManagedObjectContext: context];
    info.user = user;
    info.account = account;
    info.type = @(type);
    LogDebug(@"Add supported transaction %@", job);

    return info;
}

+ (SupportedTransactionInfo*)infoForType:(TransactionType)type account:(BankAccount*)account
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
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
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
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
    NSManagedObjectContext      *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription         *entityDescription = [NSEntityDescription entityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
    
    NSPredicate    *predicate = [NSPredicate predicateWithFormat: @"user = %@ AND account = %@", user, account];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    [request setPredicate: predicate];
    
    // Remove existing info.
    NSArray *result = [context executeFetchRequest: request error: &error];
    if (error != nil) {
        return [PecuniaError errorWithMessage: [error localizedDescription] title: NSLocalizedString(@"AP204", nil)];
    }
    
    for (SupportedTransactionInfo *tinfo in result) {
        [context deleteObject: tinfo];
    }
    
    for (NSString *jobName in supportedJobNames) {
        if ([jobName isEqualToString:@"Ueb"]) {
            SupportedTransactionInfo *info = [self insertInContext: context
                                                              user: user
                                                           account: account
                                                              type: TransactionType_TransferStandard
                                                           jobName: jobName];

            // Parameters.
            if ([supportedJobNames containsObject: @"TermUeb"]) {
                info.allowsDated = @YES;
            }
            if ([supportedJobNames containsObject: @"MultiUeb"]) {
                info.allowsCollective = @YES;
            }
        }
        
        if ([jobName isEqualToString:@"TermUeb"]) {
            [self insertInContext: context user: user account: account type: TransactionType_TransferDated jobName: jobName];
        }

        if ([jobName isEqualToString:@"UebForeign"]) {
            [self insertInContext: context user: user account: account type: TransactionType_TransferEU jobName: jobName];
        }

        if ([jobName isEqualToString:@"SepaTransfer"] || [jobName isEqualToString:@"SepaDatedTransfer"]) {
            SupportedTransactionInfo *info = [self insertInContext: context
                                                              user: user
                                                           account: account
                                                              type: TransactionType_TransferSEPA
                                                           jobName: jobName];

            // Parameters
            if ([supportedJobNames containsObject: @"SepaDatedTransfer"]) {
                info.allowsDated = @YES;
            }
            if ([supportedJobNames containsObject: @"SepaCollectiveTransfer"]) {
                info.allowsCollective = @YES;
            }
        }

        if ([jobName isEqualToString:@"SepaDatedTransfer"]) {
            [self insertInContext: context user: user account: account type: TransactionType_TransferSEPAScheduled jobName: jobName];
        }

        if ([jobName isEqualToString:@"SepaCollectiveTransfer"]) {
            [self insertInContext: context user: user account: account type: TransactionType_TransferCollectiveCreditSEPA jobName: jobName];
        }

        if ([jobName isEqualToString:@"Umb"]) {
            [self insertInContext: context user: user account: account type: TransactionType_TransferInternal jobName: jobName];
        }

        if ([jobName isEqualToString:@"SepaInternalTransfer"]) {
            [self insertInContext: context user: user account: account type: TransactionType_TransferInternalSEPA  jobName: jobName];
        }

        if ([jobName isEqualToString:@"SepaStandingOrderNew"]) {
            SupportedTransactionInfo *info = [self insertInContext: context
                                                              user: user
                                                           account: account
                                                              type: TransactionType_StandingOrderSEPA
                                                           jobName: jobName];
            // Parameters.
            if ([supportedJobNames containsObject: @"SepaStandingOrderEdit"]) {
                info.allowsChange = @YES;
                LogDebug(@"Add supported transaction SepaStandingOrderEdit");
            }
            if ([supportedJobNames containsObject: @"SepaStandingOrderDel"]) {
                info.allowesDelete = @YES;
                LogDebug(@"Add supported transaction SepaStandingOrderDel");
            }
            if ([supportedJobNames containsObject: @"SepaStandingOrderList"]) {
                info.allowsList = @YES;
                LogDebug(@"Add supported transaction SepaStandingOrderList");
            }
        }

        if ([jobName isEqualToString: @"Statements"]) {
            [self insertInContext: context user: user account: account type: TransactionType_BankStatements jobName: jobName];
        }

        if ([jobName isEqualToString: @"KKUmsAll"]) {
            [self insertInContext: context user: user account: account type: TransactionType_CCStatements jobName: jobName];
        }

        if ([jobName isEqualToString: @"KKSettleList"]) {
            [self insertInContext: context user: user account: account type: TransactionType_CCSettlementList jobName: jobName];
        }

        if ([jobName isEqualToString: @"KKSettleReq"]) {
            [self insertInContext: context user: user account: account type: TransactionType_CCSettlement jobName: jobName];
        }

        if ([jobName isEqualToString: @"ChangePin"]) {
            [self insertInContext: context user: user account: account type: TransactionType_ChangePin jobName: jobName];
        }
        
        if ([jobName isEqualToString:@"AccountStatements"]) {
            [self insertInContext: context user: user account: account type: TransactionType_AccountStatements jobName: jobName];
        }
    }
    return nil;
}

- (NSString*)description
{
    return [self descriptionWithIndent: @""];
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
        [descr appendString: NSLocalizedString(@"AP1011", @"")];
    }
    if ([self.allowsCollective boolValue]) {
        [descr appendString: NSLocalizedString(@"AP1012", @"")];
    }
    if ([self.allowsDated boolValue]) {
        [descr appendString: NSLocalizedString(@"AP1013", @"")];
    }
    if ([self.allowesDelete boolValue]) {
        [descr appendString: NSLocalizedString(@"AP1014", @"")];
    }
    if ([self.allowsList boolValue]) {
        [descr appendString: NSLocalizedString(@"AP1015", @"")];
    }
    [descr appendString: @"\n"];
    return descr;
}

@end
