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

@implementation NSString (PecuniaAdditions)

static NSData *receivedTmpData = nil;

/**
 * Returns a new string instance containing the given data as a string (assuming UTF8 encoding).
 * If the given data cannot be converted to an UTF8 string it is converted to a hex string.
 * Returns an empty string if data is nil or empty.
 */
+ (NSString *)stringWithData: (NSData *)data {
    if (data == nil) {
        return [NSString string];
    }

    // issue with received data: if an UTF8 string is cut in between on byte level, its parts do not necessarily represent
    // proper UTF8 strings, e.g. if the cut is between the 2 bytes of a single character
    // we therefore have to look if the combination of 2 or several received data blocks build a valid UTF8 string.
    if (receivedTmpData != nil) {
        NSMutableData *mData = [NSMutableData dataWithData: receivedTmpData];
        [mData appendData: data];
        data = mData;
    }

    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    if (result == nil) {
        receivedTmpData = data;
        return @"";
    }
    receivedTmpData = nil;
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

- (NSString *)stringByEscapingXmlCharacters {
    NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString: @"&<>'"];
    NSRange        range = [self rangeOfCharacterFromSet: cs];
    if (range.location == NSNotFound) {
        return self;
    }
    NSString *res = [self stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"];
    res = [res stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
    res = [res stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"];
    res = [res stringByReplacingOccurrencesOfString: @"'" withString: @"&apos;"];
    return res;
}

@end
