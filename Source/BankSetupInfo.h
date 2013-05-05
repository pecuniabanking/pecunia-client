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

#import <Cocoa/Cocoa.h>

@interface BankSetupInfo : NSObject {
    NSString *info_userid;
    NSString *info_customerid;
    NSNumber *pinlen_min;
    NSNumber *pinlen_max;
    NSNumber *tanlen_max;
}

@property (nonatomic, strong) NSString *info_userid;
@property (nonatomic, strong) NSString *info_customerid;
@property (nonatomic, strong) NSNumber *pinlen_min;
@property (nonatomic, strong) NSNumber *pinlen_max;
@property (nonatomic, strong) NSNumber *tanlen_max;

@end
