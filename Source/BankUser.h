/**
 * Copyright (c) 2012, 2015, Pecunia Project. All rights reserved.
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
#import "SigningOption.h"

@class TanMedium;
@class TanMethod;

@interface BankUser : NSManagedObject {
    BOOL        isRegistered;
    NSString    *updatedUserId;
    NSString    *updatedCustomerId;
}

@property (nonatomic, strong) NSString     *bankCode;
@property (nonatomic, strong) NSString     *bankName;
@property (nonatomic, strong) NSString     *bankURL;
@property (nonatomic, strong) NSNumber     *checkCert;
@property (nonatomic, strong) NSNumber     *noBase64;
@property (nonatomic, strong) NSNumber     *tanMediaFetched;
@property (nonatomic, strong) NSString     *country;
@property (nonatomic, strong) NSString     *customerId;
@property (nonatomic, strong) NSString     *hbciVersion;
@property (nonatomic, strong) NSString     *name;
@property (nonatomic, strong) NSString     *port;
@property (nonatomic, strong) NSString     *userId;
@property (nonatomic, strong) NSString     *chipCardId;
@property (nonatomic, strong) TanMethod    *preferredTanMethod;
@property (nonatomic, strong) NSMutableSet *tanMedia;
@property (nonatomic, strong) NSMutableSet *tanMethods;
@property (nonatomic, strong) NSNumber     *ddvPortIdx;
@property (nonatomic, strong) NSNumber     *ddvReaderIdx;
@property (nonatomic, strong) NSNumber     *secMethod;

@property (nonatomic, strong) NSMutableSet *accounts;

// temporary store for new User and Customer IDs
@property (nonatomic, strong) NSString     *updatedUserId;
@property (nonatomic, strong) NSString     *updatedCustomerId;

@property (nonatomic, assign) BOOL isRegistered;

- (void)updateTanMethods: (NSArray *)methods;
- (void)updateTanMedia: (NSArray *)media;
- (NSArray *)getSigningOptions;
- (void)setpreferredSigningOption: (SigningOption *)option;
- (SigningOption *)preferredSigningOption;
- (int)getpreferredSigningOptionIdx;
- (void)checkForUpdatedLoginData;

- (NSString*)description;
- (NSString*)descriptionWithIndent: (NSString *)indent;

+ (NSArray *)allUsers;
+ (BankUser *)findUserWithId: (NSString *)userId bankCode: (NSString *)bankCode;
+ (BOOL)existsUserWithId:(NSString *)userId;
+ (void)removeUser:(BankUser*)user;

@end
