/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
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

@class TanMedium;
@class BankUser;

@interface TanMethod : NSManagedObject {
}

@property (nonatomic, strong) NSString  *identifier;
@property (nonatomic, strong) NSString  *inputInfo;
@property (nonatomic, strong) NSNumber  *maxTanLength;
@property (nonatomic, strong) NSString  *method;
@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSString  *needTanMedia;
@property (nonatomic, strong) NSString  *process;
@property (nonatomic, strong) NSString  *zkaMethodName;
@property (nonatomic, strong) NSString  *zkaMethodVersion;
@property (nonatomic, strong) TanMedium *preferredMedium;
@property (nonatomic, strong) BankUser  *user;

- (NSString*)description;
- (NSString*)descriptionWithIndent: (NSString *)indent;

@end
