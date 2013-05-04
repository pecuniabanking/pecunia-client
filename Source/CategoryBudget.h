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

@property (nonatomic, strong) NSDecimalNumber *budget;
@property (nonatomic, strong) NSDate          *date;
@property (nonatomic, strong) Category        *category;

@end
