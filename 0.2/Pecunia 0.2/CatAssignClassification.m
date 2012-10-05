//
//  CatAssignClassification.m
//  Pecunia
//
//  Created by Frank Emminghaus on 28.07.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "CatAssignClassification.h"
#import "BankStatement.h"

@implementation CatAssignClassification

-(void)setCategory: (Category*)cat
{
	category = cat;
}


-(NSObject*)classify: (NSObject*)obj
{
	BankStatement* stat = (BankStatement*)obj;
	
	if(category == nil) return nil;
	NSSet* cats = [stat valueForKey: @"categories" ];
	if([cats containsObject: category ]) return [NSImage imageNamed: @"yes2.ico" ]; else return nil;
}

@end
