/**
 * Copyright (c) 2009, 2012, Pecunia Project. All rights reserved.
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

#import "ResultParser.h"
#import "HBCIBridge.h"
#import "HBCIError.h"
#import <objc/runtime.h>
#import "MOAssistant.h"

@implementation ResultParser

-(id)initWithParent: (HBCIBridge*)par
{
	self = [super init ];
	if(self == nil) return nil;
	stack = [[NSMutableArray alloc ] initWithCapacity: 10 ];
	parent = par;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat: @"yyyy-MM-dd" ];
	return self;
}

-(id)result
{
	return result;
}



- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
//	NSLog(@"startElement: %@", elementName);

	currentType = [attributeDict valueForKey: @"type" ];
	if (currentType == nil) currentType = @"";
	if([elementName isEqualToString: @"list" ] || [currentType isEqualToString: @"list" ]) {
		NSMutableArray *list = [NSMutableArray arrayWithCapacity: 10 ];
		[stack addObject: list ];
	} else if ([elementName isEqualToString: @"object" ]) {
		id obj;
		id class = objc_getClass([currentType UTF8String]);
		if (class == nil) {
            NSLog(@"Result parser: couldn't find class \"%s\"", [currentType UTF8String]);
        } else {
            obj = [[class alloc] init];
            [stack addObject: obj];
        }
	} else if ([elementName isEqualToString: @"cdObject" ]) {
		NSManagedObjectContext *context = [[MOAssistant assistant ] memContext ];
		id obj = [NSEntityDescription insertNewObjectForEntityForName:currentType inManagedObjectContext:context ];
		[stack addObject: obj ];
	} else if([elementName isEqualToString: @"dictionary"] || [currentType isEqualToString: @"dictionary" ]) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 10 ];
		[stack addObject: dict ];
	} else if([elementName isEqualToString: @"error" ]) {
		HBCIError *err = [[HBCIError alloc ] init ];
		err.code = [attributeDict valueForKey: @"code" ];
		[stack addObject: err ];
	} else {
//		if(type == nil) [stack addObject: [[[NSMutableString alloc ] init ] autorelease ] ]; else
		[stack addObject: [[NSMutableString alloc ] init ] ];
		// etc.
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	id obj = [stack lastObject ];
	if(obj == nil) return; //todo: exception
	if([obj isKindOfClass: [NSMutableString class ] ]) [obj appendString:string];
	// todo: else case
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	int idx = [stack count ] - 1;
	int prev = idx - 1;
//	NSLog(@"endElement: %@", elementName);
	if([elementName isEqualToString: @"object" ] || [elementName isEqualToString: @"cdObject" ] || [elementName isEqualToString: @"dictionary" ]) {
		if(prev >= 0) {
			id obj = stack[prev];
			if([obj isKindOfClass: [NSMutableArray class ] ]) {
				[obj addObject: [stack lastObject ] ];
				[stack removeLastObject ];
			}
		}
	} else if([elementName isEqualToString: @"list" ] || [elementName isEqualToString: @"error" ]) {
		// do nothing - should work already
	} else if([elementName isEqualToString: @"result" ]) {
		[parser setDelegate: parent ];
		result = [stack lastObject ];
		[parent setResult: [stack lastObject ] ];
		//[self autorelease ]; autorelease where alloc'ed
		return;
	} else {
		if([[stack lastObject ] isKindOfClass: [NSMutableArray class ] ] || [[stack lastObject ] isKindOfClass: [NSMutableDictionary class ] ]) {
			// do nothing
		} else {
			// standard attributes
			if([currentType isEqualToString: @"date" ]) {
				NSDate *date = [dateFormatter dateFromString: [stack lastObject ] ];
				[stack removeLastObject ];
				[stack addObject: date ];
			} else if([currentType isEqualToString: @"value" ]) {
				NSDecimalNumber *value = [NSDecimalNumber decimalNumberWithString: [stack lastObject ] ];
				NSDecimalNumber *div = [NSDecimalNumber decimalNumberWithString: @"100" ];
				value = [value decimalNumberByDividingBy: div ];
				[stack removeLastObject ];
				[stack addObject: value ];
			} else if([currentType isEqualToString: @"long" ]) {
				NSNumber *value = @((long)[[stack lastObject ] longLongValue ]);
				[stack removeLastObject ];
				[stack addObject: value ];
			} else if([currentType isEqualToString: @"boole" ]) {
				NSNumber *value;
				NSString *s = [stack lastObject ];
				if([s isEqualToString: @"yes" ]) value = @YES; else value = @NO;
				[stack removeLastObject ];
				[stack addObject: value ];
			} else if ([currentType isEqualToString:@"int" ]) {
				NSNumber *value;
				NSString *s = [stack lastObject ];
				value = @([s integerValue ]);
				[stack removeLastObject ];
				[stack addObject:value ];
			} else if ([currentType isEqualToString:@"binary"]) {
                NSString *s = [stack lastObject];
                CFErrorRef error = NULL;
                SecTransformRef decoder = SecDecodeTransformCreate(kSecBase64Encoding, &error);
                SecTransformSetAttribute(decoder, kSecTransformInputAttributeName, (__bridge CFTypeRef)([s dataUsingEncoding:NSUTF8StringEncoding]), &error);
                CFDataRef decodedData = SecTransformExecute(decoder, &error);
                [stack removeLastObject];
                [stack addObject:(__bridge id)(decodedData)];
            }
		}
		
		if(prev >= 0) {
			id obj = stack[prev];
			if([obj isKindOfClass: [NSMutableArray class ] ]) {
				[obj addObject: [stack lastObject ] ];
				[stack removeLastObject ];
			} else {
				[obj setValue: [stack lastObject ] forKey: elementName ];
				[stack removeLastObject ];
			}
		}
	}
}

		   
@end
