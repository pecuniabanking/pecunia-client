//
//  LogParser.m
//  Client
//
//  Created by Frank Emminghaus on 19.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "LogParser.h"
#import "HBCIBridge.h"
#import "LogController.h"

@implementation LogParser

-(id)initWithParent: (id)par level: (NSString*)lev
{
	self = [super init ];
	if(self == nil) return nil;
	parent = par;
	if(lev) level = [lev intValue ]; else level = 0;
	currentValue = [[[NSMutableString alloc ] init ] autorelease ];
	if(level == 1) {
		level = 1;
	}
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
		[[LogController logController ] logMessage:currentValue withLevel:level ]; 
		[self autorelease ];
		return;
	} 
}

@end
