/**
 * Copyright (c) 2008, 2013, Pecunia Project. All rights reserved.
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

@class TanMethod;

@interface User : NSObject {
    NSString       *name;
    NSString       *country;
    NSString       *bankCode;
    NSString       *userId;
    NSString       *customerId;
    NSString       *mediumId;
    NSString       *bankURL;
    NSString       *bankName;
    BOOL           forceSSL3;
    BOOL           noBase64;
    BOOL           checkCert;
    NSString       *hbciVersion;
    NSNumber       *tanMethodNumber;
    NSString       *tanMethodDescription;
    NSMutableArray *tanMethodList;
    NSString       *port;
    NSString       *chipCardId;

    NSArray *accounts;
}

@property (nonatomic, strong) NSMutableArray *tanMethodList;
@property (nonatomic, assign) BOOL           forceSSL3;
@property (nonatomic, assign) BOOL           noBase64;
@property (nonatomic, assign) BOOL           checkCert;
@property (nonatomic, strong) NSString       *hbciVersion;
@property (nonatomic, strong) NSNumber       *tanMethodNumber;
@property (nonatomic, copy) NSString         *tanMethodDescription;
@property (nonatomic, copy) NSString         *name;
@property (nonatomic, copy) NSString         *country;
@property (nonatomic, copy) NSString         *bankCode;
@property (nonatomic, copy) NSString         *userId;
@property (nonatomic, copy) NSString         *customerId;
@property (nonatomic, copy) NSString         *mediumId;
@property (nonatomic, copy) NSString         *bankURL;
@property (nonatomic, copy) NSString         *bankName;
@property (nonatomic, copy) NSString         *port;
@property (nonatomic, copy) NSString         *chipCardId;
@property (nonatomic, strong) NSArray        *accounts;

- (BOOL)isEqual: (User *)obj;

@end
