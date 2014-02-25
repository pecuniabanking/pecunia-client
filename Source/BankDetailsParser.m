/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import "BankDetailsParser.h"
#import "LogController.h"

NSString *PBBankCodeKey = @"BankCodeKey";
NSString *PBBankCodeReliabilityKey = @"BankCodeReliabilityKey";
NSString *PBAccountNumberKey = @"AccountNumberKey";
NSString *PBAccountNumberReliabilityKey = @"AccountNumberReliabilityKey";
NSString *PBIBANKey = @"IBANKey";
NSString *PBIBANReliabilityKey = @"IBANReliabilityKey";
NSString *PBBICKey = @"BICKey";
NSString *PBBICReliabilityKey = @"BICReliabilityKey";
NSString *PBReceiverKey = @"ReceiverKey";
NSString *PBReceiverReliabilityKey = @"ReceiverReliabilityKey";

@implementation NSString (BankDetailsParser)

// Charactersets for scanning account parts.
static NSMutableCharacterSet *ignoreSet;     // Anything not alpha numeric.
static NSMutableCharacterSet *numberSet;     // Anything we can accept for an account number.
static NSCharacterSet *digitSet;             // Decimal digits only.
static NSCharacterSet *nonDigitSet;          // All but decimal digits.
static NSMutableCharacterSet *lineBreaksSet; // Line breaks only.

/**
 * Returns a number of NSRange instances containing text that follows certain keywords.
 */
- (NSMutableArray *)collectEntriesForKeywords: (NSArray *)keywords scanToLineBreak: (BOOL)flag
{
    NSMutableArray *result = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString: self];
    scanner.caseSensitive = NO;
    scanner.locale = [NSLocale currentLocale];
    scanner.charactersToBeSkipped = ignoreSet;

    // Collect all occurences of each keyword. Keep a list of found keyword locations to avoid catching the same
    // location twice (some keywords can be part of other keywords).
    NSMutableArray *foundLocations = [NSMutableArray array];
    for (NSString *keyword in keywords) {
        scanner.scanLocation = 0;
        while (!scanner.isAtEnd) {
            [scanner scanUpToString: keyword intoString: nil];

            // Keep the current location in case we have found the keyword.
            NSUInteger location = scanner.scanLocation;

            // Try to skip the keyword. Will fail if the keyword wasn't there actually (i.e. scanUpToString reached the end).
            if (![scanner scanString: keyword intoString: nil]) {
                break; // No more occurences.
            }

            // Due to some entries possibley being subparts of other keywords we might already have found this entry.
            // In that case we ignore the currently found location.
            // For this to work more specialized keywords must appear before more general ones.
            if ([foundLocations indexOfObjectPassingTest: ^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                NSRange range = [obj rangeValue];
                return (location >= range.location) && (location <= range.location + range.length);
            }] == NSNotFound) {

                // Store the range of the full keyword. No other keyword may fall into that range to be valid.
                [foundLocations addObject: [NSValue valueWithRange: NSMakeRange(location, scanner.scanLocation - location)]];

                // Skip the keyword and get the range of the possible value.
                NSRange currentRange = NSMakeRange(scanner.scanLocation, 0);

                // For certain entries we always scan til the end of the line.
                if (flag) {
                    if ([scanner scanUpToCharactersFromSet: lineBreaksSet intoString: nil]) {
                        // Add the range only if we can get a valid value, otherwise simply ignore it.
                        currentRange.length = scanner.scanLocation - currentRange.location;
                        [result addObject: [NSValue valueWithRange: currentRange]];
                    }
                } else {
                    if ([scanner scanCharactersFromSet: numberSet intoString: nil]) {
                        // Add the range only if we can get a valid value, otherwise simply ignore it.
                        currentRange.length = scanner.scanLocation - currentRange.location;
                        [result addObject: [NSValue valueWithRange: currentRange]];
                    }
                }
            }
        }
    }

    // No sort necessary here as we do that later for all entries in one go.
    return result;
}

typedef enum {
    DigitCheckNone,
    DigitCheckStart,
    DigitCheckAll
} DigitCheck;

/**
 * Helper to extract a value from the receiver and make it up.
 */
