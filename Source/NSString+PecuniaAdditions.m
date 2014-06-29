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

#import "NSString+PecuniaAdditions.h"
#import "Mathematics.h"
#import "MessageLog.h"

#import "ZipFile.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"

NSString *PecuniaWordsLoadedNotification = @"PecuniaWordsLoadedNotification";

@implementation NSString (PecuniaAdditions)

static NSMutableDictionary *words;
static BOOL wordsValid;

// Number of entries in one batch of a dispatch_apply invocation.
#define WORDS_LOAD_STRIDE 10000

+ (void)load {
    // Schedule time consuming load of word list to a background queue.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

    words = [NSMutableDictionary new];
    dispatch_async(queue, ^{
        LogDebug(@"Loading word list");
        uint64_t startTime = Mathematics.beginTimeMeasure;
        NSString *path = [NSBundle.mainBundle pathForResource: @"words" ofType: @"zip"];
        if (path != nil) {
            ZipFile *file = [[ZipFile alloc] initWithFileName: path mode: ZipFileModeUnzip];
            if (file != nil) {
                FileInZipInfo *info = file.getCurrentFileInZipInfo;
                if (info.length < 100000000) { // Sanity check. Not more than 100MB.
                    NSMutableData *buffer = [NSMutableData dataWithLength: info.length];
                    ZipReadStream *stream = file.readCurrentFileInZip;
                    NSUInteger length = [stream readDataWithBuffer: buffer];
                    if (length == info.length) {
                        NSString *text = [[NSString alloc] initWithData: buffer encoding: NSUTF8StringEncoding];
                        buffer = nil; // Free buffer to lower mem consuption.
                        NSArray *lines = [text componentsSeparatedByCharactersInSet: NSCharacterSet.newlineCharacterSet];
                        text = nil;

                        // Convert to lower case and decompose diacritics (e.g. umlauts).
                        // Split work into blocks of WORDS_LOAD_STRIDE size and iterate in parallel over them.
                        NSUInteger blockCount = lines.count / WORDS_LOAD_STRIDE;
                        if (lines.count % WORDS_LOAD_STRIDE != 0) {
                            ++blockCount; // One more (incomplete) block for the remainder.
                        }

                        // Keep an own dictionary for each block, so we don't get into concurrency issues.
                        NSMutableArray *dictionaries = [NSMutableArray new];
                        for (NSUInteger i = 0; i < blockCount; ++i) {
                            [dictionaries addObject: [NSMutableDictionary new]];
                        }
                        dispatch_apply(blockCount, queue,
                                       ^(size_t blockIndex)  {
                                           NSUInteger start = blockIndex * WORDS_LOAD_STRIDE;
                                           NSUInteger end = start + WORDS_LOAD_STRIDE;
                                           if (end > lines.count) {
                                               end = lines.count;
                                           }
                                           for (NSUInteger i = start; i < end; ++i) {
                                               NSString *key = [[lines[i] stringWithNormalizedGermanChars] lowercaseString];
                                               dictionaries[blockIndex][key] = lines[i];
                                           }
                                       }
                                       );

                        // Finally combine all dicts into one.
                        for (NSUInteger i = 0; i < blockCount; ++i) {
                            [words addEntriesFromDictionary: dictionaries[i]];
                        }
                    }

                    wordsValid = YES;
                    NSNotification *notification = [NSNotification notificationWithName: PecuniaWordsLoadedNotification
                                                                                 object: nil];
                    [NSNotificationCenter.defaultCenter postNotification: notification];
                }
            }
        }

        LogDebug(@"Word list loading done in: %.2fs", [Mathematics timeDifferenceSince: startTime] / 1000000000);
    });
}

/**
 * Returns a new string instance containing the given data as a string (assuming UTF8 encoding).
 * If the given data cannot be converted to an UTF8 string it is converted to a hex string.
 * Returns an empty string if data is nil or empty.
 */
+ (NSString *)stringWithData: (NSData *)data {
    if (data == nil) {
        return [NSString string];
    }

    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    if (result == nil) {
        const unsigned char *dataBuffer = (const unsigned char *)[data bytes];

        if (dataBuffer == nil) {
            return [NSString string];
        }

        NSMutableString *hexString  = [NSMutableString stringWithCapacity: 2 * data.length];
        for (NSUInteger i = 0; i < data.length; ++i) {
            [hexString appendString: [NSString stringWithFormat: @"%02x", dataBuffer[i]]];
        }
        result = [NSString stringWithString: hexString];
    }
    return result;
}

- (NSAttributedString *)attributedStringWithFont: (NSFont *)font {
    NSDictionary *attrs = @{
        NSFontAttributeName: font
    };
    NSAttributedString *result = [[NSAttributedString alloc] initWithString: self attributes: attrs];
    return result;
}

- (NSString *)stringByRemovingWhitespaces: (NSString *)s {
    if (s == nil) {
        return nil;
    }
    NSString *result = @"";
    NSArray  *components = [s componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *str in components) {
        result = [result stringByAppendingString: str];
    }
    return result;
}

/**
 * Parses the content of the receiver (which must be CSV data) into an array of arrays (rows with columns).
 * Correctly handles quoted fields and fields containing line breaks.
 */
