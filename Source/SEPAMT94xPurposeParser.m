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

#import "SEPAMT94xPurposeParser.h"
#import "MessageLog.h"

#define SEPA_PREFIX_RE @"((I\n?B\n?A\n?N|" \
    "B\n?I\n?C|" \
    "E\n?R\n?E\n?F|" \
    "S\n?V\n?W\n?Z|" \
    "A\n?B\n?W\n?A|" \
    "A\n?B\n?W\n?E|" \
    "P\n?U\n?R\n?P|" \
    "M\n?R\n?E\n?F|" \
    "C\n?R\n?E\n?D|" \
    "M\n?D\n?A\n?T|" \
    "S\n?Q\n?T\n?P|" \
    "O\n?R\n?C\n?R|" \
    "O\n?R\n?M\n?R|" \
    "D\n?D\n?A\n?T|" \
    "D\n?E\n?B\n?T|" \
    "K\n?R\n?E\n?F|" \
    "C\n?O\n?A\n?M|" \
    "O\n?A\n?M\n?T)" \
    "(\\+|:))" \
    /* Special cases below (non-SEPA) */ \
    "|[Dd][Aa][Tt][Uu][Mm][ :]"

@implementation SEPAMT94xPurposeParser

/**
 * Returns a dictionary of SEPA prefixes and their localized descriptions.
 */
+ (NSDictionary *)prefixMap {
    NSAssert([NSLocalizedString(@"AP1300", nil) hasPrefix: @"IBAN+"], @"Prefix mapping localizations have unexpectedly been changed.");

    static NSMutableDictionary *prefixes;
    if (prefixes == nil) {
        prefixes = [NSMutableDictionary new];
        for (int i = 1300; i < 1318; ++i) {
            NSString *key = [NSString stringWithFormat: @"AP%i", i];
            NSArray  *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @"+"];
            if (parts.count == 2) {
                prefixes[parts[0]] = parts[1];
            }
        }
    }
    return prefixes;
}

/**
 * Returns a dictionary of SEPA purpose codes and their localized descriptions.
 */
+ (NSDictionary *)purposeCodeMap {
    NSAssert([NSLocalizedString(@"AP1330", nil) hasPrefix: @"BENE+"], @"Purpose code mapping localizations have unexpectedly been changed.");

    static NSMutableDictionary *codes;
    if (codes == nil) {
        codes = [NSMutableDictionary new];
        for (int i = 1330; i < 1471; ++i) {
            NSString *key = [NSString stringWithFormat: @"AP%i", i];
            NSArray  *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @"+"];
            if (parts.count == 2) {
                codes[parts[0]] = parts[1];
            }
        }
    }
    return codes;
}

/**
 * Returns a dictionary of SEPA sequence type codes and their localized descriptions + image names for the UI.
 * Each entry consists of a dictionary with 2 values: image + description
 */
+ (NSDictionary *)sequenceTypeMap {
    NSAssert([NSLocalizedString(@"AP1300", nil) hasPrefix: @"IBAN+"], @"Prefix mapping localizations have unexpectedly been changed.");

    static NSMutableDictionary *types;
    if (types == nil) {
        types = [NSMutableDictionary new];
        for (int i = 1495; i < 1499; ++i) {
            NSString *key = [NSString stringWithFormat: @"AP%i", i];
            NSArray  *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @"+"];
            if (parts.count == 3) {
                types[parts[0]] = @{
                    @"description": parts[1], @"image": parts[2]
                };
            }
        }
    }
    return types;
}

/**
 * Tries to find a sequence type code from the given text, using some heuristics.
 */
+ (NSString *)sequenceTypeFromString: (NSString *)text {
    if (text == nil) {
        return nil;
    }

    static NSMutableDictionary *typeVariants;
    if (typeVariants == nil) {
        typeVariants = [NSMutableDictionary new];
        for (int i = 1499; i < 1500; ++i) {
            NSString *key = [NSString stringWithFormat: @"AP%i", i];
            NSArray  *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @":"];
            if (parts.count == 2) {
                typeVariants[parts[0]] = parts[1];
            }
        }
    }

    NSString *lowerCaseText = text.lowercaseString;
    for (NSString *key in typeVariants.allKeys) {
        if ([lowerCaseText rangeOfString: key].length > 0) {
            return typeVariants[key];
        }
    }
    return nil;
}

