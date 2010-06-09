//
//  ExportController.h
//  Pecunia
//
//  Created by Frank Emminghaus on 07.08.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Category;

@interface ExportController : NSObject {
	NSDate		*fromDate;
	NSDate		*toDate;
	BOOL		withChildren;
	
	Category	*category;
	
	IBOutlet NSView		*accessoryView;
	IBOutlet NSMutableArray	*selectedFields;
}

-(void)startExport: (Category*)cat;
+(void)export: (Category*)cat;

@end
