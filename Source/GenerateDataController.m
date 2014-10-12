/**
 * Copyright (c) 2012, 2014, Pecunia Project. All rights reserved.
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

#import "GenerateDataController.h"
#import "MOAssistant.h"
#import "BankUser.h"
#import "Category.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "StatCatAssignment.h"
#import "ShortDate.h"
#import "StandingOrder.h"
#import "LocalSettingsController.h"

#import "SystemNotification.h"

static NSString *DemoDataKey = @"contains-demo-data";

@interface GenerateDataController ()

@end

@implementation GenerateDataController

@synthesize startYear;
@synthesize endYear;
@synthesize bankCount;
@synthesize maxAccountsPerBank;
@synthesize numberOfStatementsPerBank;

- (id)init;
{
    self = [super initWithWindowNibName: @"GenerateDataController"];
    if (self) {
        calendar = [ShortDate calendar];

        startYear = 2008;
        endYear = 2013;
        bankCount = 5;
        maxAccountsPerBank = 3;
        numberOfStatementsPerBank = 650;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary   *values = [defaults objectForKey: @"generator-values"];
        if (values != nil) {
            if ([values[@"path"] length] > 0) {
                self.path.stringValue = values[@"path"];
            }
            if (values[@"startYear"] != nil) {
                startYear = [values[@"startYear"] integerValue];
            }
            if (values[@"endYear"] != nil) {
                endYear = [values[@"endYear"] integerValue];
            }
            if (values[@"bankCount"] != nil) {
                bankCount = [values[@"bankCount"] integerValue];
            }
            if (values[@"maxAccounts"] != nil) {
                maxAccountsPerBank = [values[@"maxAccounts"] integerValue];
            }
            if (values[@"transactionCount"] != nil) {
                numberOfStatementsPerBank = [values[@"transactionCount"] integerValue];
            }
        }
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.progressIndicator.doubleValue = 0;
    [self updateTotalCount];
}

- (void)updateTotalCount {
    NSUInteger totalCountMin = 0;
    NSUInteger totalCountMax = 0;
    if (endYear >= startYear) {
        totalCountMin = (endYear - startYear + 1) * numberOfStatementsPerBank * bankCount;
        totalCountMax = (endYear - startYear + 1) * numberOfStatementsPerBank * bankCount * maxAccountsPerBank;
    }
    self.totalCountLabel.stringValue = [NSString stringWithFormat: @"%lu - %lu", totalCountMin, totalCountMax];
}

- (void)objectDidEndEditing: (id)editor {
    [self updateTotalCount];
}

- (IBAction)stepperChanged: (id)sender {
    [self updateTotalCount];
}

- (IBAction)selectFile: (id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: NO];
    [panel setAllowedFileTypes: @[@"txt"]];
    NSInteger result = [panel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        [self.path setStringValue: panel.URL.path];
    }
}

- (IBAction)close: (id)sender {
    [NSApp stopModal];
}

- (NSDate *)firstDayOfYear: (NSUInteger)year {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = 1;
    components.day = 1;
    return [calendar dateFromComponents: components];
}

- (NSDate *)firstDayOfQuarter: (NSUInteger)quarter inYear: (NSUInteger)year {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = 1 + 3 * (quarter - 1);
    components.day = 1;
    return [calendar dateFromComponents: components];
}

- (NSString *)createDTAPurposeFromPurpose: (NSString *)purpose
                            statementDate: (NSDate *)date
                                     info: (NSArray *)sepaInfo
                             purposeCodes: (NSArray *)purposeCodes
                            sequenceTypes: (NSArray *)sequenceTypes {
    NSMutableString *result = [NSMutableString new];

    // In 1 out of 5 cases add a line without a SEPA prefix first.
    if (arc4random_uniform(5) == 0) {
        [result appendString: NSLocalizedString(@"AP406", nil)];
        [result appendString: @":\n"];
    }

    // Shuffle the info array and pick the first n values, where n itself is a random number.
    // Using http://en.wikipedia.org/wiki/Fisher-Yates_shuffle .
    NSMutableArray *shuffledInfo = [sepaInfo mutableCopy];
    for (NSUInteger i = sepaInfo.count - 1; i > 0; --i) {
        [shuffledInfo exchangeObjectAtIndex: i
                          withObjectAtIndex: arc4random_uniform(i + 1)];
    }

    // We always add an SVWZ entry.
    [result appendString: @"SVWZ+"];
    [result appendString: purpose];
    [result appendString: @"\n"];

    NSInteger numberOfRecords = arc4random_uniform(shuffledInfo.count) + 1;
    for (NSInteger i = 0; i < numberOfRecords; ++i) {
        NSArray *parts = [shuffledInfo[i] componentsSeparatedByString: @"+"];
        if ([parts[0] isEqualToString: @"SVWZ"]) {
            continue;
        }

        if ([parts[0] isEqualToString: @"PURP"]) {
            [result appendString: @"PURP:"];
            [result appendString: purposeCodes[arc4random_uniform(purposeCodes.count)]];
            [result appendString: @"\n"];
            continue;
        }

        if ([parts[0] isEqualToString: @"SQTP"]) {
            [result appendString: @"SQTP:"];
            [result appendString: sequenceTypes[arc4random_uniform(sequenceTypes.count)]];
            [result appendString: @"\n"];
            continue;
        }

        if ([parts[0] isEqualToString: @"MDAT"]) {
            // Mandate date specifies the date from which on the mandate is valid.
            // Pick something before the given date.
            [result appendString: @"MDAT+"];
            ShortDate *mDate = [ShortDate dateWithDate: date];
            mDate = [mDate dateByAddingUnits: -3 byUnit: NSCalendarUnitMonth];
            [result appendString: mDate.isoDate];
            [result appendString: @"\n"];
            continue;
        }

        if ([parts[0] isEqualToString: @"DDAT"]) {
            // No idea yet what this is for. So ignore it for now.
            continue;
        }

        [result appendString: shuffledInfo[i]];
        [result appendString: @"\n"];
}

    return result;
}

- (void)addTransactions: (NSArray *)notes
             principals: (NSMutableArray *)principals
             categories: (NSSet *)categories
                   info: (NSArray *)sepaInfo
           purposeCodes: (NSArray *)purposeCodes
          sequenceTypes: (NSArray *)sequenceTypes {
    // Add transactions to each account of a bank.
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    Category               *root = Category.bankRoot;
    for (BankAccount *bank in root.children) {
        NSArray *accounts = [bank.children allObjects];
        for (NSUInteger year = startYear; year <= endYear; year++) {
            NSUInteger yearlyLimit = numberOfStatementsPerBank;

            // Reset all counters and start over.
            for (NSMutableDictionary *dictionary in principals) {
                int count = [dictionary[@"count"] intValue];
                dictionary[@"remaining"] = @(count);
            }
            while (yearlyLimit > 0) {
                // Walk the principals list repeatedly until we added the required amount of statements
                // or no principal has a count > 0 anymore.
                BOOL foundEntry = NO;
                for (NSMutableDictionary *dictionary in principals) {
                    int remaining = [dictionary[@"remaining"] intValue];
                    if (remaining == 0) {
                        continue;
                    } else {
                        dictionary[@"remaining"] = @(remaining - 1);
                        foundEntry = YES;
                    }

                    // Randomly pick one of the accounts in this bank. Prefer the first one as most important.
                    // It gets most of the transactions.
                    NSInteger randomIndex = (NSInteger)arc4random_uniform([bank.children count] + 6) - 6;
                    if (randomIndex < 0) {
                        randomIndex = 0;
                    }
                    BankAccount *account = accounts[randomIndex];

                    double    minBound = [dictionary[@"minBound"] doubleValue];
                    NSInteger delta = [dictionary[@"delta"] integerValue];
                    NSString  *unit = dictionary[@"unit"];

                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    [components setYear: year];

                    NSUInteger dateUnitMax = 1;
                    switch ([unit characterAtIndex: 0]) {
                        case 'y':
                            break;

                        case 'q':
                            dateUnitMax = 4;
                            break;

                        case 'm':
                            dateUnitMax = 12;
                            break;

                        case 'w':
                            dateUnitMax = 52;
                            break;

                        case 'd':
                            dateUnitMax = 365;
                            break;
                    }

                    for (NSUInteger dateOffset = 0; dateOffset < dateUnitMax; dateOffset++) {
                        NSUInteger      randomPart = arc4random_uniform(delta);
                        NSDecimalNumber *value = [NSDecimalNumber decimalNumberWithDecimal: [@((minBound + randomPart) / 100.0)decimalValue]];

                        NSDate *date;
                        switch ([unit characterAtIndex: 0]) {
                            case 'y': {
                                NSDate           *firstDayOfYear = [self firstDayOfYear: year];
                                NSDate           *firstDayOfNextYear = [self firstDayOfYear: year + 1];
                                NSDateComponents *temp = [calendar components: NSCalendarUnitDay
                                                                     fromDate: firstDayOfYear
                                                                       toDate: firstDayOfNextYear
                                                                      options: 0];
                                [components setDay: 1 + arc4random_uniform(temp.day)];
                                date = [calendar dateFromComponents: components];
                                break;
                            }

                            case 'q': {
                                NSDate *firstDayOfYear = [self firstDayOfYear: year];
                                NSDate *firstDayOfQuarter = [self firstDayOfQuarter: dateOffset + 1
                                                                             inYear: year];
                                NSDateComponents *tempBase = [calendar components: NSCalendarUnitDay
                                                                         fromDate: firstDayOfYear
                                                                           toDate: firstDayOfQuarter
                                                                          options: 0];
                                NSDate *firstDayOfNextQuarter = [self firstDayOfQuarter: dateOffset + 2
                                                                                 inYear: year];
                                NSDateComponents *temp = [calendar components: NSCalendarUnitDay
                                                                     fromDate: firstDayOfQuarter
                                                                       toDate: firstDayOfNextQuarter
                                                                      options: 0];
                                [components setDay: tempBase.day + 1 + arc4random_uniform(temp.day)];
                                date = [calendar dateFromComponents: components];
                                break;
                            }

                            case 'm': {
                                [components setMonth: dateOffset + 1];
                                NSRange r = [calendar rangeOfUnit: NSCalendarUnitDay
                                                           inUnit: NSCalendarUnitMonth
                                                          forDate: [calendar dateFromComponents: components]];
                                [components setDay: 1 + arc4random_uniform(r.length)];
                                date = [calendar dateFromComponents: components];
                                break;
                            }

                            case 'w':
                                [components setDay: 7 * dateOffset + 1 + arc4random_uniform(7)];
                                date = [calendar dateFromComponents: components];
                                break;

                            case 'd':
                                [components setDay: dateOffset];
                                date = [calendar dateFromComponents: components];
                                break;
                        }

                        BankStatement *statement = [NSEntityDescription insertNewObjectForEntityForName: @"BankStatement"
                                                                                 inManagedObjectContext: context];
                        statement.currency = account.currency;
                        statement.localAccount = account.accountNumber;
                        statement.localBankCode = account.bankCode;
                        statement.date = date;
                        statement.valutaDate = date;
                        statement.remoteCountry = @"de";
                        statement.value = value;

                        NSString *purpose = dictionary[@"purpose"];
                        purpose = [purpose stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
                        if (arc4random_uniform(5) < 2) { // 2 out of 5 use the plain purpose. The others use a MTA94x style purpose.
                            statement.purpose = purpose;
                        } else {
                            statement.purpose = [self createDTAPurposeFromPurpose: purpose
                                                                    statementDate: date
                                                                             info: sepaInfo
                                                                     purposeCodes: purposeCodes
                                                                    sequenceTypes: sequenceTypes];
                        }
                        statement.transactionText = NSLocalizedString(@"AP407", nil);
                        statement.remoteName = dictionary[@"principal"];
                        NSString *remoteAccount = [NSString stringWithFormat: @"%u", arc4random()];
                        if (remoteAccount.length > 10) {
                            statement.remoteAccount = [remoteAccount substringWithRange: NSMakeRange(0, 10)];
                        } else {
                            statement.remoteAccount = remoteAccount;
                        }

                        // Random values for certain flags.
                        statement.isManual = arc4random_uniform(10) < 5 ? @NO : @YES;
                        statement.isPreliminary = arc4random_uniform(10) < 5 ? @NO : @YES;
                        statement.isStorno = arc4random_uniform(10) < 5 ? @NO : @YES;
                        statement.isSettled = arc4random_uniform(10) < 5 ? @NO : @YES;

                        [statement addToAccount: account];

                        NSUInteger noteIndex = arc4random_uniform(notes.count);
                        statement.bankAssignment.userInfo = notes[noteIndex];

                        NSArray *keywords = [dictionary[@"keywords"] componentsSeparatedByString: @","];
                        if (keywords.count > 0) {
                            // Assign this statement to all categories which contain any of the keywords.
                            NSSet *matchingCategories = [categories objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                for (NSString *keyword in keywords) {
                                    return [[(Category *)obj name] rangeOfString: keyword].length > 0;
                                }
                                return NO;
                            }];
                            for (Category *category in matchingCategories) {
                                [statement assignToCategory: category];
                            }
                        }
                        [self.progressIndicator incrementBy: 1];
                        yearlyLimit--;
                        if (yearlyLimit == 0) {
                            break;
                        }
                    }
                    if (yearlyLimit == 0) {
                        break;
                    }

                }
                if (!foundEntry) {
                    [self.progressIndicator incrementBy: yearlyLimit];
                    yearlyLimit = 0; // No principals left, so go to the next year.
                }
            }
        }
        for (BankAccount *account in accounts) {
            [account doMaintenance];
        }
    }
}

- (void)createUsersAndAccounts: (NSMutableArray *)banks accounts: (NSMutableArray *)accounts {
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    // Randomly change the order in the banks and accounts arrays
    // This avoids using a bank/account more than once.
    NSUInteger count = [banks count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger nElements = count - i;
        NSInteger n = (arc4random() % nElements) + i;
        [banks exchangeObjectAtIndex: i withObjectAtIndex: n];
    }
    count = [accounts count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger nElements = count - i;
        NSInteger n = (arc4random() % nElements) + i;
        [accounts exchangeObjectAtIndex: i withObjectAtIndex: n];
    }
    Category *root = Category.bankRoot;
    for (NSUInteger i = 0; i < bankCount; i++) {
        NSString *bank = banks[i % bankCount];

        BankUser *user = [NSEntityDescription insertNewObjectForEntityForName: @"BankUser"
                                                       inManagedObjectContext: context];
        user.name = bank;
        user.bankCode = [NSString stringWithFormat: @"%i", arc4random_uniform(99999999)];
        user.bankName = bank;
        user.bankURL = @"http://noip.com";
        user.port = @"1";
        user.hbciVersion = @"2.2";
        user.checkCert = @YES;
        user.country = @"DE";
        user.userId = @"0987654321";
        user.customerId = @"";
        user.secMethod = @(SecMethod_PinTan);

        // Add account for this bank (actually the bank root to which the real accounts are attached).
        BankAccount *bankRoot = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount"
                                                              inManagedObjectContext: context];
        bankRoot.bankName = bank;
        bankRoot.name = bank;
        bankRoot.bankCode = user.bankCode;
        bankRoot.currency = @"EUR";
        bankRoot.country = user.country;
        bankRoot.isBankAcc = @YES;
        bankRoot.parent = root;

        // To each bank root add a few accounts. The actual number depends on the data amount flag.
        NSMutableArray *accountList = [NSMutableArray array];
        NSUInteger     accountCount = 1 + arc4random_uniform(maxAccountsPerBank);
        for (NSUInteger index = 0; index < accountCount; ++index) {
            [accountList addObject: accounts[index]];
        }
        for (NSString *accountName in accountList) {
            BankAccount *newAccount = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount"
                                                                    inManagedObjectContext: context];
            newAccount.bankCode = user.bankCode;
            newAccount.bankName = user.bankName;
            newAccount.isManual = @YES;
            newAccount.userId = user.userId;
            newAccount.customerId = user.customerId;
            //newAccount.collTransferMethod = account.collTransferMethod;
            newAccount.isStandingOrderSupported = @YES;

            newAccount.parent = bankRoot;
            newAccount.isBankAcc = @YES;

            //newAccount.iban = account.iban;
            //newAccount.bic = account.bic;
            //newAccount.owner = account.owner;
            newAccount.accountNumber = [NSString stringWithFormat: @"%i", arc4random_uniform(19999999)];
            newAccount.name = accountName;
            newAccount.currency = bankRoot.currency;
            newAccount.country = bankRoot.country;

            // Current balance of the account. Saldos are computed backwards starting with this value.
            double   dBalance = ((double)arc4random_uniform(500000) - 250000) / 100.0;
            NSNumber *balance = @(dBalance);
            newAccount.balance = [NSDecimalNumber decimalNumberWithDecimal: balance.decimalValue];
        }
    }
}

- (void)addStandingOrders: (NSArray *)orders {
    NSManagedObjectContext *context = MOAssistant.assistant.context;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"dd.MM.yyyy";
    for (NSString *line in orders) {
        NSRange  range = [line rangeOfString: @"#"];
        NSString *entry = (range.length == 0) ? line : [line substringToIndex: range.location];

        NSArray *parts = [entry componentsSeparatedByString: @":"];
        if (parts.count < 10) {
            continue; // Ignore any entry which is not properly specified (or empty/commented lines).
        }

        // Fields are: remote name:remote bank name:IBAN:BIC:amount:purpose:period ([w]eekly, [m]onthly):
        //             cycle (months in year or days in week):executionDay (day in week or month):
        //             first exec day:last exec day (optional)
        StandingOrder *order = [NSEntityDescription insertNewObjectForEntityForName: @"StandingOrder"
                                                             inManagedObjectContext: context];

        order.remoteName = parts[0];
        order.remoteBankName = parts[1];
        order.remoteIBAN = parts[2];
        order.remoteBIC = parts[3];
        order.value = [NSDecimalNumber decimalNumberWithString: parts[4]];
        order.purpose1 = parts[5]; // Assuming demo data has a purpose string of acceptable length for one line.

        if ([parts[6] isEqualTo: @"w"]) {
            order.period = @(stord_weekly);
        } else {
            order.period = @(stord_monthly);
        }
        order.cycle = @([parts[7] intValue]);
        order.executionDay = @([parts[8] intValue]);
        order.firstExecDate = [formatter dateFromString: parts[9]];

        if (parts.count > 10) {
            order.lastExecDate = [formatter dateFromString: parts[10]];
        }
    }
}

- (IBAction)start: (id)sender {
    // First store all values used for generation for restore on next run.
    // This way we can start off were we left, quickly.
    NSDictionary *values = @{
        @"path": self.path.stringValue,
        @"startYear": @(startYear),
        @"endYear": @(endYear),
        @"bankCount": @(bankCount),
        @"maxAccounts": @(maxAccountsPerBank),
        @"transactionCount": @(numberOfStatementsPerBank)
    };

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: values forKey: @"generator-values"];

    NSError  *error;
    NSString *path = self.path.stringValue;
    NSString *s = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: &error];
    if (error) {
        LogError(@"Error reading demo data template file at %@\n%@", path, error.localizedFailureReason);
    } else {
        NSMutableDictionary *blocks = [NSMutableDictionary dictionary];
        NSString            *blockName = @"";
        NSMutableArray      *entries;

        NSArray *lines = [s componentsSeparatedByString: @"\n"];
        for (NSString *line in lines) {
            if (line.length == 0) {
                continue; // Empty line.
            }
            if ([line hasPrefix: @"#"]) {
                continue; // Comment line.
            }

            if ([line hasPrefix: @"["] && [line hasSuffix: @"]"]) {
                // Starting new block.
                if (entries != nil) {
                    blocks[blockName] = entries;
                }
                entries = [NSMutableArray array];
                blockName = [line substringWithRange: NSMakeRange(1, line.length - 2)];

                continue;
            }
            [entries addObject: line];
        }
        if (entries.count > 0) {
            blocks[blockName] = entries;
        }

        [self.progressIndicator setIndeterminate: YES];
        [self.progressIndicator startAnimation: self];

        NSManagedObjectContext *context = MOAssistant.assistant.context;

        // Before adding new data remove old data if requested.
        if (self.removeOldDataCheckBox.state == 1) {
            [MOAssistant.assistant clearAllData];
            [Category recreateRoots];
            [Category createDefaultCategories];
        }

        // Once all data is read start by generating bank users and accounts.
        // Banks must be mutable as we are going to randomize it.
        NSMutableArray *banks = [blocks[@"Banks"] mutableCopy];
        if (banks.count == 0) {
            return;
        }

        NSArray *principals = blocks[@"Principals"];
        if (principals.count == 0) {
            return;
        }

        NSArray *notes = blocks[@"Notes"];
        NSArray *sepaInfo = blocks[@"SEPA Info"];
        NSArray *sepaPurposeCodes = blocks[@"SEPA Purpose Code"];
        NSArray *sepaSequenceTypes = blocks[@"SEPA Sequence Type"];

        NSSet *categories = Category.catRoot.allCategories;

        // Mark the database as having demo data.
        LocalSettingsController.sharedSettings[DemoDataKey] = @YES;

        // Precompute details for principals.
        NSMutableArray *parsedPrincipals = [NSMutableArray arrayWithCapacity: principals.count];
        for (NSString *principal in principals) {
            NSArray *parts = [principal componentsSeparatedByString: @":"];
            if (parts.count < 4) {
                continue; // Ignore any entry which is not properly specified.
            }

            // Fields are: principal:lowest value:highest value:frequency ([1-9] [d]ay, [w]eek], [m]onth,
            //   [q]uarter, [y]ear):category keywords:purpose
            NSString *principal = parts[0];
            double   lowBound = [parts[1] doubleValue];
            double   highBound = [parts[2] doubleValue];
            NSString *frequency = parts[3];
            NSString *keywords = @"";
            if (parts.count > 4) {
                keywords = parts[4]; // Optional
            }
            NSString *purpose = @"";
            if (parts.count > 5) {
                purpose = parts[5]; // Optional
            }
            if (principal.length == 0 || (lowBound == 0 && highBound == 0) || frequency.length < 2) {
                continue; // Ignore entries that are not properly specified.
            }
            NSString            *count = [frequency substringWithRange: NSMakeRange(0, frequency.length - 1)];
            NSString            *unit = [frequency substringFromIndex: frequency.length - 1];
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               parts[0], @"principal",
                                               @(lowBound * 100), @"minBound",
                                               @((NSInteger)(highBound - lowBound) * 100), @"delta",
                                               @([count intValue]), @"count",
                                               unit, @"unit",
                                               keywords, @"keywords",
                                               purpose, @"purpose",
                                               nil];
            [parsedPrincipals addObject: dictionary];
        }
        if (parsedPrincipals.count == 0) {
            return;
        }

        NSMutableArray *accounts = [blocks[@"Accounts"] mutableCopy];

        [self createUsersAndAccounts: banks accounts: accounts];
        [self.progressIndicator setIndeterminate: NO];
        self.progressIndicator.maxValue = (endYear - startYear + 1) * numberOfStatementsPerBank * banks.count * ceil(maxAccountsPerBank / 2);

        [self addTransactions: notes
                   principals: parsedPrincipals
                   categories: categories
                         info: sepaInfo
                 purposeCodes: sepaPurposeCodes
                sequenceTypes: sepaSequenceTypes];
        [Category.bankRoot updateCategorySums];

        [self addStandingOrders: blocks[@"Standing Orders"]];

        [self.progressIndicator stopAnimation: self];
        if (![context save: &error]) {
            [NSApp stopModal];

            NSAlert *alert = [NSAlert alertWithError: error];
            [alert runModal];
            return;
        }

        [SystemNotification showMessage: NSLocalizedString(@"AP501", nil)
                              withTitle: NSLocalizedString(@"AP500", nil)];
        [NSApp stopModal];
    }
}

@end