/**
 * Treats the given text as purpose provided by an MT94x result and extracts associated SEPA informations.
 * The returned dictionary contains an entry for each found SEPA prefix. The prefix is used as key.
 *
 * If there's no SEPA prefix in the text it is returned as SVWZ entry in the result. Otherwise the text is split
 * depending on the prefixes (line continuation takes place). Text before the first prefix and that in an SWVZ entry
 * is concatenated to form the final SWVZ text. Some other special handling might be applied to that.
 */
+ (NSDictionary *)parse: (NSString *)text {
    if (text.length == 0) {
        return nil;
    }

    static NSRegularExpression *sepaRegex;
    if (sepaRegex == nil) {
        NSError *error;
        sepaRegex = [NSRegularExpression regularExpressionWithPattern: SEPA_PREFIX_RE options: 0 error: &error];
        if (error != nil) {
            LogError(@"Fehler beim Parsen der SEPA-Daten: %@", error.debugDescription);
        }
    }

    NSMutableDictionary *result = [NSMutableDictionary new];

    NSString        *lastKey;
    NSMutableString *purpose = [NSMutableString new];

    // Each prefix must start on its own line in the first position. At least that's the specification.
    // Some banks have their own interpretation (including splitting prefixes over 2 lines), so we have to cater for that.
    NSArray *matches = [sepaRegex matchesInString: text options: 0 range: NSMakeRange(0, text.length)];
    if (matches.count == 0 || [(NSTextCheckingResult *)matches[0] range].location > 0) {
        // No (known) prefix or some text before the first prefix.
        // Add everything (up to the first match) to SVWZ (unchanged).
        [purpose appendString: (matches.count == 0) ? text : [text substringWithRange:
          NSMakeRange(0, [(NSTextCheckingResult *)matches[0] range].location)]];
    }

    for (NSUInteger i = 0; i < matches.count; ++i) {
        NSTextCheckingResult *match = matches[i];

        // Anything before the first match has been handled already.
        NSString *content;
        NSString *keyPart = [text substringWithRange: NSMakeRange(match.range.location, match.range.length - 1)];
        keyPart = [keyPart stringByReplacingOccurrencesOfString: @"\n" withString: @""];

        // Get the remaining part (between this and the next match or the text end).
        if (i + 1 >= matches.count) { // Last match?
            content = [text substringFromIndex: match.range.location + match.range.length];
        } else {
            NSUInteger           start = match.range.location + match.range.length; // Position after the prefix + separator.
            NSTextCheckingResult *next = matches[i + 1];
            content = [text substringWithRange: NSMakeRange(start, next.range.location - start)];
        }

        content = [content stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceCharacterSet];

        // No need to check the key part. There can be only known prefixes if we have matched something.

        // Remove embedded line breaks, but only for known prefixes.
        if ([keyPart.lowercaseString hasPrefix: @"datum"]) { // TODO: needs localization (RE as well as this check and the addition below).
            if (purpose.length > 0) {
                [purpose appendString: @"\n"];
            }
            [purpose appendString: @"Datum: "];
            [purpose appendString: content];

            continue;
        }

        content = [content stringByReplacingOccurrencesOfString: @"\n" withString: @""];
        
        // Some special handling required here.
        if ([keyPart isEqualToString: @"EREF"] && [content isEqualToString: @"NOTPROVIDED"]) {
            continue; // Ignore this entry.
        }

        if ([keyPart isEqualToString: @"KREF"] && [content isEqualToString: @"NONREF"]) {
            continue;
        }

        lastKey = keyPart;

        if ([lastKey isEqualToString: @"SVWZ"]) {
            // Collect the purpose text and anything before the first prefix into
            // the overall purpose.
            if (purpose.length > 0) {
                [purpose appendString: @"\n"];
            }
            [purpose appendString: content];
            continue;
        }
        result[lastKey] = content;
    }

    result[@"SVWZ"] = purpose;
    return result;
}

@end
