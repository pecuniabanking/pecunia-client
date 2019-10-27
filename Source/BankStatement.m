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

#import "MessageLog.h"

#import "BankStatement.h"
#import "BankingCategory.h"
#import "MOAssistant.h"
#import "StatCatAssignment.h"
#import "ShortDate.h"
#import "SEPAMT94xPurposeParser.h"
#import "SepaData.h"

static NSArray *catCache = nil;

static NSRegularExpression *ibanRE;
static NSRegularExpression *bicRE;

@implementation BankStatement

@dynamic valutaDate;
@dynamic date;

@dynamic value, nassValue, charge, saldo;
@dynamic localBankCode, localAccount;
@dynamic remoteName, remoteIBAN, remoteBIC, remoteBankCode, remoteAccount, remoteCountry, remoteBankName;
@dynamic purpose, localSuffix, remoteSuffix;

@dynamic customerReference, bankReference;
@dynamic transactionCode, transactionText;
@dynamic primaNota;
@dynamic currency;
@dynamic additional;
@dynamic isAssigned;    // assigned to >= 100%
@dynamic account;
@dynamic type;
@dynamic isManual;
@dynamic isStorno;
@dynamic isNew;
@dynamic isPreliminary;
@dynamic ref1, ref2, ref3, ref4;

@dynamic docDate, origValue, origCurrency, isSettled, ccNumberUms, ccChargeForeign, ccChargeTerminal, ccChargeKey, ccSettlementRef;
@dynamic tags, sepa;

BOOL stringEqualIgnoreWhitespace(NSString *a, NSString *b) {
    NSUInteger     i = 0, j = 0;
    NSUInteger     l1, l2;
    BOOL           done = NO;
    NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    if (a == nil && b == nil) {
        return YES;
    }
    if (a == nil && b != nil && [b length] == 0) {
        return YES;
    }
    if (a != nil && b == nil && [a length] == 0) {
        return YES;
    }
    if (a == nil && b != nil) {
        return NO;
    }
    if (a != nil && b == nil) {
        return NO;
    }
    l1 = [a length];
    l2 = [b length];
    while (done == NO) {
        //find first of a and b
        while (i < l1 && [cs characterIsMember: [a characterAtIndex: i]]) {
            i++;
        }
        while (j < l2 && [cs characterIsMember: [b characterAtIndex: j]]) {
            j++;
        }
        if (i == l1 && j == l2) {
            return YES;
        }
        if (i < l1 && j < l2) {
            if ([a characterAtIndex: i] != [b characterAtIndex: j]) {
                return NO;
            } else {
                i++;
                j++;
            }
        } else {
            return NO;
        }
    }
    return YES;
}

BOOL stringEqualIgnoringMissing(NSString *a, NSString *b) {
    if (a == nil || b == nil) {
        return YES;
    }
    if ([a length] == 0 || [b length] == 0) {
        return YES;
    }
    return [a isEqualToString: b];
}

BOOL stringEqual(NSString *a, NSString *b) {
    if (a == nil && b == nil) {
        return YES;
    }
    if (a == nil && b != nil && [b length] == 0) {
        return YES;
    }
    if (a != nil && b == nil && [a length] == 0) {
        return YES;
    }
    if (a == nil && b != nil) {
        return NO;
    }
    if (a != nil && b == nil) {
        return NO;
    }
    return [a isEqualToString: b];
}

+ (void)initialize {
    // Can be called multiple times, so just take care not to initialize more than once.
    if (ibanRE == nil) {
        ibanRE = [NSRegularExpression regularExpressionWithPattern: @"^[a-zA-Z]{2}[0-9]{2}[a-zA-Z0-9]{4}[0-9]{7}([a-zA-Z0-9]?){0,16}$"
                                                           options: 0
                                                             error: nil];
    }
    if (bicRE == nil) {
        bicRE = [NSRegularExpression regularExpressionWithPattern: @"^([a-zA-Z]{4}[a-zA-Z]{2}[a-zA-Z0-9]{2}([a-zA-Z0-9]{3})?)$"
                                                          options: 0
                                                            error: nil];
    }
}

