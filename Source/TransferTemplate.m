/**
 * Copyright (c) 2010, 2014, Pecunia Project. All rights reserved.
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

#import "TransferTemplate.h"

@implementation TransferTemplate

@dynamic currency;
@dynamic name;
@dynamic purpose1;
@dynamic purpose2;
@dynamic purpose3;
@dynamic purpose4;
@dynamic remoteAccount;
@dynamic remoteBankCode;
@dynamic remoteBankName;
@dynamic remoteBIC;
@dynamic remoteCountry;
@dynamic remoteIBAN;
@dynamic remoteName;
@dynamic remoteSuffix;
@dynamic value;
@dynamic type;

- (NSString *)purpose
{
    NSMutableString *s = [NSMutableString stringWithCapacity: 100];
    if (self.purpose1) {
        [s appendString: self.purpose1];
    }
    if (self.purpose2) {
        [s appendString: @" "]; [s appendString: self.purpose2];
    }
    if (self.purpose3) {
        [s appendString: @" "]; [s appendString: self.purpose3];
    }
    if (self.purpose4) {
        [s appendString: @" "]; [s appendString: self.purpose4];
    }

    return s;
}

@end
