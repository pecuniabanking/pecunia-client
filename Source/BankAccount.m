/**
 * Copyright (c) 2007, 2015, Pecunia Project. All rights reserved.
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

#import "BankAccount.h"
#import "BankStatement.h"
#import "MOAssistant.h"
#import "ShortDate.h"
#import "StandingOrder.h"
#import "PurposeSplitController.h"
#import "BankUser.h"
#import "MessageLog.h"
#import "StatCatAssignment.h"
#import "SupportedTransactionInfo.h"
#import "PecuniaError.h"

#import "HBCIController.h"

@implementation BankAccount

@dynamic latestTransferDate;
@dynamic country;
@dynamic bankName;
@dynamic bankCode;
@dynamic bic;
@dynamic iban;
@dynamic userId;
@dynamic customerId;
@dynamic owner;
@dynamic uid;
@dynamic type;
@dynamic balance;
@dynamic noAutomaticQuery;
@dynamic collTransferMethod;
@dynamic isManual;
@dynamic splitRule;
@dynamic isStandingOrderSupported;
@dynamic accountSuffix;
@dynamic users;
@dynamic plugin;

@synthesize dbStatements;
@synthesize unread;

- (id)copyWithZone: (NSZone *)zone {
    return self;
}

- (NSInteger)calcUnread {
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (isNew = 1)", self];
    [request setPredicate: predicate];
    NSArray *statements = [context executeFetchRequest: request error: &error];
    return unread = [statements count];
}

- (NSDictionary *)statementsByDay: (NSArray *)stats {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity: 10];

    for (BankStatement *stat in stats) {
        ShortDate      *date = [ShortDate dateWithDate: stat.date];
        NSMutableArray *dayStats = result[date];
        if (dayStats == nil) {
            dayStats = [NSMutableArray arrayWithCapacity: 10];
            result[date] = dayStats;
        }
        [dayStats addObject: stat];
    }
    return result;
}

- (void)evaluateQueryResult: (BankQueryResult *)res {
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    // get old statements
    if ([res.statements count] == 0) {
        return;
    }
    
    // first remove old preliminary statements
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (isPreliminary = 1)", self];
    [request setPredicate: predicate];

    NSError *error;
    NSArray *preliminaryStatements = [context executeFetchRequest: request error: &error];
    for (BankStatement *statement in preliminaryStatements) {
        [context deleteObject: statement];
    }
    if (preliminaryStatements.count > 0) {
        [context processPendingChanges];
    }
    
    BankStatement *newStatement = (res.statements)[0]; // oldest statement
    predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@)", self, [[ShortDate dateWithDate: newStatement.date] lowDate]];
    [request setPredicate: predicate];
    self.dbStatements = [context executeFetchRequest: request error: &error];

    // Rearrange statements by day.
    NSDictionary *oldDayStats = [self statementsByDay: self.dbStatements];
    NSDictionary *newDayStats = [self statementsByDay: res.statements];

    // Compare by day.
    NSArray *dates = [newDayStats allKeys];
    for (ShortDate *date in dates) {
        NSMutableArray *oldStatements = oldDayStats[date];
        NSMutableArray *newStatments = newDayStats[date];

        for (newStatement in newStatments) {
            if (newStatement.isPreliminary.boolValue) {
                continue;
            }
            if (oldStatements == nil) {
                newStatement.isNew = @YES;
                continue;
            } else {
                // Find new statement in old statements.
                BOOL isMatched = NO;
                for (BankStatement *oldStatment in oldStatements) {
                    if ([newStatement matchesAndRepair: oldStatment]) {
                        isMatched = YES;
                        [oldStatements removeObject: oldStatment];
                        break;
                    }
                }

                if (!isMatched) {
                    newStatement.isNew = @YES;
                } else {
                    newStatement.isNew = @NO;
                }
            }
        }
    }
}

- (void)updateStandingOrders: (NSArray *)orders {
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    StandingOrder          *stord;
    StandingOrder          *order;
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"StandingOrder" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];


    for (stord in orders) {
        order = [NSEntityDescription insertNewObjectForEntityForName: @"StandingOrder" inManagedObjectContext: context];

        // now copy order to real context
        NSEntityDescription *entity = [stord entity];
        NSArray             *attributeKeys = [[entity attributesByName] allKeys];
        NSDictionary        *attributeValues = [stord dictionaryWithValuesForKeys: attributeKeys];
        [order setValuesForKeysWithDictionary: attributeValues];
        order.account = self;
        order.localAccount = self.accountNumber;
        order.localBankCode = self.bankCode;

        if (order.lastExecDate == nil) {
            order.lastExecDate = [[ShortDate dateWithYear: 2999 month: 12 day: 31] lowDate];
        }
    }
}

- (int)updateFromQueryResult: (BankQueryResult *)result {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    BankStatement          *stat;
    NSDate                 *ltd = self.latestTransferDate;
    ShortDate              *currentDate = nil;
    NSMutableArray         *newStatements = [NSMutableArray arrayWithCapacity: 50];

    // make sure that balance is defined
    if (self.balance == nil) {
        self.balance = [NSDecimalNumber zero];
    }

    result.oldBalance = self.balance;
    if (result.balance) {
        self.balance = [NSDecimalNumber decimalNumberWithDecimal: result.balance.decimalValue];
    }
    if (result.statements == nil) {
        return 0;
    }

    // Give statements at the given day a little offset each so they always sort the same way.
    // Without that statements within the same day can be reordered randomly as they have no time
    // part by default (which would cause trouble once the balance is computed and stored).
    NSDictionary *oldDayStats = [self statementsByDay: self.dbStatements];

    // Statements must be properly sorted!
    NSDate *date;
    for (stat in result.statements) {
        // Preliminary statements are always newly inserted but not marked as new.
        if (!stat.isNew.boolValue && !stat.isPreliminary.boolValue) {
            continue;
        }

        // Copy statement.
        NSEntityDescription *entity = [stat entity];
        NSArray             *attributeKeys = [[entity attributesByName] allKeys];
        NSDictionary        *attributeValues = [stat dictionaryWithValuesForKeys: attributeKeys];

        BankStatement *bankStatement = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement"
                                                            inManagedObjectContext: context];

        [bankStatement setValuesForKeysWithDictionary: attributeValues];
        if (!bankStatement.isPreliminary.boolValue) {
            bankStatement.isNew = @YES;
        }
        [bankStatement sanitize];

        // check for old statements
        ShortDate *stmtDate = [ShortDate dateWithDate: bankStatement.date];

        if (currentDate == nil || ![stmtDate isEqual: currentDate]) {
            // New day found. See if this day is already in the existing statements and if so
            // take the last one for that day, so we continue from there.
            NSArray *oldStats = oldDayStats[stmtDate];
            if (oldStats == nil) {
                date = bankStatement.date;
            } else {
                date = nil;

                // Find the last statement for that day.
                for (BankStatement *oldStat in oldStats) {
                    if (date == nil || [date compare: oldStat.date] == NSOrderedAscending) {
                        date = oldStat.date;
                        if (date == nil) {
                            date = oldStat.valutaDate;
                        }
                    }
                }
                // Advance to a time after the last statement.
                date = [[NSDate alloc] initWithTimeInterval: 10 sinceDate: date];
            }
            currentDate = stmtDate;
        }

        bankStatement.date = date;
        if (bankStatement.valutaDate == nil) {
            bankStatement.valutaDate = date;
        }
        date = [[NSDate alloc] initWithTimeInterval: 10 sinceDate: date];

        [newStatements addObject: bankStatement];
        [bankStatement addToAccount: self];
        if (bankStatement.isPreliminary.boolValue == NO) {
            if (ltd == nil || [ltd compare: bankStatement.date] == NSOrderedAscending) {
                ltd = bankStatement.date;
            }
        }
    }
    [self updateAssignmentsForReportRange];

    if (newStatements.count > 0) {
        if (result.balance == nil) {
            // no balance given - calculate new balance
            NSArray *sds = @[[[NSSortDescriptor alloc] initWithKey: @"date" ascending: YES]];
            [newStatements sortUsingDescriptors: sds];
            NSMutableArray *oldStatements = [self.dbStatements mutableCopy];
            [oldStatements sortUsingDescriptors: sds];             // XXX: is it really necessary to resort existing statements again?

            // find earliest old that is later than first new
            BankStatement *firstNewStat = newStatements[0];

            BOOL            found = NO;
            NSMutableArray  *mergedStatements = [NSMutableArray arrayWithCapacity: 100];
            NSDecimalNumber *newBalance;
            for (stat in oldStatements) {
                if ([stat.date compare: firstNewStat.date] == NSOrderedDescending) {
                    found = YES;
                    if (stat.value != nil) {
                        newBalance = [stat.saldo decimalNumberBySubtracting: stat.value];
                    }
                }
                if (found) {
                    [mergedStatements addObject: stat];
                }
            }
            if (!found) {
                newBalance = self.balance;
            }

            [mergedStatements addObjectsFromArray: newStatements];
            [mergedStatements sortUsingDescriptors: sds];
            
            // Sum up balances.
            for (stat in mergedStatements) {
                if (stat.value != nil && stat.isPreliminary.boolValue == NO) {
                    newBalance = [newBalance decimalNumberByAdding: stat.value];
                }
                stat.saldo = newBalance;
            }
            self.balance = newBalance;
        } else {
            // balance was given - calculate back
            NSMutableArray *mergedStatements = [NSMutableArray arrayWithCapacity: 100];
            [mergedStatements addObjectsFromArray: newStatements];
            [mergedStatements addObjectsFromArray: self.dbStatements];
            NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
            NSArray          *sds = @[sd];
            [mergedStatements sortUsingDescriptors: sds];
            NSDecimalNumber *newBalance = self.balance;
            for (stat in mergedStatements) {
                stat.saldo = newBalance;
                if (stat.isPreliminary.boolValue == NO) {
                    newBalance = [newBalance decimalNumberBySubtracting: stat.value];
                }
            }
        }
        [self copyStatementsToManualAccounts: newStatements];
    }

    self.latestTransferDate = ltd;
    [self  calcUnread];
    return [newStatements count];
}

- (void)updateStatementBalances {
    // repair balances
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
    NSArray          *sortedStatements = [[self valueForKey: @"statements"] sortedArrayUsingDescriptors: @[sd]];

    NSDecimalNumber *balance = self.balance;
    for (BankStatement *statement in sortedStatements) {
        if (![statement.saldo isEqual: balance]) {
            statement.saldo = balance;
        }
        if (!statement.isPreliminary.boolValue) {
            // Preliminary statements have no representation in the balance yet, so don't
            // take them into account.
            balance = [balance decimalNumberBySubtracting: statement.value];
        }
    }
}

- (BOOL)updateSupportedTransactions {
    BOOL success = YES;

    for (BankUser *user in self.users) {
        if ([user.userId isEqualToString: self.userId]) {
            PecuniaError *error = [[HBCIController controller] updateSupportedTransactionsForUser:user];
            if (error != nil) {
                [error alertPanel];
                success = NO;
            }
        }
    }
    return success;
}

- (void)updateBalanceWithValue: (NSDecimalNumber *)value {
    if ([self.balance compare: value] != NSOrderedSame) {
        self.balance = value;
        [self updateStatementBalances];
    }
}

/**
 * Account maintance is done here which involves things like correcting transfer times (for correct
 * ordering), balance recomputation and field validation.
 */