// Helper factory method to create a BankStatement instance in the memory context.
+ (instancetype)createTemporary {
    return [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement" inManagedObjectContext: MOAssistant.sharedAssistant.memContext];
}

- (NSString *)categoriesDescription {
    NSMutableSet      *stats = [self mutableSetValueForKey: @"assignments"];
    NSMutableSet      *cats = [NSMutableSet setWithCapacity: 10];
    StatCatAssignment *stat;
    NSString          *result = nil;
    for (stat in stats) {
        BankingCategory *cat = stat.category;
        if (cat == nil) {
            continue;
        }
        // avoid same category several times
        if ([cats containsObject: cat]) {
            continue;
        } else {
            [cats addObject: cat];
        }

        if (cat.isBankAccount) {
            continue;
        }
        if (cat.isNotAssignedCategory) {
            continue;
        }
        if (result) {
            result = [NSString stringWithFormat: @"%@, %@", result, [cat localName]];
        } else {
            result = [cat localName];
        }
    }
    if (result) {
        return result;
    } else {
        return @"";
    }
}

/**
 * Central point for assigning statements to their account. Here we do a mapping between the account (category)
 * and ourselve. After that we run all defined rules for assigning to categories and other actions.
 */
- (void)addToAccount: (BankAccount *)account {
    if (account == nil) {
        return;
    }

    NSManagedObjectContext *context = [[MOAssistant sharedAssistant] context];

    // Create new to-many relationship between the account and the statement (ourselve) and keep that in our
    // assignments set.
    StatCatAssignment *stat = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment"
                                                            inManagedObjectContext: context];
    stat.value = self.value;
    stat.category = (BankingCategory *)account;
    stat.statement = self;

    self.account = account;
    NSMutableSet *stats = [self mutableSetValueForKey: @"assignments"];
    [stats addObject: stat];

    if (self.isPreliminary.boolValue == NO) {
        // Initialize the categories cache if not yet done and run all category rules.
        if (catCache == nil) {
            [BankStatement initCategoriesCache];
        }
        for (BankingCategory *cat in catCache) {
            NSPredicate *pred = [NSPredicate predicateWithFormat: cat.rule];
            @try {
                if ([pred evaluateWithObject: stat]) {
                    [self assignToCategory: cat];
                }
            }
            @catch (NSException *exception) {
                LogError(@"Fehler in Regel: %@. Ursache: %@", cat.rule, exception.debugDescription);
            }
        }
    }

    // See if there is some value left that is not yet assigned to a category.
    [self updateAssigned];
}

/**
 * extract MT940 SEPA data
 */
