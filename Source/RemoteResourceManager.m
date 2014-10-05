/**
 * Copyright (c) 2014, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "RemoteResourceManager.h"
#import "NSDictionary+PecuniaAdditions.h"
#import "MessageLog.h"
#import "ShortDate.h"
#import "MOAssistant.h"

#define RemoteResourcePath       @"http://www.pecuniabanking.de/downloads/resources/"
#define RemoteResourceUpdateInfo @"http://www.pecuniabanking.de/downloads/resources/updateInfo.xml"

@interface RemoteResourceManager ()
{
    NSArray *defaultFiles;
}

@end

@implementation RemoteResourceManager

@synthesize fileInfos;

- (id)init {
    self = [super init];
    if (self != nil) {
        defaultFiles = @[@"eu_all22.txt.zip"];

        NSData *xmlData = [NSData dataWithContentsOfURL: [NSURL URLWithString: RemoteResourceUpdateInfo]];
        if (xmlData != nil) {
            NSError *error = nil;

            NSDictionary *updateInfo = [NSDictionary dictForXMLData: xmlData error: &error];
            if (error != nil) {
                LogError(@"Parser error for update info file %@", RemoteResourceUpdateInfo);
                return self;
            }

            self.fileInfos = updateInfo[@"files"][@"file"];

            // Trigger updating files in the background.
            [self performSelectorInBackground: @selector(updateFiles) withObject: nil];
        } else {
            LogError(@"Could not load update info file at %@", RemoteResourceUpdateInfo);
        }
    }
    return self;
}

- (void)addManagedFile: (NSString *)fileName {
    [self performSelectorInBackground: @selector(updateFileAndNotify:) withObject: fileName];
}

- (BOOL)removeManagedFile: (NSString *)fileName {
    NSError       *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString      *targetPath = [MOAssistant.assistant.resourcesDir stringByAppendingPathComponent: fileName];

    [fm removeItemAtPath: targetPath error: &error];
    if (error != nil) {
        [[NSAlert alertWithError: error] runModal];
        return NO;
    }
    return YES;
}

/**
 * Typically triggered in a background thread to check and eventually update the given file from
 * the remote location (if it doesn't exist or is outdated).
 *
 * @param fileName Contains the pure file name without path information.
 * @return YES, if the file is up-to-date or could be updated successfully.
 */
- (BOOL)updateFile: (NSString *)fileName {
    NSString        *resourcePath = MOAssistant.assistant.resourcesDir;
    NSFileManager   *fm = NSFileManager.defaultManager;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";

    // Check that the given file is one of the remote files we can download.
    NSDictionary *fileInfo;
    for (fileInfo in fileInfos) {
        if ([fileInfo[@"name"] isEqualToString: fileName]) {
            break;
        }
    }
    if (![fileInfo[@"name"] isEqualToString: fileName]) {
        LogWarning(@"File %@ is not a remote resource file", fileName);
        return NO;
    }

    NSString *targetPath = [resourcePath stringByAppendingPathComponent: fileName];
    if ([fm fileExistsAtPath: targetPath]) {
        // File exists already. Check if it is older than the last update date.
        NSError      *error;
        NSDictionary *fileAttrs = [fm attributesOfItemAtPath: targetPath error: &error];
        if (fileAttrs != nil) {
            NSDate *date = fileAttrs.fileModificationDate;
            if (date == nil) {
                date = [fileAttrs fileCreationDate];
            }
            if (date != nil) {
                ShortDate *fileDate = [ShortDate dateWithDate: date];
                date = [dateFormatter dateFromString: fileInfo[@"updated"]];
                if (date != nil) {
                    ShortDate *updateDate = [ShortDate dateWithDate: date];
                    if ([updateDate compare: fileDate] == NSOrderedAscending) {
                        return YES;
                    }
                }
            }
        }
        [fm removeItemAtPath: targetPath error: &error];
    }

    // copy file from remote location
    NSURL *sourceURL = [NSURL URLWithString: RemoteResourcePath];
    sourceURL = [sourceURL URLByAppendingPathComponent: fileName];
    NSURL *targetURL = [NSURL fileURLWithPath: targetPath];

    NSError *error;
    NSData  *fileData = [NSData dataWithContentsOfURL: sourceURL options: 0 error: &error];
    if (error != nil) {
        LogError(@"Could not open remote resource %@", [sourceURL path]);
        return NO;
    }
    if (fileData != nil) {
        if ([fileData writeToURL: targetURL atomically: NO] == NO) {
            LogError(@"Could not copy remote resource %@", [sourceURL path]);
            return NO;
        }
    }
    return YES;
}

- (void)updateFileAndNotify: (NSString *)fileName {
    BOOL result = [self updateFile: fileName];

    NSNotification *notification = [NSNotification notificationWithName: PecuniaResourcesUpdatedNotification object: @(result)];
    [[NSNotificationCenter defaultCenter] postNotification: notification];
}

- (void)updateFiles {
    // first check if we already did this today
    NSError        *error = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate         *lastUpdated = [defaults objectForKey: @"remoteFilesLastUpdate"];
    ShortDate      *last = lastUpdated != nil ? [ShortDate dateWithDate: lastUpdated] : nil;
    ShortDate      *now = [ShortDate currentDate];

    if (last == nil || [last compare: now] == NSOrderedAscending) {
        // now check files
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray       *files = [fm contentsOfDirectoryAtPath: MOAssistant.assistant.resourcesDir error: &error];

        for (NSString *fileName in files) {
            [self updateFile: fileName];
        }
        // check if all mandatory files exist
        for (NSString *fileName in defaultFiles) {
            if ([files containsObject: fileName] == NO) {
                [self updateFile: fileName];
            }
        }
        [defaults setObject: [now lowDate] forKey: @"remoteFilesLastUpdate"];
        NSNotification *notification = [NSNotification notificationWithName: PecuniaResourcesUpdatedNotification object: nil];
        [[NSNotificationCenter defaultCenter] postNotification: notification];
    }
}

+ (RemoteResourceManager *)manager {
    static RemoteResourceManager *instance;
    if (instance == nil) {
        instance = [RemoteResourceManager new];
    }
    return instance;
}

@end
