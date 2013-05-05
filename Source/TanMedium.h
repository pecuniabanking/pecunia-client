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

@class BankUser;

@interface TanMedium : NSManagedObject {
}

@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *cardNumber;
@property (nonatomic, strong) NSString *cardSeqNumber;
@property (nonatomic, strong) NSNumber *cardType;
@property (nonatomic, strong) NSDate   *validFrom;
@property (nonatomic, strong) NSDate   *validTo;
@property (nonatomic, strong) NSString *tanListNumber;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *mobileNumber;
@property (nonatomic, strong) NSString *mobileNumberSecure;
@property (nonatomic, strong) NSNumber *freeTans;
@property (nonatomic, strong) NSDate   *lastUse;
@property (nonatomic, strong) NSDate   *activatedOn;
@property (nonatomic, strong) BankUser *user;

@end