- (void)doMaintenance {
    NSArray *statementsArray = [self valueForKey: @"statements"];

    // first repair date if not defined
    for (BankStatement *statement in statementsArray) {
        if (statement.date == nil && statement.valutaDate != nil) {
            statement.date = statement.valutaDate;
        }
    }
    // Then ensure that statements on a single day have a little time offset each,
    // so they can maintain a fixed sort order.
    // For now we don't fix valutaDate, though.
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: YES];
    NSArray          *sortedStatements = [statementsArray sortedArrayUsingDescriptors: @[sd]];
    NSDictionary     *statements = [self statementsByDay: sortedStatements];
    for (ShortDate *date in statements.allKeys) {
        NSDate *newDate = nil;
        BOOL   doRepair = NO;
        for (BankStatement *statement in statements[date]) {
            if (newDate == nil) {
                newDate = statement.date;
            } else {
                if (!doRepair) {
                    if ([statement.date isEqualToDate: newDate]) {
                        doRepair = YES;
                    } else {
                        newDate = statement.date;
                    }
                }

                if (doRepair) {
                    statement.date = [[NSDate alloc] initWithTimeInterval: 10 sinceDate: newDate];
                    newDate = statement.date;
                }
            }
        }
    }
    // repair balances
    [self updateStatementBalances];

    for (BankStatement *statement in sortedStatements) {
        [statement sanitize];
    }
}

