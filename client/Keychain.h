//
//  Keychain.h
//  Pecunia
//
//  Created by Frank Emminghaus on 06.02.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Keychain : NSObject {

}

+(NSString*)passwordForService:(NSString*)service account:(NSString*)account;
+(BOOL)setPassword:(NSString*)password forService:(NSString*)service account:(NSString*)account store:(BOOL)store;
+(void)deletePasswordsForService: (NSString*)service;
+(void)deletePasswordForService:(NSString*)service account:(NSString*)account;

@end
