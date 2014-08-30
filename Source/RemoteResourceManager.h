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
@property (nonatomic, strong) NSArray *managedFiles;

+ (RemoteResourceManager*)manager;
- (void)addManagedFile: (NSString *)fileName;
- (void)removeManagedFile: (NSString *)fileName;

@end
