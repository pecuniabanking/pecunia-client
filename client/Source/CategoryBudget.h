//
//  CategoryBudget.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.01.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Category;

@interface CategoryBudget : NSManagedObject {

}

@end

@interface CategoryBudget (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSDecimalNumber * budget;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Category * category;
@end
