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

@implementation SEPAMT94xPurposeParser

// Unfortunately, these values are defined as german strings.
#define REVERSE_TRANSFER_STRING @"RUECKUEBERWEISUNG:"
#define CHARGE_BACK_STRING @"RUECKLASTSCHRIFT:"

/**
 * Returns a set of SEPA prefixes and their localized descriptions.
 */
+ (NSDictionary *)prefixMappings {
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
 * Returns a set of SEPA purpose codes and their localized descriptions.
 */
+ (NSDictionary *)purposeCodeMappings {
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
 * Treats the given text as purpose provided by an MT94x result and extracts associated SEPA informations.
 * The returned dictionary contains an entry for each found SEPA prefix. The prefix is used as key.
 *
 * If there's no SEPA prefix in the text it is returned as SVWZ entry in the result. Otherwise the text is considered
 * consisting of only SEPA informations with prefix (line continuation takes place).
 * In addition to the manually specified purpose (or as alternative) a machine generated purpose is added
 * under its key PURP (if such a record is in the text at all). The purpose code is translated to a localized
 * description.
 */
+ (NSDictionary *)parse: (NSString *)text {
    NSDictionary *mappings = [self prefixMappings];
    NSMutableDictionary *result = [NSMutableDictionary new];

    // Each prefix must start on its own line in the first position.
    // Collect all unknown entries and the SVWZ entry into a common purpose string.
    NSArray *lines = [text componentsSeparatedByCharactersInSet: NSCharacterSet.newlineCharacterSet];
    NSString *lastKey;
    NSMutableString *purpose = [NSMutableString new];
    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByString: @"+"];

        if (parts.count == 2 && [parts[0] length] == 4) {
            if (mappings[parts[0]] != nil) {
                lastKey = parts[0];
                NSString *value = parts[1];

                // Some special handling required here.
                // Entry SQTP+ is currently unclear. Couldn't find an understandable description so far.
                if ([lastKey isEqualToString: @"EREF"] && [value isEqualToString: @"NOTPROVIDED"]) {
                    continue; // Ignore this entry.
                } else {
                    if ([lastKey isEqualToString: @"KREF"] && [value isEqualToString: @"NONREF"]) {
                        continue;
                    } else {
                        if ([lastKey isEqualToString: @"PURP"]) {
                            // Generated purpose key. We can convert that to a clear text message.
                            NSDictionary *purposeCodes = [self purposeCodeMappings];
                            if (purposeCodes[value] != nil) {
                                value = purposeCodes[value];
                            }
                        } else {
                            if ([lastKey isEqualToString: @"SVWZ"]) {
                                if ([value hasPrefix: REVERSE_TRANSFER_STRING]) {
                                    value = [value substringFromIndex: [REVERSE_TRANSFER_STRING length]];
                                } else {
                                    if ([value hasPrefix: CHARGE_BACK_STRING]) {
                                        value = [value substringFromIndex: [CHARGE_BACK_STRING length]];
                                    }
                                }
                                // Collect the purpose text and any unknown found before the first prefix into
                                // the overall purpose.
                                [purpose appendString: value];
                                continue;
                            }
                        }
                        result[lastKey] = value;
                    }
                }
            } else {
                // Looks like a prefix but is unknown. Handle this as line continuation then.
                if (lastKey == nil) {
                    [purpose appendString: line];
                } else {
                    result[lastKey] = [result[lastKey] stringByAppendingString: line];
                }
            }
        } else {
            // A line without (known) prefix. Either this is the continuation of the previous line
            // or something else we add to the purpose string.
            if (lastKey == nil) {
                if (purpose.length > 0) {
                    [purpose appendString: @"\n"];
                }
                [purpose appendString: line];
            } else {
                if ([lastKey isEqualToString: @"SVWZ"]) {
                    [purpose appendString: line];
                } else {
                    result[lastKey] = [result[lastKey] stringByAppendingString: line];
                }
            }
        }
    }

    result[@"SVWZ"] = purpose;
    return result;
}

@end
