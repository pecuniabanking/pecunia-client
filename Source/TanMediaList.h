//
//  TanMediaList.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TanMediaList : NSObject {
    NSString    *tanOption;
    NSArray     *mediaList;
}

@property (nonatomic, retain) NSString *tanOption;
@property (nonatomic, retain) NSArray *mediaList;

@end

