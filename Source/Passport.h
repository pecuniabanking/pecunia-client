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

@interface Passport : NSObject {
    NSString *name;
    NSString *bankCode;
    NSString *bankName;
    NSString *userId;
    NSString *customerId;
    NSString *host;
    //	NSString	*filter;
    NSString *version;
    NSString *tanMethod;
    NSString *port;
    NSArray  *tanMethods;
    BOOL     base64;
    BOOL     checkCert;
}

@property (copy) NSString *name;
@property (copy) NSString *bankCode;
@property (copy) NSString *bankName;
@property (copy) NSString *userId;
@property (copy) NSString *customerId;
@property (copy) NSString *host;
//@property (copy) NSString *filter;
@property (copy) NSString  *version;
@property (copy) NSString  *tanMethod;
@property (copy) NSString  *port;
@property (strong) NSArray *tanMethods;
@property (assign) BOOL    base64;
@property (assign) BOOL    checkCert;

- (void)setFilter: (NSString *)filter;
- (BOOL)isEqual: (id)obj;


@end
