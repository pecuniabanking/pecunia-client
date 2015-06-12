/**
 * Copyright (c) 2009, 2015, Pecunia Project. All rights reserved.
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

#import "CallbackParser.h"
#import "HBCIBridge.h"
#import "CallbackData.h"
#import "CallbackHandler.h"

@implementation CallbackParser

- (id)initWithParent: (HBCIBridge *)par command: (NSString *)cmd {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    data = [[CallbackData alloc] init];
    data.command = cmd;
    parent = par;
    return self;
}

-  (void)parser: (NSXMLParser *)parser
didStartElement: (NSString *)elementName
   namespaceURI: (NSString *)namespaceURI
  qualifiedName: (NSString *)qName
     attributes: (NSDictionary *)attributeDict {
    currentValue = [[NSMutableString alloc] init];
}

- (void)parser: (NSXMLParser *)parser foundCharacters: (NSString *)string {
    [currentValue appendString: string];
}

- (void)parser: (NSXMLParser *)parser
 didEndElement: (NSString *)elementName
  namespaceURI: (NSString *)namespaceURI
 qualifiedName: (NSString *)qName {
    if ([elementName isEqualToString: @"callback"]) {
        [parser setDelegate: parent];

        // do command handling here.
        NSString *result = [CallbackHandler.handler callbackWithData: data parent: parent];

        NSPipe *pipe = [parent outPipe];
        result = [result stringByAppendingString: @"\n"];
        [[pipe fileHandleForWriting] writeData: [result dataUsingEncoding: NSUTF8StringEncoding]];

        return;
    }
    [data setValue: currentValue forKey: elementName];
}

@end
