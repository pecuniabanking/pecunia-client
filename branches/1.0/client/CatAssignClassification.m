//
//  CatAssignClassification.m
//  Pecunia
//
//  Created by Frank Emminghaus on 28.07.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "CatAssignClassification.h"
#import "StatCatAssignment.h"
#import "Category.h"

@implementation CatAssignClassification

-(void)setCategory: (Category*)cat
{
	category = cat;
}


-(NSObject*)classify: (NSObject*)obj
{
	StatCatAssignment* stat = (StatCatAssignment*)obj;
	
	if(category == nil) return nil;
	if(stat.category != [Category nassRoot ]) return [NSImage imageNamed: @"yes2.ico" ]; else return nil;
//	NSSet* cats = [stat valueForKey: @"categories" ];
//	if([cats containsObject: category ]) return [NSImage imageNamed: @"yes2.ico" ]; else return nil;
}

@end