- (void)extractSEPADataUsingContext: (NSManagedObjectContext *)context {
    // Examine purpose to see if we need to extract SEPA informations.
    NSDictionary *values = nil;
    
    @try {
        values = [SEPAMT94xPurposeParser parse: self.purpose];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception when parsing SEPA information from %@", self.purpose);
        return;
    }

    if (values != nil && values.count > 0) {
        if (self.sepa == nil) {
            self.sepa = [NSEntityDescription insertNewObjectForEntityForName: @"SepaData"
                                                      inManagedObjectContext: context];
        }

        static NSDateFormatter *sepaDateFormatter = nil;
        if (sepaDateFormatter == nil) {
            sepaDateFormatter = [NSDateFormatter new];
            sepaDateFormatter.dateFormat = @"yyyy-MM-dd";
        }

        @try {
            NSString *iban = values[@"IBAN"];
            if ([SepaService isValidIBAN: iban] && ![SepaService isValidIBAN: self.remoteIBAN]) {
                if (iban != nil && iban.length <= 34) {
                    self.remoteIBAN = iban;
                } else {
                    LogError(@"IBAN-Information konnte nicht ermittelt werden aus Verwendungszweck %@, IBAN %@ ist ungültig", self.purpose, iban);
                }
            }
            NSString *bic = values[@"BIC"];
            if ([SepaService isValidBIC: bic] && ![SepaService isValidBIC: self.remoteBIC]) {
                if (bic != nil && bic.length <= 11) {
                    self.remoteBIC = bic;
                } else {
                    LogError(@"BIC-Information konnte nicht ermittelt werden aus Verwendungszweck %@, BIC %@ ist ungültig", self.purpose, bic);
                }
        }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception while checking IBAN/BIC");
        }

        self.sepa.endToEndId = values[@"EREF"]; // Sets to nil if not existent.
        self.sepa.purpose = values[@"SVWZ"];
        self.sepa.ultimateDebitorId = values[@"ABWA"];
        self.sepa.ultimateCreditorId = values[@"ABWE"];
        self.sepa.purposeCode = values[@"PURP"];
        self.sepa.mandateId = values[@"MREF"];
        self.sepa.creditorId = values[@"CRED"];
        if (values[@"MDAT"] != nil) {
            NSDate *date = [sepaDateFormatter dateFromString: values[@"MDAT"]];
            if (date != nil) {
            self.sepa.mandateSignatureDate = date;
            }
        } else {
            self.sepa.mandateSignatureDate = nil;
        }
        self.sepa.sequenceType = values[@"SQTP"];
        self.sepa.oldCreditorId = values[@"ORCR"];
        self.sepa.oldMandateId = values[@"ORMR"];
        if (values[@"DDAT"] != nil) {
            NSDate *date = [sepaDateFormatter dateFromString: values[@"DDAT"]];
            if (date != nil) {
            self.sepa.settlementDate = date;
            }
        } else {
            self.sepa.settlementDate = nil;
        }
        self.sepa.debitorId = values[@"DEBT"];
        self.customerReference = values[@"KREF"];
        if (values[@"COAM"] != nil) {
            self.charge = [[NSDecimalNumber alloc] initWithString: values[@"COAM"]
                                                           locale: @{NSLocaleDecimalSeparator: @"."}];
        } else {
            self.charge = nil;
        }
        if (values[@"OAMT"] != nil) {
            // Currently not yet clear, but assume there can be a currency attached.
            static NSRegularExpression *amountRegEx;
            if (amountRegEx == nil) {
                amountRegEx = [NSRegularExpression regularExpressionWithPattern: @"([A-Za-z]*)([0-9][0-9.,]*)([A-Za-z]*)" options: 0 error: nil];
            }
            NSString *value = values[@"OAMT"];
            NSArray  *matches = [amountRegEx matchesInString: value options: 0 range: NSMakeRange(0, value.length)];

            NSDecimalNumber *amount;
            if (matches.count == 0) {
                amount = [[NSDecimalNumber alloc] initWithString: value locale: @{NSLocaleDecimalSeparator: @"."}];
            } else {
                // If there's a match we always have 4 ranges: at 0 the full range + 3 capture groups.
                NSTextCheckingResult *match = matches[0];
                NSRange              range = [match rangeAtIndex: 1];
                if (range.length > 0) {
                    // Leading currency.
                    self.origCurrency = [value substringWithRange: range];
                }
                range = [match rangeAtIndex: 2];
                amount = [[NSDecimalNumber alloc] initWithString: [value substringWithRange: range] locale: @{NSLocaleDecimalSeparator: @"."}];

                range = [match rangeAtIndex: 3];
                if (range.length > 0) {
                    // Trailing currency. Hopefully not together with a leaading currency.
                    // If so, the trailing one wins.
                    self.origCurrency = [value substringWithRange: range];
                }
            }
            self.origValue = (amount == NSDecimalNumber.notANumber) ? nil : amount;
        } else {
            self.origValue = nil;
        }
    }
}

/**
 * Runs some checks for values that are in wrong locations or missing etc. and corrects those.
 */
- (void)sanitize {
    // 1) Sanity check for date/valutaDate.
    if (self.valutaDate == nil) {
        if (self.date != nil) {
            self.valutaDate = self.date;
        } else {
            self.valutaDate = [NSDate date];
        }
    }

    // 2) Check remote bank code, account number, IBAN and BIC.
    //    Move info in the correct fields if they are wrong.
    if (self.remoteIBAN == nil && self.remoteAccount != nil) {
        NSRange range = [ibanRE rangeOfFirstMatchInString: self.remoteAccount
                                                  options: NSMatchingAnchored
                                                    range: NSMakeRange(0, self.remoteAccount.length)];

        if (range.length > 0) {
            if (self.remoteAccount.length <= 34) {
                self.remoteIBAN = self.remoteAccount;
            }
            self.remoteAccount = nil;
        }
    }

    if (self.remoteBIC == nil && self.remoteBankCode != nil) {
        NSRange range = [bicRE rangeOfFirstMatchInString: self.remoteBankCode
                                                 options: NSMatchingAnchored
                                                   range: NSMakeRange(0, self.remoteBankCode.length)];

        if (range.length > 0) {
            if (self.remoteBankCode.length <= 11) {
                self.remoteBIC = self.remoteBankCode;
            }
            self.remoteBankCode = nil;
        }
    }

    [self extractSEPADataUsingContext: MOAssistant.sharedAssistant.context];
}

