/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
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

#import <objc/runtime.h>

#import "MessageLog.h"

#import "ResultParser.h"
#import "HBCIBridge.h"
#import "HBCIError.h"
#import "MOAssistant.h"

#import "NSString+PecuniaAdditions.h"

@implementation ResultParser

- (id)initWithParent: (HBCIBridge *)par
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    stack = [[NSMutableArray alloc] initWithCapacity: 10];
    parent = par;
    NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"Europe/Berlin"];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:tz];
    [dateFormatter setDateFormat: @"yyyy-MM-dd"];
    resultXmlString = [[NSMutableString alloc] init];
    return self;
}

- (NSString*)parsedResultString
{
    return resultXmlString;
}

- (id)result
{
    return result;
}

- (NSData *)decodeBase64: (NSData *)data
{
    char       *source = (char *)data.bytes;
    char       *ret = malloc(data.length);
    NSUInteger retlen = 0;

    int  needFromFirst = 6;
    int  needFromSecond = 2;
    BOOL abort = FALSE;
    int  byteCounter = 0;
    char values[2];

    for (NSUInteger readPos = 0; readPos < data.length; readPos++) {
        values[0] = 0;
        values[1] = 0;

        for (int step = 0; step < 2; step++) {
            char value = 0;

            while ((readPos + step) < data.length) {
                value = source[readPos + step];

                if ((value >= '0' && value <= '9') ||
                    (value >= 'A' && value <= 'Z') ||
                    (value >= 'a' && value <= 'z') ||
                    value == '+' || value == '/' || value == '=') {
                    break;
                }

                readPos++;
            }

            if (!((value >= '0' && value <= '9') ||
                  (value >= 'A' && value <= 'Z') ||
                  (value >= 'a' && value <= 'z') ||
                  value == '+' || value == '/')) {
                abort = true;
                break;
            }

            if (value == '/') {
                value = 63;
            } else if (value == '+') {
                value = 62;
            } else if (value <= '9') {
                value = 52 + value - '0';
            } else if (value <= 'Z') {
                value = value - 'A';
            } else {
                value = 26 + value - 'a';

            }
            if (step == 0) {
                values[0] = (value << (8 - needFromFirst)) & 0xFF;
            } else {
                values[1] = (value >> (6 - needFromSecond)) & 0xFF;
            }
        }
        if (abort) {
            break;
        }

        ret[retlen++] = (values[0] | values[1]);

        if ((byteCounter & 3) == 2) {
            readPos++;
            byteCounter++;
            needFromFirst = 6;
            needFromSecond = 2;
        } else {
            needFromFirst = 6 - needFromSecond;
            needFromSecond = 8 - needFromFirst;
        }

        byteCounter++;
    }
    NSData *retData = [[NSData alloc] initWithBytes: ret length: retlen];
    free(ret);
    return retData;
}

- (void)parser: (NSXMLParser *)parser didStartElement: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName attributes: (NSDictionary *)attributeDict
{
    LogVerbose(@"startElement: %@", elementName);
    [resultXmlString appendFormat:@"<%@>", elementName ];
    
    currentType = [attributeDict valueForKey: @"type"];
    if (currentType == nil) {
        currentType = @"";
    }
    if ([elementName isEqualToString: @"list"] || [currentType isEqualToString: @"list"]) {
        NSMutableArray *list = [NSMutableArray arrayWithCapacity: 10];
        [stack addObject: list];
    } else if ([elementName isEqualToString: @"object"]) {
        id obj;
        id class = objc_getClass([currentType UTF8String]);
        if (class == nil) {
            LogError(@"Result parser: couldn't find class \"%s\"", [currentType UTF8String]);
        } else {
            obj = [[class alloc] init];
            [stack addObject: obj];
        }
    } else if ([elementName isEqualToString: @"cdObject"]) {
        NSManagedObjectContext *context = [[MOAssistant assistant] memContext];
        id                     obj = [NSEntityDescription insertNewObjectForEntityForName: currentType inManagedObjectContext: context];
        [stack addObject: obj];
    } else if ([elementName isEqualToString: @"dictionary"] || [currentType isEqualToString: @"dictionary"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 10];
        [stack addObject: dict];
    } else if ([elementName isEqualToString: @"error"]) {
        HBCIError *err = [[HBCIError alloc] init];
        err.code = [attributeDict valueForKey: @"code"];
        [stack addObject: err];
    } else {
        //		if(type == nil) [stack addObject: [[[NSMutableString alloc ] init ] autorelease ] ]; else
        [stack addObject: [[NSMutableString alloc] init]];
        // etc.
    }
}

