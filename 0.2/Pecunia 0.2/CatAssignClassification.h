//
//  CatAssignClassification.h
//  Pecunia
//
//  Created by Frank Emminghaus on 28.07.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import "ClassificationContext.h"
@class Category;

@interface CatAssignClassification : ClassificationContext {
	Category*	category;
}

-(void)setCategory: (Category*)cat;
-(NSObject*)classify: (NSObject*)obj;

@end
