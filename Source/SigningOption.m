/**
 * Copyright (c) 2012, 2013, Pecunia Project. All rights reserved.
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

#import "SigningOption.h"
#import "BankUser.h"


@implementation SigningOption

@synthesize userId;
@synthesize userName;
@synthesize cardId;
@synthesize tanMethod;
@synthesize tanMethodName;
@synthesize tanMediumName;
@synthesize tanMediumCategory;
@synthesize mobileNumber;
@synthesize secMethod;

- (id)copyWithZone: (NSZone *)zone
{
    return self;
}

- (NSString *)description
{
    if (secMethod == SecMethod_PinTan) {
        if (tanMediumName) {
            return [NSString stringWithFormat: @"%@ (%@)", tanMethodName, tanMediumName];
        } else {
            return tanMethodName;
        }
    } else {
        return [NSString stringWithFormat: @"Chipkarte: %@", cardId];
    }

}

+(SigningOption*)defaultOptionForUser:(BankUser*)user
{
    SigningOption *option = [[SigningOption alloc] init];
    option.userId = user.userId;
    option.userName = user.name;
    option.tanMethod = @"900";
    option.TanMethodName = @"unbekannt";
    return option;
}

@end
