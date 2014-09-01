//
//  RemoteResourceManager.m
//  Pecunia
//
//  Created by Frank Emminghaus on 18.08.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

#import "RemoteResourceManager.h"
#import "NSDictionary+PecuniaAdditions.h"
#import "MessageLog.h"
#import "ShortDate.h"
#import "MOAssistant.h"

#define RemoteResourcePath @"http://www.pecuniabanking.de/downloads/resources/"
#define RemoteResourceUpdateInfo @"http://www.pecuniabanking.de/downloads/resources/updateInfo.xml"
#define DefaultRemoteFiles @"eu_all22.txt.zip"

static RemoteResourceManager * _rrManager = nil;
static NSArray *_defaultFiles = nil;

@implementation RemoteResourceManager

@synthesize fileInfos;


-(id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _defaultFiles = [NSArray arrayWithObjects:DefaultRemoteFiles, nil];

    NSData *xmlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:RemoteResourceUpdateInfo]];
    if (xmlData != nil) {
        NSError *error = nil;
        
        NSDictionary *updateInfo = [NSDictionary dictionaryForXMLData:xmlData error:&error];
        if (error != nil) {
            LogError(@"Parser error for update info file %@", RemoteResourceUpdateInfo);
            return self;
        }
        
        self.fileInfos = updateInfo[@"files"][@"file"];
        
        // update files
        [self performSelectorInBackground:@selector(updateFiles) withObject:nil];
    } else {
        LogError(@"Could not load update info file at %@", RemoteResourceUpdateInfo);
    }
    return self;
}

- (void)addManagedFile: (NSString *)fileName {
    [self performSelectorInBackground:@selector(updateFileAndNotify:) withObject:fileName];
}

- (BOOL)removeManagedFile: (NSString *)fileName {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *targetPath = [MOAssistant.assistant.resourcesDir stringByAppendingPathComponent:fileName];
    
    [fm removeItemAtPath:targetPath error:&error];
    if (error != nil) {
        [[NSAlert alertWithError:error] runModal];
        return NO;
    }
    return YES;
}

- (BOOL)updateFile: (NSString *)fileName {
    NSError *error=nil;
    NSDictionary *fileInfo;
    
    // now check file
    NSString *resourcePath = MOAssistant.assistant.resourcesDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // find entry in fileInfo
    for (fileInfo in self.fileInfos) {
        NSString *name = fileInfo[@"name"];
        if ([name isEqualToString:fileName]) {
            break;
        }
    }
    if ([fileInfo[@"name"] isEqualToString:fileName] == NO) {
        LogError(@"File %@ is not a remote resource file", fileName);
        return NO;
    }
    
    NSString *targetPath = [resourcePath stringByAppendingPathComponent:fileName];
    
    if ([fm fileExistsAtPath:targetPath] == YES) {
        // check if file is older than last update date
        NSDictionary *fileAttrs = [fm attributesOfItemAtPath:targetPath error:&error];
        if (fileAttrs != nil) {
            NSDate *date = [fileAttrs fileModificationDate];
            if (date == nil) {
                date = [fileAttrs fileCreationDate];
            }
            if (date != nil) {
                ShortDate *fileDate = [ShortDate dateWithDate:date];
                date = [dateFormatter dateFromString:fileInfo[@"updated"]];
                if (date != nil) {
                    ShortDate *updateDate = [ShortDate dateWithDate:date];
                    if ([updateDate compare:fileDate] == NSOrderedAscending) {
                        return YES;
                    }
                }
            }
        }
        [fm removeItemAtPath:targetPath error:&error];
    }
    
    // copy file from remote location
    NSURL *sourceURL = [NSURL URLWithString:RemoteResourcePath];
    sourceURL = [sourceURL URLByAppendingPathComponent:fileName];
    NSURL *targetURL = [NSURL fileURLWithPath:targetPath];
    
    //NSData *fileData = [NSData dataWithContentsOfURL:sourceURL];
    NSData *fileData = [NSData dataWithContentsOfURL:sourceURL options:0 error:&error];
    if (error != nil) {
        LogError(@"Could not open remote resource %@", [sourceURL path]);
        return NO;
    }
    if (fileData != nil) {
        if ([fileData writeToURL:targetURL atomically:NO] == NO) {
            LogError(@"Could not copy remote resource %@", [sourceURL path]);
            return NO;
        }
    }
    return YES;
}

- (void)updateFileAndNotify: (NSString *)fileName {
    BOOL result = [self updateFile:fileName];
    
    NSNotification *notification = [NSNotification notificationWithName: PecuniaResourcesUpdatedNotification object: @(result)];
    [[NSNotificationCenter defaultCenter] postNotification: notification];
}

- (void)updateFiles {
    // first check if we already did this today
    NSError *error=nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdated = [defaults objectForKey:@"remoteFilesLastUpdate"];
    ShortDate *last = lastUpdated != nil?[ShortDate dateWithDate:lastUpdated]:nil;
    ShortDate *now = [ShortDate currentDate];
    
    if (last == nil || [last compare:now] == NSOrderedAscending) {
        // now check files
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *files = [fm contentsOfDirectoryAtPath:MOAssistant.assistant.resourcesDir error:&error];
        
        for (NSString *fileName in files) {
            [self updateFile:fileName];
        }
        
        // check if all mandatory files exist
        for (NSString *fileName in _defaultFiles) {
            if ([files containsObject:fileName] == NO) {
                [self updateFile:fileName];
            }
        }
        
        [defaults setObject: [now lowDate] forKey:@"remoteFilesLastUpdate"];
        NSNotification *notification = [NSNotification notificationWithName: PecuniaResourcesUpdatedNotification object: nil];
        [[NSNotificationCenter defaultCenter] postNotification: notification];
    }
}

+ (RemoteResourceManager*)manager {
    if (_rrManager == nil) {
        _rrManager = [[RemoteResourceManager alloc] init];
    }
    return _rrManager;
}




@end
