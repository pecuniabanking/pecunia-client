/**
 * Copyright (c) 2010, 2013, Pecunia Project. All rights reserved.
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

#import "CategoryPolicy030.h"

@implementation CategoryPolicy030

- (NSString *)convertRule: (NSString *)rule
{
    NSString *res;
    if (rule != nil) {
        res = [rule stringByReplacingOccurrencesOfString: @"purpose" withString: @"statement.purpose"];
        res = [res stringByReplacingOccurrencesOfString: @"remoteName" withString: @"statement.remoteName"];
        res = [res stringByReplacingOccurrencesOfString: @"remoteAccount" withString: @"statement.remoteAccount"];
        res = [res stringByReplacingOccurrencesOfString: @"localAccount" withString: @"statement.localAccount"];
        return res;
    } else {return rule; }
}

@end
