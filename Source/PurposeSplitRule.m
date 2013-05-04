/**
 * Copyright (c) 2011, 2012, Pecunia Project. All rights reserved.
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

#import "PurposeSplitRule.h"
#import "BankStatement.h"

@implementation PurposeSplitRule

- (id)initWithString: (NSString *)rule
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    NSArray *tokens = [rule componentsSeparatedByString: @":"];
    if ([tokens count] != 2) {
        return nil;
    }

    // first part is version info, skip
    NSString *s = tokens[1];
    tokens = [s componentsSeparatedByString: @","];
    if ([tokens count] != 7) {
        return nil;
    }
    ePos = [tokens[0] intValue];
    eLen = [tokens[1] intValue];
    kPos = [tokens[2] intValue];
    kLen = [tokens[3] intValue];
    bPos = [tokens[4] intValue];
    bLen = [tokens[5] intValue];
    vPos = [tokens[6] intValue];
    return self;
}

- (void)applyToStatement: (BankStatement *)stat
{
    NSRange eRange;
    NSRange kRange;
    NSRange bRange;

    eRange.location = ePos;
    eRange.length = eLen;
    kRange.location = kPos;
    kRange.length = kLen;
    bRange.location = bPos;
    bRange.length = bLen;

    stat.additional = stat.purpose;
    if (eRange.length) {
        stat.remoteName = [[stat.purpose substringWithRange: eRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (kRange.length) {
        stat.remoteAccount = [[stat.purpose substringWithRange: kRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (bRange.length) {
        stat.remoteBankCode = [[stat.purpose substringWithRange: bRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (vPos) {
        stat.purpose = [[stat.purpose substringFromIndex: vPos] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

@end
