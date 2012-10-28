/**
 * Copyright (c) 2012, Pecunia Project. All rights reserved.
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

@implementation LaunchParameters

@synthesize dataFile;
@synthesize debugServer;

static LaunchParameters *parameters = nil;

- (void)parseParameters
{
    // Customize data file name and other parameters.
    BOOL altFile = NO;
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    for (NSString *s in args) {
        if ([s hasPrefix:@"-f" ]) {
            altFile = YES;
            NSString *name = [s substringFromIndex: 2];
            if (name == nil || [name length] == 0) {
                continue;
            }
            else {
                dataFile = [name stringByExpandingTildeInPath];
                altFile = NO;
            }
        }
        if (altFile) {
            // If there's a space between -f and the file name we end up here.
            altFile = NO;
            if (s == nil || [s length] == 0) {
                continue;
            }
            dataFile = [s stringByExpandingTildeInPath];
        }
        
        if ([s isEqualToString: @"-dServer"]) {
            debugServer = YES;
        }
    }
}

+(LaunchParameters*)parameters
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
	[dataFile release], dataFile = nil;

	[super dealloc];
}

@end

