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

#import <Cocoa/Cocoa.h>

@interface TransferTemplate : NSManagedObject {
}

- (NSString *)purpose;

@property (nonatomic, strong) NSString        *currency;
@property (nonatomic, strong) NSString        *name;
@property (nonatomic, strong) NSString        *purpose1;
@property (nonatomic, strong) NSString        *purpose2;
@property (nonatomic, strong) NSString        *purpose3;
@property (nonatomic, strong) NSString        *purpose4;
@property (nonatomic, strong) NSString        *remoteAccount;
@property (nonatomic, strong) NSString        *remoteBankCode;
@property (nonatomic, strong) NSString        *remoteBIC;
@property (nonatomic, strong) NSString        *remoteCountry;
@property (nonatomic, strong) NSString        *remoteIBAN;
@property (nonatomic, strong) NSString        *remoteName;
@property (nonatomic, strong) NSString        *remoteSuffix;
@property (nonatomic, strong) NSDecimalNumber *value;
@property (nonatomic, strong) NSNumber        *type;
@end