- (void)parser: (NSXMLParser *)parser foundCharacters: (NSString *)string
{
    [resultXmlString appendString: [string stringByEscapingXmlCharacters] ];

    id obj = [stack lastObject];
    if (obj == nil) {
        return;                //todo: exception
    }
    if ([obj isKindOfClass: [NSMutableString class]]) {
        [obj appendString: string];
    }
    // todo: else case
}

- (void)parser: (NSXMLParser *)parser didEndElement: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName
{
    if ([elementName isEqualToString: @"result"]) {
        NSString *msg = [NSString stringWithFormat: @"Parsed message result: %@",
                         [MessageLog prettyPrintServerMessage: resultXmlString]];
        LogComTrace(HBCILogIntern, msg);
    } else {
        [resultXmlString appendFormat:@"</%@>", elementName ];
    }
    
    int idx = [stack count] - 1;
    int prev = idx - 1;
    LogVerbose(@"endElement: %@", elementName);
    if ([elementName isEqualToString: @"object"] || [elementName isEqualToString: @"cdObject"] || [elementName isEqualToString: @"dictionary"]) {
        if (prev >= 0) {
            id obj = stack[prev];
            if ([obj isKindOfClass: [NSMutableArray class]]) {
                [obj addObject: [stack lastObject]];
                [stack removeLastObject];
            }
        }
    } else if ([elementName isEqualToString: @"list"] || [elementName isEqualToString: @"error"]) {
        // do nothing - should work already
    } else if ([elementName isEqualToString: @"result"]) {
        [parser setDelegate: parent];
        result = [stack lastObject];
        [parent setResult: [stack lastObject]];
        return;
    } else {
        if ([[stack lastObject] isKindOfClass: [NSMutableArray class]] || [[stack lastObject] isKindOfClass: [NSMutableDictionary class]]) {
            // do nothing
        } else {
            // standard attributes
            if ([currentType isEqualToString: @"date"]) {
                NSDate *date = [dateFormatter dateFromString: [stack lastObject]];
                date = [date dateByAddingTimeInterval:12*3600]; // add 12hrs so we start at noon
                [stack removeLastObject];
                [stack addObject: date];
            } else if ([currentType isEqualToString: @"value"]) {
                NSDecimalNumber *value = [NSDecimalNumber decimalNumberWithString: [stack lastObject]];
                NSDecimalNumber *div = [NSDecimalNumber decimalNumberWithString: @"100"];
                value = [value decimalNumberByDividingBy: div];
                [stack removeLastObject];
                [stack addObject: value];
            } else if ([currentType isEqualToString: @"long"]) {
                NSNumber *value = @((long)[[stack lastObject] longLongValue]);
                [stack removeLastObject];
                [stack addObject: value];
            } else if ([currentType isEqualToString: @"boole"]) {
                NSNumber *value;
                NSString *s = [stack lastObject];
                if ([s isEqualToString: @"yes"]) {
                    value = @YES;
                } else {value = @NO; }
                [stack removeLastObject];
                [stack addObject: value];
            } else if ([currentType isEqualToString: @"int"]) {
                NSNumber *value;
                NSString *s = [stack lastObject];
                value = @([s integerValue]);
                [stack removeLastObject];
                [stack addObject: value];
            } else if ([currentType isEqualToString: @"binary"]) {
                NSString *s = [stack lastObject];
                NSData *decodedData = [self decodeBase64: [s dataUsingEncoding: NSUTF8StringEncoding]];
                [stack removeLastObject];
                [stack addObject: decodedData];
            }
        }

        if (prev >= 0) {
            id obj = stack[prev];
            if ([obj isKindOfClass: [NSMutableArray class]]) {
                [obj addObject: [stack lastObject]];
                [stack removeLastObject];
            } else {
                [obj setValue: [stack lastObject] forKey: elementName];
                [stack removeLastObject];
            }
        }
    }
}

@end
