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
/*
@implementation SupportedTransactionInfo

@dynamic allowsChange;
@dynamic allowsCollective;
@dynamic allowsDated;
@dynamic allowsList;
@dynamic type;
@dynamic allowesDelete;

@dynamic account;
@dynamic user;


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
*/
