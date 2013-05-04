//
//  Passport.h
//  Client
//
//  Created by Frank Emminghaus on 10.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