- (BOOL)matches: (BankStatement *)stat {
    ShortDate *d1 = [ShortDate dateWithDate: self.date];
    ShortDate *d2 = [ShortDate dateWithDate: stat.date];

    LogDebug(@"-------------------matches------------------------------------");
    if ([d1 isEqual: d2] == NO) {
        LogDebug(@"Dates different: %@, %@", d1.description, d2.description);
        return NO;
    }
    if (fabs([self.value doubleValue] - [stat.value doubleValue]) > 0.001) {
        LogDebug(@"Value different: %f, %f", self.value.doubleValue, stat.value.doubleValue);
        return NO;
    }

    if (stringEqualIgnoreWhitespace(self.purpose, stat.purpose) == NO) {
        LogDebug(@"Purpose different: %@, %@", self.purpose, stat.purpose);
        return NO;
    }
    if (stringEqualIgnoreWhitespace(self.remoteName, stat.remoteName) == NO) {
        LogDebug(@"Name different: %@, %@", self.remoteName, stat.remoteName);
        return NO;
    }

    if (stringEqualIgnoringMissing(self.remoteAccount, stat.remoteAccount) == NO) {
        LogDebug(@"RemoteAccount different: %@, %@", self.remoteAccount, stat.remoteAccount);
        return NO;
    }
    if (stringEqualIgnoringMissing(self.remoteBankCode, stat.remoteBankCode) == NO) {
        LogDebug(@"RemoteBankCode different: %@, %@", self.remoteBankCode, stat.remoteBankCode);
        return NO;
    }
    if (stringEqualIgnoringMissing(self.remoteBIC, stat.remoteBIC) == NO) {
        LogDebug(@"RemoteBIC different: %@, %@", self.remoteBIC, stat.remoteBIC);
        return NO;
    }
    if (stringEqualIgnoringMissing(self.remoteIBAN, stat.remoteIBAN) == NO) {
        LogDebug(@"RemoteIBAN different: %@, %@", self.remoteIBAN, stat.remoteIBAN);
        return NO;
    }

    return YES;
}

- (BOOL)matchesAndRepair: (BankStatement *)stat {
    NSDecimalNumber *e = [NSDecimalNumber decimalNumberWithMantissa: 1 exponent: -2 isNegative: NO];
    ShortDate       *d1 = [ShortDate dateWithDate: self.date];
    ShortDate       *d2 = [ShortDate dateWithDate: stat.date];

    LogDebug(@"-------------------matchesAndRepair------------------------------------");
    if ([d1 isEqual: d2] == NO) {
        LogDebug(@"Dates different: %@, %@", d1.description, d2.description);
        return NO;
    }

    if (stringEqualIgnoreWhitespace(self.purpose, stat.purpose) == NO) {
        LogDebug(@"Purpose different: %@, %@", self.purpose, stat.purpose);
        return NO;
    }
    if (stringEqualIgnoreWhitespace(self.remoteName, stat.remoteName) == NO) {
        LogDebug(@"Name different: %@, %@", self.remoteName, stat.remoteName);
        return NO;
    }

    if (stringEqualIgnoringMissing(self.remoteAccount, stat.remoteAccount) == NO) {
        LogDebug(@"RemoteAccount different: %@, %@", self.remoteAccount, stat.remoteAccount);
        return NO;
    }
    if (stringEqualIgnoringMissing(self.remoteBankCode, stat.remoteBankCode) == NO) {
        LogDebug(@"RemoteBankCode different: %@, %@", self.remoteBankCode, stat.remoteBankCode);
        return NO;
    }
    if (stringEqualIgnoringMissing(self.remoteBIC, stat.remoteBIC) == NO) {
        LogDebug(@"RemoteBIC different: %@, %@", self.remoteBIC, stat.remoteBIC);
        return NO;
    }
    if (stringEqualIgnoringMissing(self.remoteIBAN, stat.remoteIBAN) == NO) {
        LogDebug(@"RemoteIBAN different: %@, %@", self.remoteIBAN, stat.remoteIBAN);
        return NO;
    }

    NSDecimalNumber *d = [[self.value decimalNumberBySubtracting: stat.value] abs];
    if ([d compare: e] == NSOrderedDescending) {
        LogDebug(@"Value different: %f, %f", self.value.doubleValue, stat.value.doubleValue);
        return NO;
    }
    if ([d compare: e] == NSOrderedSame) {
        // repair
        [stat changeValueTo: self.value];
    }
    return YES;
}

