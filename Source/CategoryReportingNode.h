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
    NSString                                             *name;
    NSMutableSet                                         *children;
    NSMutableDictionary                                  *values;
    NSMutableDictionary                                  *periodValues;
    Category                        *__unsafe_unretained category;
}

@property (nonatomic, copy) NSString              *name;
@property (nonatomic, strong) NSMutableSet        *children;
@property (nonatomic, strong) NSMutableDictionary *values;
@property (nonatomic, strong) NSMutableDictionary *periodValues;
@property (nonatomic, unsafe_unretained) Category *category;

@end
