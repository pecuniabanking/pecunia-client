/**
 * Copyright (c) 2009, 2013, Pecunia Project. All rights reserved.
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

@interface BankInfo : NSObject {
    NSString *country;
    NSString *branch;
    NSString *bankCode;
    NSString *bic;
    NSString *name;
    NSString *location;
    NSString *street;
    NSString *city;
    NSString *region;
    NSString *phone;
    NSString *email;
    NSString *host;
    NSString *pinTanURL;
    NSString *pinTanVersion;
    NSString *hbciVersion;
    NSString *website;
}

@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *branch;
@property (nonatomic, strong) NSString *bankCode;
@property (nonatomic, strong) NSString *bic;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *pinTanURL;
@property (nonatomic, strong) NSString *pinTanVersion;
@property (nonatomic, strong) NSString *hbciVersion;
@property (nonatomic, strong) NSString *website;

@end
