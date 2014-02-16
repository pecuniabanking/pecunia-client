/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
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

#import "LocalSettingsController.h"
#import "MOAssistant.h"
#import "Info.h"
#include "MessageLog.h"

@interface LocalSettingsController ()
@end

@implementation LocalSettingsController

// Implement a singleton pattern so that LocalSettingsController can also be used in IB.
+ (id)alloc
{
    return self.sharedSettings;
}

+ (id)allocWithZone: (NSZone *)zone
{
    return self.sharedSettings;
}

+ (instancetype)sharedSettings
{
    static LocalSettingsController* singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self localAlloc] localInit];
    });
    
    return singleton;
}

- (id)init
{
    return self;
}

+ (id)localAlloc
{
    return [super allocWithZone: NULL];
}

- (id)localInit
{
    return [super init];
}

/**
 * Does a lookup for the given key in the context's info entries and returns the value stored under
 * that key (or nil if nothing is found).
 */
- (id)valueForKey: (id)aKey
{
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"Info"
                                                         inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"key = %@", aKey];
    [request setPredicate: predicate];

    NSError *error;
    NSArray *entries = [context executeFetchRequest: request error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return nil;
    }

    if (entries.count > 1) {
        LogWarning(@"Persistent info storage: more than one entry found for key: %@.", aKey);
    }

    if (entries.count == 0) {
        return nil;
    } else {
        Info *info = entries[0];
        @try {
            return [NSKeyedUnarchiver unarchiveObjectWithData: info.value];
        }
        @catch (...) {
            LogWarning(@"Local settings: could not unarchive value for key %@", aKey);
            return nil;
        }
    }
}

/**
 * Writes the given data under the given key in the persistent storage (our managed context).
 * An entry is first created if it doesn't exist yet.
 */
- (void)setValue: (id)anObject forKey: (NSString *)aKey
{
    [self willChangeValueForKey: aKey];

    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: @"Info"
                                                         inManagedObjectContext: context];
    NSFetchRequest      *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];

    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"key = %@", aKey];
    [request setPredicate: predicate];

    NSError *error;
    NSArray *entries = [context executeFetchRequest: request error: &error];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }

    if (entries.count > 1) {
        LogWarning(@"Persistent info storage: more than one entry found for key: %@.", aKey);
    }

    Info *info;
    if (entries.count == 0) {
        // No entry yet, so create one.
        info = [NSEntityDescription insertNewObjectForEntityForName: @"Info" inManagedObjectContext: context];
        info.key = aKey;
    } else {
        info = entries[0];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: anObject];
    info.value = data;
    [context commitEditing];

    [self didChangeValueForKey: aKey];
}

- (NSInteger)integerForKey: (NSString *)key
{
    return [[self valueForKey: key] integerValue];
}

- (BOOL)boolForKey: (NSString *)key
{
    return [[self valueForKey: key] boolValue];
}

- (NSString *)stringForKey: (NSString *)key
{
    return [[self valueForKey: key] stringValue];
}

- (void)setInteger: (NSInteger)value forKey: (NSString *)key
{
    [self setValue: @(value) forKey: key];
}

- (void)setBool: (BOOL)value forKey: (NSString *)key
{
    [self setValue: @(value) forKey: key];
}

- (void)setString: (NSString *)value forKey: (NSString *)key
{
    [self setValue: value forKey: key];
}

- (void)setObject: (id)object forKeyedSubscript: (id)subscript
{
    [self setValue: object forKey: subscript];
}

- (id)objectForKeyedSubscript: (id)subscript
{
    return [self valueForKey: subscript];
}

@end
