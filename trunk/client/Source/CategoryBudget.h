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

@property (nonatomic, retain) NSDecimalNumber * budget;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Category * category;

@end
