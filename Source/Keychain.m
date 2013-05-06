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

#import "Keychain.h"
#import <Security/Security.h>

static NSMutableDictionary *passwordCache = nil;

@implementation Keychain

+ (BOOL)setPassword: (NSString *)password forService: (NSString *)service account: (NSString *)account store: (BOOL)store
{
    OSStatus status;

    if (passwordCache == nil) {
        passwordCache = [[NSMutableDictionary alloc] initWithCapacity: 10];
    }
    NSString *key = [NSString stringWithFormat: @"%@/%@", service, account];
    [passwordCache setValue: password forKey: key];
    if (store == NO) {
        return YES;
    }

    status = SecKeychainAddGenericPassword(
                                           NULL,                                                                                                                                                                                     // default keychain
                                           [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                               // length of service name
                                           [service UTF8String],                                                                                                                                                     // service name
                                           [account lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                               // length of account name
                                           [account UTF8String],                                                                                                                                                     // account name
                                           [password lengthOfBytesUsingEncoding: NSUTF8StringEncoding] + 1,                                                                                                                                                          // length of password
                                           [password UTF8String],                                                                                                                                                    // pointer to password data
                                           NULL                                                                                                                                                                                      // the item reference
                                           );
    if (status != noErr) {
        [passwordCache removeObjectForKey: key];
    }
    return status == noErr;
}

+ (NSString *)passwordForService: (NSString *)service account: (NSString *)account
{
    OSStatus           status;
    SecKeychainItemRef itemRef;
    UInt32             myPasswordLength = 0;
    void               *passwordData = nil;
    NSString           *pwd;
    NSString           *key = [NSString stringWithFormat: @"%@/%@", service, account];

    if (passwordCache != nil) {
        pwd = [passwordCache valueForKey: key];
        if (pwd) {
            return pwd;
        }
    }

    status = SecKeychainFindGenericPassword(
                                            NULL,                                                                                                                                                                    // default keychain
                                            [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                                 // length of service name
                                            [service UTF8String],                                                                                                                                                       // service name
                                            [account lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                                 // length of account name
                                            [account UTF8String],                                                                                                                                                       // account name
                                            &myPasswordLength,                                                                                                                                                       // length of password
                                            &passwordData,                                                                                                                                                           // pointer to password data
                                            &itemRef                                                                                                                                                                 // the item reference
                                            );


    if (status != noErr) {
        return nil;
    }

    pwd = [NSString stringWithUTF8String: passwordData];

    if (passwordCache == nil) {
        passwordCache = [[NSMutableDictionary alloc] initWithCapacity: 10];
    }
    [passwordCache setValue: pwd forKey: key];

    SecKeychainItemFreeContent(NULL,               //No attribute data to release
                               passwordData    //Release data buffer allocated by SecKeychainFindGenericPassword
                               );

    if (itemRef) {
        CFRelease(itemRef);
    }

    return pwd;
}

+ (void)deletePasswordForService: (NSString *)service account: (NSString *)account
{
    OSStatus           status;
    SecKeychainItemRef itemRef;
    NSString           *key = [NSString stringWithFormat: @"%@/%@", service, account];

    if (passwordCache != nil) {
        [passwordCache removeObjectForKey: key];
    }

    status = SecKeychainFindGenericPassword(
                                            NULL,                                                                                                                                                                    // default keychain
                                            [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                                 // length of service name
                                            [service UTF8String],                                                                                                                                                       // service name
                                            [account lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                                 // length of account name
                                            [account UTF8String],                                                                                                                                                       // account name
                                            NULL,                                                                                                                                                       // length of password
                                            NULL,                                                                                                                                                           // pointer to password data
                                            &itemRef                                                                                                                                                                 // the item reference
                                            );
    if (status == noErr) {
        if (itemRef) {
            SecKeychainItemDelete(itemRef);
            CFRelease(itemRef);
        }
    }
}

// todo:
+ (void)deletePasswordsForService: (NSString *)service
{
    OSStatus           status;
    SecKeychainItemRef itemRef;

    [passwordCache removeAllObjects];

    do {
        status = SecKeychainFindGenericPassword(
                                                NULL,                                                                                                                                                                        // default keychain
                                                [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding],                                                                                                                                                                     // length of service name
                                                [service UTF8String],                                                                                                                                                           // service name
                                                0,                                                                                                                                                                                                      // length of account name
                                                NULL,                                                                                                                                                                                           // account name
                                                NULL,                                                                                                                                                                        // length of password
                                                NULL,                                                                                                                                                                        // pointer to password data
                                                &itemRef                                                                                                                                                                     // the item reference
                                                );

        if (status == noErr) {
            if (itemRef) {
                SecKeychainItemDelete(itemRef);
                CFRelease(itemRef);
            }
        }
    } while (status == noErr && itemRef != NULL);
}

+ (void)clearCache
{
    [passwordCache removeAllObjects];
}

@end
