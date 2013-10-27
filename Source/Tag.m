/**
 * Copyright (c) 2013, Pecunia Project. All rights reserved.
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

#import "Tag.h"

#import "NSColor+PecuniaAdditions.h"
#import "BankStatement.h"
#include "MOAssistant.h"

@implementation Tag

@dynamic caption;
@dynamic color;
@dynamic order;
@dynamic statements;

@synthesize tagColor;

+ (void)createDefaultTags
{
    NSString *sentinel = NSLocalizedString(@"AP900", nil); // Upper limit.
    if (sentinel == nil || sentinel.length == 0) {
        return;
    }

    int lower = 850;
    int upper = [sentinel intValue];
    if (upper <= lower) {
        return;
    }

    NSError *error = nil;

    // First remove any existing tag.
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSManagedObjectModel   *model = MOAssistant.assistant.model;
    NSFetchRequest         *request = [model fetchRequestTemplateForName: @"allTags"];
    NSArray                *existingTags = [context executeFetchRequest: request error: &error];
    for (Tag *tag in existingTags) {
        [context deleteObject: tag];
    }
    for (int i = lower; i <= upper; i++) {
        NSString *key = [NSString stringWithFormat: @"AP%u", i];
        NSString *entry = NSLocalizedString(key, nil);

        Tag *tag = [NSEntityDescription insertNewObjectForEntityForName: @"Tag" inManagedObjectContext: context];
        tag.order = @(i - 850);
        tag.caption = entry;
        tag.tagColor = [NSColor nextDefaultTagColor];
    }
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

+ (Tag *)createTagWithCaption: (NSString *)caption index: (NSUInteger)index
{
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    Tag                    *tag = [NSEntityDescription insertNewObjectForEntityForName: @"Tag" inManagedObjectContext: context];
    tag.order = @(index);
    tag.caption = caption;
    tag.tagColor = [NSColor nextDefaultTagColor];

    return tag;
}

+ (Tag *)tagWithCaption: (NSString *)caption
{
    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSManagedObjectModel   *model = MOAssistant.assistant.model;

    NSDictionary   *substitution = @{@"caption": caption};
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName: @"tagWithCaption"
                                                substitutionVariables: substitution];
    NSArray *tags = [context executeFetchRequest: request error: &error];
    if (error != nil) {
        NSLog(@"Error reading tags: %@", error.localizedDescription);
    }
    return tags.count == 0 ? nil : tags[0];
}

/**
 * Changes the order so that the receiver is sorted before the target tag.
 * One exception: if target is nil the receiver is moved to the end of the list.
 */
- (void)sortBefore: (Tag *)target
{
    NSError                *error = nil;
    NSManagedObjectContext *context = MOAssistant.assistant.context;
    NSManagedObjectModel   *model = MOAssistant.assistant.model;
    NSFetchRequest         *request = [model fetchRequestTemplateForName: @"allTags"];
    NSArray                *tags = [context executeFetchRequest: request error: &error];

    NSInteger sourceOrder = self.order.integerValue;
    NSInteger targetOrder = (target == nil) ? tags.count : target.order.integerValue;

    NSInteger delta = sourceOrder - targetOrder;
    if (delta == 0 || delta == -1) {
        return;
    }

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey: @"order" ascending: YES];
    tags = [tags sortedArrayUsingDescriptors: @[sd]];

    if (sourceOrder < targetOrder) {
        // Moving tag towards the end.
        targetOrder--;
        for (Tag *tag in tags) {
            NSInteger order = tag.order.integerValue;
            if (order < sourceOrder) {
                continue;
            }
            if (order > targetOrder) {
                break;
            }

            if (tag == self) {
                tag.order = @(targetOrder);
            } else {
                tag.order = @(order - 1);
            }
        }
    } else {
        // Moving tag towards the beginning.
        for (Tag *tag in tags) {
            NSInteger order = tag.order.integerValue;
            if (order < targetOrder) {
                continue;
            }
            if (order > sourceOrder) {
                break;
            }

            if (tag == self) {
                tag.order = @(targetOrder);
            } else {
                tag.order = @(order + 1);
            }
        }
    }

    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
}

- (NSColor *)tagColor
{
    [self willAccessValueForKey: @"tagColor"];
    if (self.color == nil) {
        tagColor = [NSColor nextDefaultTagColor];

        // Archive the just determined color.
        NSMutableData *data = [NSMutableData data];

        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: tagColor forKey: @"color"];
        [archiver finishEncoding];

        self.color = data;
    } else {
        if (tagColor == nil) {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: self.color];
            tagColor = [unarchiver decodeObjectForKey: @"color"];
            [unarchiver finishDecoding];
        }
    }

    [self didAccessValueForKey: @"tagColor"];

    return tagColor;
}

- (void)setTagColor: (NSColor *)color
{
    if (![tagColor isEqualTo: color]) {
        [self willChangeValueForKey: @"tagColor"];
        tagColor = color;

        NSMutableData *data = [NSMutableData data];

        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: tagColor forKey: @"color"];
        [archiver finishEncoding];

        self.color = data;
        [self didChangeValueForKey: @"tagColor"];
    }
}

@end