+ (BankAccount *)bankRootForCode: (NSString *)bankCode {
    BOOL    found = NO;
    NSError *error = nil;

    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSManagedObjectModel   *model   = [[MOAssistant sharedAssistant] model];

    NSFetchRequest *request = [model fetchRequestTemplateForName: @"bankNodes"];
    NSArray        *nodes = [context executeFetchRequest: request error: &error];
    if (error != nil || nodes == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }

    BankAccount *bankNode;
    for (bankNode in nodes) {
        if ([[bankNode valueForKey: @"bankCode"] isEqual: bankCode]) {
            found = YES;
            break;
        }
    }
    if (found) {
        return bankNode;
    } else {
        return nil;
    }
}

- (void)setAccountNumber: (NSString *)n {
    [self willAccessValueForKey: @"accountNumber"];
    [self setPrimitiveValue: n forKey: @"accountNumber"];
    [self didAccessValueForKey: @"accountNumber"];
}

- (NSString *)accountNumber {
    [self willAccessValueForKey: @"accountNumber"];
    NSString *n = [self primitiveValueForKey: @"accountNumber"];
    [self didAccessValueForKey: @"accountNumber"];
    return n;
}

- (NSDate *)nextDateForDate: (NSDate *)date {
    NSError *error = nil;
    NSDate  *startDate = [[ShortDate dateWithDate: date] lowDate];
    NSDate  *endDate = [[ShortDate dateWithDate: date] highDate];
    NSDate  *currentDate;

    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@) AND (date < %@)", self, startDate, endDate];
    [request setPredicate: predicate];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: NO];
    NSArray          *sds = @[sd];
    [request setSortDescriptors: sds];

    NSArray *statements = [context executeFetchRequest: request error: &error];
    if (statements == nil || [statements count] == 0) {
        return startDate;
    }

    currentDate = [statements[0] date];
    return [[NSDate alloc] initWithTimeInterval: 100 sinceDate: currentDate];
}