- (NSString *)cleanUpValueFromRange: (NSRange)range digitCheck: (DigitCheck)check removeInnerWhitespaces: (BOOL)removeInner
{
    // Remove whitespaces before adding the new number.
    NSString *value = [self substringWithRange: range];
    if (removeInner) {
        value = [value stringByReplacingOccurrencesOfString: @" " withString: @""];
        value = [value stringByReplacingOccurrencesOfString: @"\t" withString: @""];
        value = [value stringByReplacingOccurrencesOfString: @"\n" withString: @""];
    }
    value = [value stringByTrimmingCharactersInSet: ignoreSet];

    // Some validity checks.
    switch (check) {
        case DigitCheckStart: // Start with a digit.
            if (![digitSet characterIsMember: [value characterAtIndex: 0]]) {
                return @"";
            }
            break;

        case DigitCheckAll: { // Must be all digits.
            NSRange range = [value rangeOfCharacterFromSet: nonDigitSet];
            if (range.location != NSNotFound) { // At least one non-digit found.
                return @"";
            }
            break;
        }

        default:
            break;
    }

    return value;
}

/**
 * Examines the text of the receiver to find as many interesting bank details as possible.
 */
- (NSArray *)parseBankDetails
{
    LogEnter;

    if (ignoreSet == nil) {
        ignoreSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [ignoreSet invert];

        numberSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [numberSet addCharactersInString: @" \t.-"];

        digitSet = [NSCharacterSet decimalDigitCharacterSet];
        nonDigitSet = [digitSet invertedSet];

        lineBreaksSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [lineBreaksSet formIntersectionWithCharacterSet: [[NSCharacterSet whitespaceCharacterSet] invertedSet]];

    }

    static NSArray *keyArray;
    if (keyArray == nil) {
        keyArray  = @[PBBankCodeKey, PBBankCodeReliabilityKey, PBAccountNumberKey, PBAccountNumberReliabilityKey,
                      PBIBANKey, PBIBANReliabilityKey, PBBICKey, PBBICReliabilityKey, PBReceiverKey, PBReceiverReliabilityKey];
    }

    // For now we only consider german keywords to search for. Scanning is case-insensitive.
    // Order in all arrays is important!
    NSMutableArray *result = [NSMutableArray array];

    static NSArray *receiverKeywords;
    if (receiverKeywords == nil) {
        receiverKeywords = @[@"Empfänger", @"Begünstigter"];
    }

    NSMutableArray *receiverRanges = [self collectEntriesForKeywords: receiverKeywords scanToLineBreak: YES];

    static NSArray *accountNumberKeywords;
    if (accountNumberKeywords == nil) {
        accountNumberKeywords = @[@"Kontonummer", @"Konto-Nr.:", @"Konto-Nr:", @"Konto-Nr", @"Konto",
                                  @"Kto-Nr.:", @"Kto-Nr",
                                  @"Kto.nr.:", @"Kto.nr", @"Kto.:", @"Kto"];
    }

    NSMutableArray *accountNumberRanges = [self collectEntriesForKeywords: accountNumberKeywords scanToLineBreak: NO];
    
    static NSArray *bankCodeKeywords;
    if (bankCodeKeywords == nil) {
        bankCodeKeywords = @[@"Bankleitzahl (BLZ)", @"Bankleitzahl", @"BLZ.:", @"BLZ"];
    }

    NSMutableArray *bankCodeRanges = [self collectEntriesForKeywords: bankCodeKeywords scanToLineBreak: NO];
    
    static NSArray *ibanKeywords;
    if (ibanKeywords == nil) {
        // We could just use "IBAN", but that seems too generious to me.
        ibanKeywords = @[@"IBAN:", @"IBAN ", @"IBAN\t", @"IBAN\n"];
    }

    NSMutableArray *ibanRanges = [self collectEntriesForKeywords: ibanKeywords scanToLineBreak: NO];

    static NSArray *bicKeywords;
    if (bicKeywords == nil) {
        bicKeywords = @[@"BIC) SWIFTCODE:", @"BIC (Swift-Code)", @"BIC (SWIFT)", @"BIC/SWIFT-Code", @"BIC/SWIFTCODE",
                        @"BIC:", @"BIC ", @"BIC\t", @"SWIFT"];
    }

    NSMutableArray *bicRanges = [self collectEntriesForKeywords: bicKeywords scanToLineBreak: NO];

    // Collect all found entries in the correct order and coalesc entries that probably
    // belong together into a single result entry.
    NSMutableArray *list = [NSMutableArray array];
    for (NSValue *value in receiverRanges) {
        // We need to store the type of the value in that range. We could use an own pair class here but for this
        // temporary process it would be overkill. A simple dictionary does the job as well.
        [list addObject: @{PBReceiverKey: value}];
    }

    for (NSValue *value in accountNumberRanges) {
        [list addObject: @{PBAccountNumberKey: value}];
    }

    for (NSValue *value in bankCodeRanges) {
        [list addObject: @{PBBankCodeKey: value}];
    }

    for (NSValue *value in ibanRanges) {
        [list addObject: @{PBIBANKey: value}];
    }

    for (NSValue *value in bicRanges) {
        [list addObject: @{PBBICKey: value}];
    }

    // Sort the ranges by increasing location.
    [list sortUsingComparator: ^NSComparisonResult(id value1, id value2) {
        NSRange range1 = [[value1 allValues][0] rangeValue]; // We only have a single entry in the dict.
        NSRange range2 = [[value2 allValues][0] rangeValue];

        NSComparisonResult result = (range1.location < range2.location) ? NSOrderedAscending : ((range1.location > range2.location) ? NSOrderedDescending : NSOrderedSame);
        return result;
    }];

    NSMutableDictionary *bankEntry = [NSMutableDictionary dictionary];
    for (NSDictionary *entry in list) {
        if (bankEntry[entry.allKeys[0]] != nil) {
            // We have already an entry with that type. This means as far as we are concerned our current bank entry
            // can't get more additional values, so we close it and start over with a new one.
            // Check that we did not only scan a wrong receiver entry, however.
            if (bankEntry.allKeys.count > 1 || bankEntry[PBReceiverKey] == nil) {
                [result addObject: bankEntry];
            }
            bankEntry = [NSMutableDictionary dictionary];
        }

        switch ([keyArray indexOfObject: entry.allKeys[0]]) {
            case 0: { // PBBankCodeKey
                NSString *value = [self cleanUpValueFromRange: [entry.allValues[0] rangeValue]
                                                   digitCheck: DigitCheckStart
                                       removeInnerWhitespaces: YES];
                if (value.length > 0) {
                    bankEntry[PBBankCodeKey] = value;
                    bankEntry[PBBankCodeReliabilityKey] = @(PBReliabilityPerfect);
                }
                break;
            }

            case 2: { // PBAccountNumberKey;
                NSString *value = [self cleanUpValueFromRange: [entry.allValues[0] rangeValue]
                                                   digitCheck: DigitCheckAll
                                       removeInnerWhitespaces: YES];
                if (value.length > 0) {
                    bankEntry[PBAccountNumberKey] = value;
                    bankEntry[PBAccountNumberReliabilityKey] = @(PBReliabilityPerfect);
                }
                break;
            }

            case 4: { // PBIBANKey;
                NSString *value = [self cleanUpValueFromRange: [entry.allValues[0] rangeValue]
                                                   digitCheck: DigitCheckNone
                                       removeInnerWhitespaces: YES];
                if (value.length > 0) {
                    bankEntry[PBIBANKey] = value;
                    bankEntry[PBIBANReliabilityKey] = @(PBReliabilityPerfect);
                }
                break;
            }

            case 6: { // PBBICKey;
                NSString *value = [self cleanUpValueFromRange: [entry.allValues[0] rangeValue]
                                                   digitCheck: DigitCheckNone
                                       removeInnerWhitespaces: YES];
                if (value.length > 0) {
                    bankEntry[PBBICKey] = value;
                    bankEntry[PBBICReliabilityKey] = @(PBReliabilityPerfect);
                }
                break;
            }

            case 8: { // PBReceiverKey;
                NSString *value = [self cleanUpValueFromRange: [entry.allValues[0] rangeValue]
                                                   digitCheck: DigitCheckNone
                                       removeInnerWhitespaces: NO];
                if (value.length > 0) {
                    bankEntry[PBReceiverKey] = value;
                    bankEntry[PBReceiverReliabilityKey] = @(PBReliabilityPerfect);
                }
                break;
            }
        }
    };

    if (bankEntry.allKeys.count > 0 &&
        (bankEntry.allKeys.count > 2 || bankEntry[PBReceiverKey] == nil)) {
        [result addObject: bankEntry];
    }

    LogLeave;

    return result;
}

@end
