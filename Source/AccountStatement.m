/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
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

#import "AccountStatement.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "NSString+PecuniaAdditions.h"
#import "MOAssistant.h"
#import "StatCatAssignment.h"
#import "BankStatementPrintView.h"

@implementation AccountStatementParameters

@synthesize canIndex;
@synthesize formats;
@synthesize needsReceipt;

- (BOOL)supportsFormat: (AccountStatementFormat)format {
    NSString *f = [NSString stringWithFormat: @"%lu", format];
    return [formats hasSubstring: f];
}

@end

@implementation AccountStatement

@dynamic document;
@dynamic format;
@dynamic startDate;
@dynamic endDate;
@dynamic info;
@dynamic conditions;
@dynamic advertisement;
@dynamic iban;
@dynamic bic;
@dynamic name;
@dynamic confirmationCode;
@dynamic account;
@synthesize statements;
@synthesize number;

/**
 * Converts all account statements for the given account to a PDF document for the UI and printing.
 */
- (void)convertStatementsToPDFForAccount: (BankAccount *)acct {
    if (self.statements == nil) {
        return;
    }

    if (self.format.intValue != AccountStatement_MT940) {
        return;
    }

    // Insert temporary account + category assignments for the print view to work with.
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.memContext;
    NSMutableArray         *stats = [NSMutableArray array];

    BankAccount *account = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount"
                                                         inManagedObjectContext: context];
    account.accountNumber = acct.accountNumber;
    account.bankCode = acct.bankCode;
    account.accountSuffix = acct.accountSuffix;
    account.name = acct.name;
    account.bankName = acct.bankName;
    account.currency = acct.currency;

    for (BankStatement *statement in self.statements) {
        [statement extractSEPADataUsingContext: context];
        statement.account = account;
        StatCatAssignment *stat = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment"
                                                                inManagedObjectContext: context];
        stat.statement = statement;
        stat.value = statement.value;
        [stats addObject: stat];
    }

    NSPrintInfo *printInfo = NSPrintInfo.sharedPrintInfo;

    // For more info about the margins read StatementsOverviewController print.
    printInfo.topMargin = 20;
    printInfo.bottomMargin = 20;
    printInfo.leftMargin = 18;
    printInfo.rightMargin = 18;

    NSMutableData *pdfData = [NSMutableData new];
    NSView        *view = [[BankStatementPrintView alloc] initWithStatements: stats
                                                                   printInfo: printInfo
                                                                       title: NSLocalizedString(@"AP140", nil)
                                                                    category: account
                                                              additionalText: self.info];

    // Since the print operation ignores any margin setting in the print info we need a little trick
    // to make it render our view with margins.
    NSRect rect = view.bounds;
    rect.size.width += printInfo.leftMargin + printInfo.rightMargin;
    rect.size.height += printInfo.topMargin + printInfo.bottomMargin;
    rect.origin.x = -printInfo.leftMargin;
    rect.origin.y = -printInfo.topMargin;
    NSPrintOperation *printOp = [NSPrintOperation PDFOperationWithView: view
                                                            insideRect: rect
                                                                toData: pdfData
                                                             printInfo: printInfo];
    [printOp runOperation];

    self.document = pdfData;
}

@end