- (NSArray *)csvRowsWithSeparator: (NSString *)separator {
    NSMutableArray *rows = [NSMutableArray array];

    NSMutableCharacterSet *newlineCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [newlineCharacterSet formIntersectionWithCharacterSet: [[NSCharacterSet whitespaceCharacterSet] invertedSet]];

    NSMutableCharacterSet *importantCharactersSet =
        [NSMutableCharacterSet characterSetWithCharactersInString: [NSString stringWithFormat: @"%@\"", separator]];
    [importantCharactersSet formUnionWithCharacterSet: newlineCharacterSet];

    // Construct a characterset for skipping whitespaces between fields, but exclude the separator
    // (which might be a whitespace too).
    NSMutableString *skipChars = [NSMutableString string];
    if ([separator rangeOfString: @" "].length == 0) {
        [skipChars appendString: @" "];
    }
    if ([separator rangeOfString: @"\t"].length == 0) {
        [skipChars appendString: @"\t"];
    }
    NSCharacterSet *skipCharacterSet = [NSCharacterSet characterSetWithCharactersInString: skipChars];

    NSScanner *scanner = [NSScanner scannerWithString: self];
    [scanner setCharactersToBeSkipped: nil];
    while (![scanner isAtEnd]) {
        BOOL insideQuotes = NO;
        BOOL finishedRow = NO;

        NSMutableArray  *columns = [NSMutableArray arrayWithCapacity: 10];
        NSMutableString *currentColumn = [NSMutableString string];
        while (!finishedRow) {
            NSString *tempString;
            if ([scanner scanUpToCharactersFromSet: importantCharactersSet intoString: &tempString]) {
                [currentColumn appendString: tempString];
            }

            if ([scanner isAtEnd]) {
                if (![currentColumn isEqualToString: @""]) {
                    [columns addObject: currentColumn];
                }
                finishedRow = YES;
            } else if ([scanner scanCharactersFromSet: newlineCharacterSet intoString: &tempString]) {
                if (insideQuotes) {
                    // Add line break to column text
                    [currentColumn appendString: tempString];
                } else {
                    // End of row
                    if (![currentColumn isEqualToString: @""]) {
                        [columns addObject: currentColumn];
                    }
                    finishedRow = YES;
                }
            } else if ([scanner scanString: @"\"" intoString: nil]) {
                if (insideQuotes && [scanner scanString: @"\"" intoString: nil]) {
                    // Replace double quotes with a single quote in the column string.
                    [currentColumn appendString: @"\""];
                } else {
                    // Start or end of a quoted string.
                    insideQuotes = !insideQuotes;
                }
            } else if ([scanner scanString: separator intoString: nil]) {
                if (insideQuotes) {
                    [currentColumn appendString: separator];
                } else {
                    // This is a column separating delimiter.
                    [columns addObject: currentColumn];
                    currentColumn = [NSMutableString string];

                    [scanner scanCharactersFromSet: skipCharacterSet intoString: nil];
                }
            }
        }
        if ([columns count] > 0) {
            [rows addObject: columns];
        }
    }

    return rows;
}

/**
 * Interprets the content as XML and inserts line breaks and whitespaces for better readability.
 */
- (NSString *)formatXML {
    NSError       *error;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString: self options: NSXMLNodePreserveAll error: &error];
    if (error != nil) {
        return self;
    }
    return [document XMLStringWithOptions: NSXMLNodePrettyPrint];
}

- (BOOL)hasSubstring: (NSString *)substring {
    if (substring != nil) {
        NSRange r = [self rangeOfString: substring];
        return r.location != NSNotFound;
    }
    return NO;
}

/**
 * Processes the content of the receiver and creates a new string with a more natural appearance, if possible.
 * This mostly involves truecasing words.
 */
- (NSString *)stringWithNaturalText {
    if (!wordsValid) {
        // While our word list is being loaded return a simple capitalized string.
        return [self capitalizedStringWithLocale: NSLocale.currentLocale];
    }

    NSMutableString *result = [NSMutableString new];
    [self enumerateLinguisticTagsInRange: NSMakeRange(0, self.length)
                                  scheme: NSLinguisticTagSchemeLexicalClass
                                 options: 0
                             orthography: nil
                            usingBlock: ^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
                                NSString *item = [self substringWithRange: tokenRange];
                                if (tag == NSLinguisticTagOtherWhitespace) {
                                    // Skip any leading whitespace.
                                    if (result.length > 0) {
                                        [result appendString: item];
                                    }
                                } else {
                                    // Not a whitespace. See if that is a known word.
                                    // TODO: needs localization.
                                    NSString *key = item.stringWithNormalizedGermanChars.lowercaseString;
                                    NSString *word = words[key];
                                    if (word != nil) {
                                        // If the original work contains lower case characters then it was probably
                                        // already in true case. We only use the lookup then for replacing diacritics/sharp-s.
                                        if ([item rangeOfCharacterFromSet: NSCharacterSet.lowercaseLetterCharacterSet].length > 0) {
                                            [result appendString: [item substringToIndex: 1]];
                                            [result appendString: [word substringFromIndex: 1]];
                                        } else {
                                            // Make the first letter upper case if it is the first entry.
                                            // Don't touch the other letters, though!
                                            if (result.length == 0) {
                                                [result appendString: [word substringToIndex: 1].capitalizedString];
                                                [result appendString: [word substringFromIndex: 1]];
                                            } else {
                                                [result appendString: word];
                                            }
                                        }
                                    } else {
                                        [result appendString: item];
                                    }
                                }
                              }
     ];
    return result;
}

/**
 * Converts umlauts and ß in the receiver to a decomposed form.
 */
- (NSString *)stringWithNormalizedGermanChars {
    NSString *result = [self decomposedStringWithCanonicalMapping];
    result = [result stringByReplacingOccurrencesOfString: @"ß" withString: @"ss"];
    return [result stringByReplacingOccurrencesOfString: @"\u0308" withString: @"e"]; // Combining diaresis.
}

@end