- (void)copyStatement: (BankStatement *)stat {
    NSDate                 *startDate = [[ShortDate dateWithDate: stat.date] lowDate];
    NSDate                 *endDate = [[ShortDate dateWithDate: stat.date] highDate];
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSError                *error = nil;

    // first copy statement
    NSEntityDescription *entity = [stat entity];
    NSArray             *attributeKeys = [[entity attributesByName] allKeys];
    NSDictionary        *attributeValues = [stat dictionaryWithValuesForKeys: attributeKeys];

    BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement"
                                                        inManagedObjectContext: context];

    [stmt setValuesForKeysWithDictionary: attributeValues];

    // make sure value is defined
    if (stmt.value == nil) {
        stmt.value = [NSDecimalNumber zero];
    }

    // negate value
    stmt.value = [[NSDecimalNumber zero] decimalNumberBySubtracting: stmt.value];

    // next check if duplicate
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankStatement" inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date >= %@) AND (date < %@)", self, startDate, endDate];
    [request setPredicate: predicate];
    NSArray *statements = [context executeFetchRequest: request error: &error];
    for (BankStatement *statement in statements) {
        if ([statement matches: stmt]) {
            [context deleteObject: stmt];
            return;
        }
    }
    // Balance.
    stmt.date = [self nextDateForDate: stmt.date];

    // adjust all statements after the current
    predicate = [NSPredicate predicateWithFormat: @"(account = %@) AND (date > %@)", self, stmt.date];
    [request setPredicate: predicate];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"date" ascending: YES];
    NSArray          *sds = @[sd];
    [request setSortDescriptors: sds];

    statements = [context executeFetchRequest: request error: &error];
    if (statements == nil || [statements count] == 0) {
        self.balance = [self.balance decimalNumberByAdding: stmt.value];
        stmt.saldo = self.balance;
    } else {
        BankStatement   *statement = statements[0];
        NSDecimalNumber *base = [statement.saldo decimalNumberBySubtracting: statement.value];
        stmt.saldo = [base decimalNumberByAdding: stmt.value];

        for (statement in statements) {
            statement.saldo = [statement.saldo decimalNumberByAdding: stmt.value];
            self.balance = statement.saldo;
        }
    }

    // add to account
    [stmt addToAccount: self];

    NSArray *categoryAssignments = [stat categoryAssignments];
    for (StatCatAssignment *assignment in categoryAssignments) {
        [stmt assignAmount: [[NSDecimalNumber zero] decimalNumberBySubtracting: assignment.value] toCategory: assignment.category withInfo: assignment.userInfo];
    }
}

- (void)copyStatementsToManualAccounts: (NSArray *)statements {
    NSError *error = nil;

    // find all manual accounts that have rules
    if ([self.isManual boolValue] == YES) {
        return;
    }
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isManual = 1) AND (rule != nil)"];
    [request setPredicate: predicate];
    NSArray *accounts = [context executeFetchRequest: request error: &error];
    if (accounts == nil || error || [accounts count] == 0) {
        return;
    }

    for (BankAccount *account in accounts) {
        NSPredicate *pred = [NSPredicate predicateWithFormat: account.rule];
        for (BankStatement *stat in statements) {
            if ([pred evaluateWithObject: stat]) {
                [account copyStatement: stat];
            }
        }
    }
}

