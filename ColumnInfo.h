//
//  ColumnInfo.h
//  MacBanking
//
//  Created by Frank Emminghaus on 10.06.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ColumnInfo : NSObject {
	BOOL				visible;
	float				width;
	NSSortDescriptor	*sd;
	NSString			*name;
}


-(BOOL)visible;
-(BOOL)sorted;
-(BOOL)width;


@end
