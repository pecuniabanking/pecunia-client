//
//  Country.h
//  Pecunia
//
//  Created by Frank Emminghaus on 15.11.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Country : NSObject {
    NSString *name;
    NSString *currency;
    NSString *code;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, copy) NSString *code;


@end
