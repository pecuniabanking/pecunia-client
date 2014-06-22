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
            NSArray *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @"+"];
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
            NSArray *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @"+"];
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
            NSArray *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @"+"];
            if (parts.count == 3) {
                types[parts[0]] = @{@"description": parts[1], @"image": parts[2]};
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
        for (int i = 1499; i < 1502; ++i) {
            NSString *key = [NSString stringWithFormat: @"AP%i", i];
            NSArray *parts = [NSLocalizedString(key, nil) componentsSeparatedByString: @":"];
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
        sepaRegex = [NSRegularExpression regularExpressionWithPattern: @"[A-Z]{3,4}(\\+|:)" options: 0 error: &error];
        if (error != nil) {
            LogError(@"Error while compiling RE for SEPA data: %@", error.debugDescription);
        }
    }

    NSDictionary *mappings = [self prefixMap];
    NSMutableDictionary *result = [NSMutableDictionary new];

    NSArray *lines = [text componentsSeparatedByCharactersInSet: NSCharacterSet.newlineCharacterSet];
    NSString *lastKey;
    NSMutableString *purpose = [NSMutableString new];

    for (NSString *line in lines) {
        if (line.length == 0) {
            continue;
        }

        // Each prefix must start on its own line in the first position. At least that's the theory. Some banks have
        // their own interpretation, so we have to cater for that.
        NSArray *matches = [sepaRegex matchesInString: line options: 0 range: NSMakeRange(0, line.length)];
        if (matches.count == 0 || [matches[0] range].location > 0) {
            // A line without (known) prefix or some remaining text before the first prefix.
            // Either this is the continuation of the previous line
            // or something else we add to the purpose string.
            NSString *remainder = (matches.count == 0) ? line : [line substringWithRange: NSMakeRange(0, [matches[0] range].location)];

            // Consider the (non-standard) DATUM prefix, but only if it starts at position 0.
            // We may have to add more such special prefixes as banks tend to introduce their own markup.
            if (lastKey == nil || [remainder hasPrefix: @"DATUM "]) {
                if ([remainder hasPrefix: @"DATUM "]) {
                    // Put the DATUM entry on an own line.
                    [purpose appendString: @"\n"];
                }
                [purpose appendString: remainder];
                [purpose appendString: @"\n"];
                lastKey = nil; // DATUM prefix closes the last prefix if there was any.
            } else {
                if ([lastKey isEqualToString: @"SVWZ"]) { // Line continuation for the purpose entry.
                    [purpose appendString: remainder];
                } else {
                    result[lastKey] = [[result[lastKey] stringByAppendingString: remainder] stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceCharacterSet];
                }
            }
            if (matches.count == 0) {
                continue;
            }
        }

        for (NSUInteger i = 0; i < matches.count; ++i) {
            NSTextCheckingResult *match = matches[i];

            // Anything before the first match has been handled already.
            NSString *content;
            NSString *keyPart = [line substringWithRange: NSMakeRange(match.range.location, match.range.length - 1)];

            // Get the remaining part (between this and the next match or the line end).
            // Sometimes there are whitespaces between the prefix and the content. Remove them too.
            if (i + 1 >= matches.count) { // Last match?
                content = [line substringFromIndex: match.range.location + match.range.length];
            } else {
                NSUInteger start = match.range.location + match.range.length; // Position after the prefix + separator.
                NSTextCheckingResult *next = matches[i + 1];
                content = [line substringWithRange: NSMakeRange(start, next.range.location - start)];
            }

            content = [content stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceCharacterSet];

            if (mappings[keyPart] == nil) {
                LogWarning(@"SEPA tag %@ is not supported", keyPart);

                // Keep any unknown prefix as part of the purpose string for now.
                [purpose appendString: content];
                [purpose appendString: @"\n"];
                continue;
            }

            // Some special handling required here.
            if ([keyPart isEqualToString: @"EREF"] && [content isEqualToString: @"NOTPROVIDED"]) {
                lastKey = nil;
                continue; // Ignore this entry.
            } else {
                if ([keyPart isEqualToString: @"KREF"] && [content isEqualToString: @"NONREF"]) {
                    lastKey = nil;
                    continue;
                } else {
                    lastKey = keyPart;
                    
                    if ([lastKey isEqualToString: @"SVWZ"]) {
                        // Collect the purpose text anything before the first prefix into
                        // the overall purpose.
                        [purpose appendString: content];
                        continue;
                    }
                    result[lastKey] = content;
                }
            }
        }
    }

    result[@"SVWZ"] = purpose;
    return result;
}

@end
