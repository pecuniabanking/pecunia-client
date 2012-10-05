//
//  TableInfo.m
//  MacBanking
//
//  Created by Frank Emminghaus on 10.06.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TableInfo.h"
#import "ColumnInfo.h"

@implementation TableInfo
/*
-(init)

-(id)initWithTable: (NSTableView*)table
{
	int i;
	
	self = [super init ];
	if(self == nil) return self;
	
	NSArray*	cols = [table tableColumns ];
	for(i = 0; i < [cols size ]; i++) {
		NSTableColumn*	col = [cols objectAtIndex: i ];
		
}

-(void)updateWithTable: (NSTableView*)table
{
	int i;
	
	NSArray*	cols = [table tableColumns ];
	for(i = 0; i < [cols size ]; i++) {
		NSTableColumn*	col = [cols objectAtIndex: i ];
	}
	
}

-(void)buildWithTable: (NSTableView*)table
{
	int i;
	
	columnInfos = [[NSMutableDictionary ] dictionaryWithCapacity: 20 ];
	
	NSArray*	cols = [table tableColumns ];
	for(i = 0; i < [cols size ]; i++) {
		NSTableColumn*	col = [cols objectAtIndex: i ];
	}
	
}


-(void)encodeWithCoder: (NSCoder*) coder
{
	[coder encodeObject: columnInfos forKey: _cInfos ];
}

-(id)initWithCoder: (NSCoder*)coder
{
	[super init ];
	columnInfos = [coder decodeObjectForKey: _cInfos ];
	if(columnInfos != nil) [columnInfos retain ];
	return self;
}

-(void)dealloc
{
	if(columnInfos) [columnInfos release ];
}

*/
@end
