//
//  CategoryReportingNode.h
//  Pecunia
//
//  Created by Frank Emminghaus on 09.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Category;

@interface CategoryReportingNode : NSObject {
	NSString			*name;
	NSMutableSet		*children;
	NSMutableDictionary	*values;
	NSMutableDictionary *periodValues;
	Category			*category;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSMutableSet *children;
@property (nonatomic, retain) NSMutableDictionary *values;
@property (nonatomic, retain) NSMutableDictionary *periodValues;
@property (nonatomic, assign) Category *category;

@end

