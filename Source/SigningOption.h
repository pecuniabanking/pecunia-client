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

typedef enum {
    SecMethod_PinTan = 0,
    SecMethod_DDV,
    SecMethod_Script
} SecurityMethod;

@interface SigningOption : NSObject {
    SecurityMethod secMethod;

    NSString *tanMethod;
    NSString *tanMethodName;
    NSString *tanMediumName;
    NSString *tanMediumCategory;
    NSString *mobileNumber;
    NSString *userId;
    NSString *userName;
    NSString *cardId;

}

@property (nonatomic, copy) NSString         *userId;
@property (nonatomic, copy) NSString         *userName;
@property (nonatomic, copy) NSString         *cardId;
@property (nonatomic, copy) NSString         *tanMethod;
@property (nonatomic, copy) NSString         *tanMethodName;
@property (nonatomic, copy) NSString         *tanMediumName;
@property (nonatomic, copy) NSString         *tanMediumCategory;
@property (nonatomic, copy) NSString         *mobileNumber;
@property (nonatomic, assign) SecurityMethod secMethod;

+(SigningOption*)defaultOptionForUser:(BankUser*)user;

@end
