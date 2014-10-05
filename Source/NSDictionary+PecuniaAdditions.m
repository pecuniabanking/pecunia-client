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

#import "NSDictionary+PecuniaAdditions.h"

// XML to NSDictionary conversion mostly taken from http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/
#pragma mark - XML reader helper class

NSString *const kXMLReaderTextNodeKey = @"text";

@interface XMLReader : NSObject  <NSXMLParserDelegate>
{
    NSMutableArray          *dictionaryStack;
    NSMutableString         *textInProgress;
    NSError __autoreleasing **errorPointer;
}

- (id)initWithError: (NSError **)error;
- (NSDictionary *)objectWithData: (NSData *)data;

@end

@implementation XMLReader

- (id)initWithError: (NSError **)error
{
    if (self = [super init]) {
        errorPointer = error;
    }
    return self;
}

- (NSDictionary *)objectWithData: (NSData *)data
{
    dictionaryStack = [[NSMutableArray alloc] init];
    textInProgress = [[NSMutableString alloc] init];

    // Initialize the stack with a fresh dictionary.
    [dictionaryStack addObject: [NSMutableDictionary dictionary]];

    // Parse the XML.
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData: data];
    parser.delegate = self;
    BOOL success = [parser parse];

    // Return the stack’s root dictionary on success
    if (success) {
        return dictionaryStack[0];
    }

    return nil;
}

#pragma mark NSXMLParserDelegate methods

- (void)     parser: (NSXMLParser *)parser
    didStartElement: (NSString *)elementName
       namespaceURI: (NSString *)namespaceURI
      qualifiedName: (NSString *)qName
         attributes: (NSDictionary *)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [dictionaryStack lastObject];

    // Create the child dictionary for the new element, and initialize it with the attributes.
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary: attributeDict];

    // If there’s already an item for this key, it means we need to create an array.
    id existingValue = parentDict[elementName];
    if (existingValue) {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass: [NSMutableArray class]]) {
            array = (NSMutableArray *)existingValue;
        } else {
            array = [NSMutableArray array];
            [array addObject: existingValue];
            parentDict[elementName] = array;
        }

        [array addObject: childDict];
    } else {
        // No existing value, so update the dictionary
        parentDict[elementName] = childDict;
    }

    [dictionaryStack addObject: childDict];
}

- (void)   parser: (NSXMLParser *)parser
    didEndElement: (NSString *)elementName
     namespaceURI: (NSString *)namespaceURI
    qualifiedName: (NSString *)qName
{
    NSMutableDictionary *dictInProgress = [dictionaryStack lastObject];

    if ([textInProgress length] > 0) {
        dictInProgress[kXMLReaderTextNodeKey] = textInProgress;
        textInProgress = [[NSMutableString alloc] init];
    }

    // Pop the current dict since we are done with this tag.
    [dictionaryStack removeLastObject];
}

- (void)parser: (NSXMLParser *)parser foundCharacters: (NSString *)string
{
    [textInProgress appendString: string];
}

- (void)parser: (NSXMLParser *)parser parseErrorOccurred: (NSError *)parseError
{
    if (errorPointer != nil) {
        *errorPointer = parseError;
    }
}

@end

#pragma mark - NSDictionary category

@implementation NSDictionary (PecuniaAdditions)

+ (NSDictionary *)dictForXMLData: (NSData *)data error: (NSError **)error
{
    XMLReader *reader = [[XMLReader alloc] initWithError: error];
    return [reader objectWithData: data];
}

+ (NSDictionary *)dictForXMLString: (NSString *)string error: (NSError **)error
{
    NSData *data = [string dataUsingEncoding: NSUTF8StringEncoding];
    return [self dictForXMLData: data error: error];
}

+ (NSDictionary *)dictForUrlParameters: (NSURL *)url
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *key = [url query];
    for (NSString *param in [[url query] componentsSeparatedByString: @"="]) {
        if ([key rangeOfString: param].location == NSNotFound)
            params[key] = param;
        key = param;
    }

    return params;
}

/**
 * Looks up an entry for the given key and if that is a dictionary too returns the value of its @"text" subkey,
 * provided that is a string.
 */
- (NSString *)textForKey: (NSString *)key
{
    id temp = self[key];
    if ([temp isKindOfClass: NSDictionary.class]) {
        temp = temp[@"text"];
        if ([temp isKindOfClass: NSString.class]) {
            return temp;
        }
    }
    return nil;
}

/**
 * Returns the dictionary stored under the given path, provided all parts on the path are in fact dictionaries.
 * Returns nil otherwise.
 */
- (NSDictionary *)dictionaryFromPath: (NSArray *)path
{
    NSDictionary *result = self;
    for (NSString *entry in path) {
        if (![result[entry] isKindOfClass: NSDictionary.class]) {
            return nil;
        }

        result = result[entry];
    }

    return result;
}

@end