- (void)changeValueTo: (NSDecimalNumber *)val {
    BankingCategory *ncat = [BankingCategory nassRoot];

    self.value = val;
    NSMutableSet *stats = [self mutableSetValueForKey: @"assignments"];
    for (StatCatAssignment *stat in stats) {
        if ([stat.category isBankAccount]) {
            stat.value = val;
        }
        // if there is only one category assignment, change that as well
        if (stat.category != ncat && [stats count] == 2) {
            stat.value = val;
        }
    }
    [self updateAssigned];
}

- (BOOL)hasAssignment {
    StatCatAssignment *stat;
    BankingCategory   *ncat = [BankingCategory nassRoot];
    NSMutableSet      *stats = [self mutableSetValueForKey: @"assignments"];
    NSEnumerator      *iter = [stats objectEnumerator];
    while ((stat = [iter nextObject]) != nil) {
        if ([stat.category isBankAccount] == NO && stat.category != ncat) {
            return YES;
        }
    }
    return NO;
}

- (StatCatAssignment *)bankAssignment {
    NSMutableSet      *stats = [self mutableSetValueForKey: @"assignments"];
    StatCatAssignment *stat;
    for (stat in stats) {
        if ([stat.category isBankAccount] == YES) {
            return stat;
        }
    }
    return nil;
}

- (NSArray *)categoryAssignments {
    NSMutableArray    *categoryAssignments = [NSMutableArray arrayWithCapacity: 10];
    NSMutableSet      *stats = [self mutableSetValueForKey: @"assignments"];
    StatCatAssignment *stat;
    for (stat in stats) {
        if ([stat.category isBankAccount] == NO) {
            [categoryAssignments addObject: stat];
        }
    }
    return categoryAssignments;
}

- (BOOL)updateAssigned {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    NSDecimalNumber *value = self.value;

    BOOL positive = [value compare: [NSDecimalNumber zero]] != NSOrderedAscending;
    BOOL assigned = NO;
    BOOL ncatNeedsRefresh = NO;

    BankingCategory *ncat = BankingCategory.nassRoot;

    NSSet *assignments = [self valueForKey: @"assignments"];
    for (StatCatAssignment *assignment in assignments) {
        if (!assignment.value) {
            assignment.value = [NSDecimalNumber zero];
        }
        if (![assignment.category isBankAccount] && assignment.category != ncat) {
            value = [value decimalNumberBySubtracting: assignment.value];
        }
    }
    if (positive) {
        if ([value compare: [NSDecimalNumber zero]] != NSOrderedDescending) {
            assigned = YES;                                                                          // fully assigned
        }
    } else {
        if ([value compare: [NSDecimalNumber zero]] != NSOrderedAscending) {
            assigned = YES;                                                                         // fully assigned
        }
    }
    self.isAssigned = @(assigned);

    // update not assigned part
    if (assigned == NO) {
        self.nassValue = value;
    } else {
        self.nassValue = [NSDecimalNumber zero];
    }

    // Another round, find the first assignment to the not-assigned category (if any).
    BOOL found = NO;
    for (StatCatAssignment *assignment in assignments) {
        if (assignment.category == ncat) {
            if (assigned || [assignment.value compare: value] != NSOrderedSame) {
                [ncat invalidateBalance];
            }
            if (assigned) {
                [context deleteObject: assignment];
                ncatNeedsRefresh = YES;
            } else {
                assignment.value = value;
            }
            found = YES;
            break;
        }
    }
    if (!found && !assigned) {
        // Create a new assignment to not-assigned category.
        StatCatAssignment *assignment = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment" inManagedObjectContext: context];
        assignment.value = value;
        assignment.category = ncat;
        assignment.statement = self;
        ncatNeedsRefresh = YES;
    }
    return ncatNeedsRefresh;
}

