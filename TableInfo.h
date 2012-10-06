//
//  TableInfo.h
//  MacBanking
//
//  Created by Frank Emminghaus on 10.06.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define _cInfos @"ColumnInfos"

@interface TableInfo : NSObject <NSCoding> {
	NSMutableDictionary		*columnInfos;
}

-(id)initWithTable: (NSTableView*)table;
-(id)initWithCoder: (NSCoder*)coder;
-(void)encodeWithCoder: (NSCoder*)coder;

@end
