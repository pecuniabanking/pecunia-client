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
        [[MessageLog log] addMessage: @"Add supported transaction UEB" withLevel: LogLevel_Debug];
    }
    
    // todo as soon as we support management of dated transfers
    if ([supportedJobNames containsObject: @"TermUeb"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferDated);
        [[MessageLog log] addMessage: @"Add supported transaction TERMUEB" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"UebForeign"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferEU);
        [[MessageLog log] addMessage: @"Add supported transaction UEBFOREIGN" withLevel: LogLevel_Debug];
        
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
        
        [[MessageLog log] addMessage: @"Add supported transaction UEBSEPA" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"TermUebSEPA"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferSEPAScheduled);
        
        [[MessageLog log] addMessage: @"Add supported transaction TERMUEBSEPA" withLevel: LogLevel_Debug];
    }
        
    if ([supportedJobNames containsObject: @"Umb"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferInternal);
        [[MessageLog log] addMessage: @"Add supported transaction UMB" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"Last"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_TransferDebit);
        [[MessageLog log] addMessage: @"Add supported transaction LAST" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"DauerSEPANew"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_StandingOrderSEPA);
        [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPANEW" withLevel: LogLevel_Debug];
        
        // Parameters
        if ([supportedJobNames containsObject: @"DauerSEPAEdit"] == YES) {
            tinfo.allowsChange = @YES;
            [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPAEDIT" withLevel: LogLevel_Debug];
        } else {
            tinfo.allowsChange = @NO;
        }
        if ([supportedJobNames containsObject: @"DauerSEPADel"] == YES) {
            tinfo.allowesDelete = @YES;
            [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPADEL" withLevel: LogLevel_Debug];
            
        } else {
            tinfo.allowesDelete = @NO;
        }
        if ([supportedJobNames containsObject: @"DauerSEPAList"] == YES) {
            tinfo.allowsList = @YES;
            [[MessageLog log] addMessage: @"Add supported transaction DAUERSEPALIST" withLevel: LogLevel_Debug];
        } else {
            tinfo.allowsList = @NO;
        }
    }
    
    
    if ([supportedJobNames containsObject: @"KUmsAll"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_BankStatements);
        [[MessageLog log] addMessage: @"Add supported transaction KUMSALL" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"KKUmsAll"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_CCStatements);
        [[MessageLog log] addMessage: @"Add supported transaction KKUMSALL" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"KKSettleList"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_CCSettlementList);
        [[MessageLog log] addMessage: @"Add supported transaction KKSETTLELIST" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"KKSettleReq"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_CCSettlement);
        [[MessageLog log] addMessage: @"Add supported transaction KKSETTLEREQ" withLevel: LogLevel_Debug];
    }
    
    if ([supportedJobNames containsObject: @"ChangePin"] == YES) {
        SupportedTransactionInfo *tinfo = [NSEntityDescription insertNewObjectForEntityForName: @"SupportedTransactionInfo" inManagedObjectContext: context];
        tinfo.account = account;
        tinfo.user = user;
        tinfo.type = @(TransactionType_ChangePin);
        [[MessageLog log] addMessage: @"Add supported transaction ChangePin" withLevel: LogLevel_Debug];
    }
    return nil;
}

@end
