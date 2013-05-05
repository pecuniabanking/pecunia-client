/**
 * Copyright (c) 2011, 2013, Pecunia Project. All rights reserved.
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

#import "MessageLog.h"

static MessageLog *_messageLog;

@implementation MessageLog

@synthesize forceConsole;
@synthesize currentLevel;

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"HH:mm:ss.SSS"];
    logUIs = [[NSMutableSet alloc] initWithCapacity: 5];
    return self;
}

- (void)registerLogUI: (id<MessageLogUI>)ui
{
    @synchronized(logUIs) {
        if (![logUIs containsObject: ui]) {
            [logUIs addObject: ui];
        }
    }
}

- (void)unregisterLogUI: (id<MessageLogUI>)ui
{
    @synchronized(logUIs) {
        if ([logUIs containsObject: ui]) {
            [logUIs removeObject: ui];
        }
    }
}

- (void)addMessage: (NSString *)msg withLevel: (LogLevel)level
{
    if ([logUIs count] == 0 && !forceConsole) {
        return;
    }
    NSDate   *date = [NSDate date];
    NSString *message = [NSString stringWithFormat: @"<%@> %@\n", [formatter stringFromDate: date], msg];
    if (forceConsole) {
        NSLog(@"%@", message);
    }

    @synchronized(logUIs) {
        for (id<MessageLogUI> logUI in logUIs) {
            [logUI addMessage: message withLevel: level];
        }
    }
}

- (void)addMessageFromDict: (NSDictionary *)data
{
    LogLevel level = (LogLevel)[data[@"level"] intValue];
    [self addMessage: data[@"message"] withLevel: level];
}

- (void)setLevel: (LogLevel)level
{
    currentLevel = level;
    // todo
}

+ (MessageLog *)log
{
    if (_messageLog == nil) {
        _messageLog = [[MessageLog alloc] init];
    }
    return _messageLog;
}

@end
