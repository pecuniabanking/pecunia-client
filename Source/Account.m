//
/**
 * Copyright (c) 2008, 2012, Pecunia Project. All rights reserved.
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

#import "Account.h"


@implementation Account

@synthesize name;
@synthesize bankName;
@synthesize bankCode;
@synthesize accountNumber;
@synthesize ownerName;
@synthesize currency;
@synthesize country;
@synthesize iban;
@synthesize bic;
@synthesize userId;
@synthesize customerId;
@synthesize subNumber;
@synthesize type;
@synthesize supportedJobs;

@synthesize collTransfer;
@synthesize substInternalTransfers;


- (BOOL)isEqual: (id)obj
{
    if ([accountNumber isEqual: ((Account *)obj)->accountNumber] && [bankCode isEqual: ((Account *)obj)->bankCode]) {
        if ((subNumber == nil && ((Account *)obj)->subNumber == nil) || [subNumber isEqual: ((Account *)obj)->subNumber]) {
            return YES;
        }
    }
    return NO;
}

@end
