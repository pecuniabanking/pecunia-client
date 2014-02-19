/**
 * Copyright (c) 2012, 2014, Pecunia Project. All rights reserved.
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

#import "LaunchParameters.h"
#import "DDLog.h" // For internal log levels.

static NSString *extensionPackage = @".pecuniadata";

@implementation LaunchParameters

@synthesize dataFile;
@synthesize debugServer;
@synthesize customLogLevel;

static LaunchParameters *parameters = nil;

- (void)parseParameters
{
    NSUserDefaults *arguments = NSUserDefaults.standardUserDefaults;

    // Customize data file name and other parameters.
    NSString *parameter = [arguments objectForKey: @"f"]; // "-f <datafile>"
    if (parameter.length > 0) {
        dataFile = parameter;
        if (![parameter hasSuffix: extensionPackage]) {
            dataFile = [parameter stringByAppendingString: extensionPackage];
        }
    }

    parameter = [arguments objectForKey: @"d"]; // "-d server"
    if (parameter.length > 0 && [parameter caseInsensitiveCompare: @"server"] == NSOrderedSame) {
        debugServer = YES;
    }

    customLogLevel = -1;
    parameter = [arguments objectForKey: @"loglevel"]; // "-loglevel (off, error, warning, info, debug, verbose)"
    if (parameter.length > 0) {
        NSDictionary *stringToNumber = @{@"off": @LOG_LEVEL_OFF,
                                         @"error": @LOG_LEVEL_ERROR,
                                         @"warning": @LOG_LEVEL_WARN,
                                         @"info": @LOG_LEVEL_INFO,
                                         @"debug": @LOG_LEVEL_DEBUG,
                                         @"verbose": @LOG_LEVEL_VERBOSE};
        NSNumber *number = [stringToNumber objectForKey: parameter.lowercaseString];
        if (number) {
            customLogLevel = number.intValue;
            NSLog(@"Setting log level to %@ (0x%.2X)", parameter.lowercaseString, customLogLevel);
        } else {
            NSLog(@"Invalid log level \"%@\" specified. Using default log level instead.", parameter.lowercaseString);
        }
    }
}

+ (LaunchParameters *)parameters
{
    if (parameters == nil) {
        parameters = [[LaunchParameters alloc] init];
    }
    return parameters;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        [self parseParameters];
    }
    return self;
}

- (void)dealloc
{
    dataFile = nil;

}

@end
