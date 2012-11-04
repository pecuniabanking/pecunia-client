//
//  LogParser.m
//  Client
//
//  Created by Frank Emminghaus on 19.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LogParser.h"
#import "HBCIBridge.h"
#import "MessageLog.h"

@implementation LogParser

-(id)initWithParent: (id)par level: (NSString*)lev
{
	self = [super init ];
	if(self == nil) return nil;
	parent = par;
	if(lev) level = [lev intValue ] - 1; else level = LogLevel_Debug;
	currentValue = [[NSMutableString alloc ] init ];
	return self;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [currentValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	if([elementName isEqualToString: @"log" ]) {
		[parser setDelegate: parent ];
		[[MessageLog log ] addMessage:currentValue withLevel:level ];
		//[self autorelease ]; don't autorelease here but where the parser is allocated or the analyizer will report a leak.
		return;
	} 
}

@end
