//
//  RemoteResourceManager.h
//  Pecunia
//
//  Created by Frank Emminghaus on 18.08.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

#import <Foundation/Foundation.h>
#define PecuniaResourcesUpdatedNotification           @"PecuniaResourcesUpdatedNotification"

@interface RemoteResourceManager : NSObject {
    
}

@property (nonatomic, strong) NSArray *fileInfos;

+ (RemoteResourceManager*)manager;
- (void)addManagedFile: (NSString *)fileName;
- (BOOL)removeManagedFile: (NSString *)fileName;

@end
