//
//  Keychain.m
//  Pecunia
//
//  Created by Frank Emminghaus on 06.02.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "Keychain.h"
#import <Security/Security.h>

@implementation Keychain


+(BOOL)setPassword:(NSString*)password forService:(NSString*)service account:(NSString*)account 
{
	OSStatus status;
	
	status = SecKeychainAddGenericPassword (
											NULL,						// default keychain
											[service lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of service name
											[service UTF8String],		// service name
											[account lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of account name
											[account UTF8String ],		// account name
											[password lengthOfBytesUsingEncoding: NSUTF8StringEncoding]+1,			// length of password
											[password UTF8String],		// pointer to password data
											NULL						// the item reference
	);
	return (status == noErr);
}

+(NSString*)passwordForService:(NSString*)service account:(NSString*)account
{
	OSStatus status ;
	SecKeychainItemRef itemRef;
	UInt32 myPasswordLength = 0;
	void *passwordData = nil;
	NSString *pwd;
	
	status = SecKeychainFindGenericPassword (
											 NULL,                       // default keychain
											 [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of service name
											 [service UTF8String],		// service name
											 [account lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of account name
											 [account UTF8String ],		// account name
											 &myPasswordLength,          // length of password
											 &passwordData,              // pointer to password data
											 &itemRef                    // the item reference
	);
	
	
	if (status != noErr) return nil;
	
	pwd = [NSString stringWithUTF8String:passwordData ];
	
	status = SecKeychainItemFreeContent (
										 NULL,           //No attribute data to release
										 passwordData    //Release data buffer allocated by SecKeychainFindGenericPassword
	);
	
	if (itemRef) CFRelease(itemRef);
	
	return pwd;
}

+(void)deletePasswordForService:(NSString*)service account:(NSString*)account
{
	OSStatus status ;
	SecKeychainItemRef itemRef;
	
	status = SecKeychainFindGenericPassword (
											 NULL,                       // default keychain
											 [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of service name
											 [service UTF8String],		// service name
											 [account lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of account name
											 [account UTF8String ],		// account name
											 NULL,          // length of password
											 NULL,              // pointer to password data
											 &itemRef                    // the item reference
											 );
	if(status == noErr) {
		if(itemRef) {
			SecKeychainItemDelete(itemRef);
			CFRelease(itemRef);
		}
	}
}

+(void)deletePasswordsForService: (NSString*)service
{
	OSStatus status;
	SecKeychainItemRef itemRef;
	
	do {
		status = SecKeychainFindGenericPassword (
												 NULL,                       // default keychain
												 [service lengthOfBytesUsingEncoding: NSUTF8StringEncoding ],			// length of service name
												 [service UTF8String],		// service name
												 0,							// length of account name
												 NULL,						// account name
												 NULL,                       // length of password
												 NULL,                       // pointer to password data
												 &itemRef                    // the item reference
		);
	
		if(status == noErr) {
			if(itemRef) {
				SecKeychainItemDelete(itemRef);
				CFRelease(itemRef);
			}
		}
	} while(status == noErr && itemRef != NULL);
}

@end
