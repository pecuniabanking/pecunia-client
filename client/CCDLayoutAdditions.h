//
//  CCDLayoutAdditions.h
//  MacBanking
//
//  Created by Frank Emminghaus on 08.02.08.
//  Copyright 2008 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSSplitView (CCDLayoutAdditions)

- (void)storeLayoutWithName: (NSString*)name;
- (void)loadLayoutWithName: (NSString*)name;

@end