- (NSDecimalNumber *)residualAmount {
    BankingCategory   *ncat = [BankingCategory nassRoot];
    NSMutableSet      *stats = [self mutableSetValueForKey: @"assignments"];
    NSEnumerator      *iter = [stats objectEnumerator];
    StatCatAssignment *stat;
    while ((stat = [iter nextObject]) != nil) {
        if (stat.category == ncat) {
            return stat.value;
        }
    }
    return [NSDecimalNumber zero];
}

- (void)assignToCategory: (BankingCategory *)cat {
    [self assignAmount: self.value toCategory: cat withInfo: nil];
}

- (void)assignAmount: (NSDecimalNumber *)value toCategory: (BankingCategory *)targetCategory withInfo: (NSString *)info {
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;

    // First check if this statement is already assigned to the target category. If so add the given value to that category
    // or remove the assignment if the value is nil/zero.
    BOOL         foundTarget = NO;
    NSMutableSet *assignments = [self valueForKey: @"assignments"];
    for (StatCatAssignment *assignment in assignments) {
        if (assignment.category == targetCategory) {
            if (value == nil || [value isEqual: [NSDecimalNumber zero]]) {
                [context deleteObject: assignment];
            } else {
                assignment.value = [assignment.value decimalNumberByAdding: value];

                // Ensure the assigned value is not larger than the statement's value.
                if ([[assignment.value abs] compare: [assignment.statement.value abs]] == NSOrderedDescending) {
                    assignment.value = assignment.statement.value;
                }

                if (info.length > 0) {
                    if (assignment.userInfo && assignment.userInfo.length > 0) {
                        assignment.userInfo = [NSString stringWithFormat: @"%@\n%@", assignment.userInfo, info];
                    } else {
                        assignment.userInfo = info;
                    }
                }
            }
            foundTarget = YES;
            break;
        }
    }
    if (!foundTarget) {
        // There's no assignment for the given target yet so create a new one.
        StatCatAssignment *assignment = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment" inManagedObjectContext: context];
        StatCatAssignment *bankAssignment = [self bankAssignment];
        assignment.value = value;
        if (targetCategory) {
            assignment.category = targetCategory;
        }
        assignment.statement = self;
        if (info == nil) {
            // If there's no info given use that of the bank assignment.
            if (bankAssignment.userInfo) {
                assignment.userInfo = bankAssignment.userInfo;
            } else {
                assignment.userInfo = @"";
            }
        } else {
            assignment.userInfo = info;
        }
        [assignments addObject: assignment];
    }

    [self updateAssigned];

    [targetCategory invalidateBalance];
    [BankingCategory.nassRoot invalidateBalance];
}

- (NSComparisonResult)compareValuta: (BankStatement *)stat {
    return [self.valutaDate compare: stat.valutaDate];
}

+ (void)initCategoriesCache {
    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.sharedAssistant.context;
    NSManagedObjectModel   *model = MOAssistant.sharedAssistant.model;

    catCache = nil;
    NSFetchRequest *request = [model fetchRequestTemplateForName: @"categories"];
    catCache = [context executeFetchRequest: request error: &error];
    if (error != nil || catCache == nil) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (NSString *)floatingPurpose {
    // replace newline with space
    NSString *s = self.sepa == nil ? self.purpose : self.sepa.purpose;
    s = [s stringByReplacingOccurrencesOfString: @"\n " withString: @" "];
    s = [s stringByReplacingOccurrencesOfString: @" \n" withString: @" "];
    return [s stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
}

- (NSString *)nonfloatingPurpose {
    return self.sepa == nil ? self.purpose : self.sepa.purpose;
}

- (NSString *)note {
    StatCatAssignment *stat = [self bankAssignment];
    return stat.userInfo;
}

@end