- (BankUser *)defaultBankUser {
    // If there are multiple user ids per bank account this might need adjustment.
    NSSet *users = self.users;
    if (users.count == 0) {
        LogError(@"Account %@: no assigned users", self.accountNumber);
        return nil;
    }

    if (self.userId == nil) {
        BankUser *user = [[users allObjects] firstObject];
        self.userId = user.userId;
        return user;
    }
    for (BankUser *user in users) {
        if ([user.userId isEqualToString:self.userId]) {
            return user;
        }
    }
    BankUser *user = [[users allObjects] firstObject];
    self.userId = user.userId;
    return user;
}

+ (BankAccount *)findAccountWithNumber: (NSString *)number bankCode: (NSString *)code {
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSManagedObjectModel   *model = [[MOAssistant sharedAssistant] model];

    NSError      *error = nil;
    NSDictionary *subst = @{
        @"ACCNT": number, @"BCODE": code
    };
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName: @"bankAccountByID" substitutionVariables: subst];
    NSArray        *results = [context executeFetchRequest: fetchRequest error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if (results == nil || [results count] != 1) {
        return nil;
    }
    return results[0];
}

+ (BankAccount *)findAccountWithNumber: (NSString *)number subNumber: (NSString *)subNumber bankCode: (NSString *)code {
    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    NSManagedObjectModel   *model = [[MOAssistant sharedAssistant] model];

    NSError      *error = nil;
    NSDictionary *subst = @{
        @"ACCNT": number, @"BCODE": code
    };
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName: @"bankAccountByID" substitutionVariables: subst];
    NSArray        *results = [context executeFetchRequest: fetchRequest error: &error];
    if (error != nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }
    if (results == nil || [results count] == 0) {
        return nil;
    }
    if ([results count] == 1 || subNumber == nil) {
        return [results lastObject];
    }
    for (BankAccount *account in results) {
        if ([account.accountSuffix isEqualToString: subNumber]) {
            return account;
        }
    }
    return nil;
}

+ (NSInteger)maxUnread {
    NSError   *error = nil;
    NSInteger unread = 0;

    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];
    if (context == nil) {
        return 0;
    }
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"BankAccount" inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isManual = 0) AND (accountNumber != nil)"];
    [request setPredicate: predicate];
    NSArray *accounts = [context executeFetchRequest: request error: &error];
    if (accounts == nil || error || [accounts count] == 0) {
        return 0;
    }

    for (BankAccount *account in accounts) {
        NSInteger n = [account calcUnread];
        if (n > unread) {
            unread = n;
        }
    }
    return unread;
}

- (NSString *)description {
    return [self descriptionWithIndent: @""];
}

- (NSString *)descriptionWithIndent: (NSString *)indent {
    NSMutableString *s = [NSMutableString string];
    switch (self.type.intValue) {
        case AccountType_Standard: {
            NSString *fs = NSLocalizedString(@"AP1000", @"");
            [s appendFormat: fs, indent, self.accountNumber, self.accountSuffix, self.bankCode];

            fs = NSLocalizedString(@"AP1001", @"");
            [s appendFormat: fs, indent, self.userId, self.iban, self.bic];

            break;
        }

        case AccountType_CreditCart: {
            [s appendFormat: NSLocalizedString(@"AP1002", @""), indent, self.accountNumber];
            break;
        }

        default:
            [s appendFormat: NSLocalizedString(@"AP1003", @""), indent];
            break;
    }

    [s appendFormat: NSLocalizedString(@"AP1004", @""), indent];
    if ([self.isManual boolValue]) {
        [s appendString: NSLocalizedString(@"AP1005", @"")];
    } else {
        if ([self.noAutomaticQuery boolValue]) {
            [s appendString: NSLocalizedString(@"AP1006", @"")];
        }
    }
    if ([self.isHidden boolValue]) {
        [s appendString: NSLocalizedString(@"AP1007", @"")];
    }
    if ([self.noCatRep boolValue]) {
        [s appendString: NSLocalizedString(@"AP1008", @"")];
    }
    if ([self.isStandingOrderSupported boolValue]) {
        [s appendString: NSLocalizedString(@"AP1009", @"")];
    }

    [s appendFormat: NSLocalizedString(@"AP1010", @""), indent];

    NSArray *infos = [SupportedTransactionInfo supportedTransactionsForAccount: self];
    for (SupportedTransactionInfo *info in infos) {
        [s appendFormat: @"    %@", [info descriptionWithIndent: indent]];
    }
    [s appendFormat: @"%@}", indent];
    return s;
}

@end
