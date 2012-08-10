//
//  User.h
//  MacBanking
//
//  Created by Frank Emminghaus on 17.03.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TanMethod;

@interface User : NSObject {
	NSString		*name;
	NSString		*country;
	NSString		*bankCode;
	NSString		*userId;
	NSString		*customerId;
	NSString		*mediumId;
	NSString		*bankURL;
	NSString		*bankName;
	BOOL			forceSSL3;
	BOOL			noBase64;
	BOOL			checkCert;
	NSString		*hbciVersion;
	NSNumber		*tanMethodNumber;
	NSString		*tanMethodDescription;
	NSMutableArray	*tanMethodList;	
	NSString		*port;
    NSString        *chipCardId;
}

@property (nonatomic, retain) NSMutableArray *tanMethodList;
@property (nonatomic, assign) BOOL forceSSL3;
@property (nonatomic, assign) BOOL noBase64;
@property (nonatomic, assign) BOOL checkCert;
@property (nonatomic, retain) NSString* hbciVersion;
@property (nonatomic, retain) NSNumber* tanMethodNumber;
@property (nonatomic, copy) NSString* tanMethodDescription;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *bankCode;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *customerId;
@property (nonatomic, copy) NSString *mediumId;
@property (nonatomic, copy) NSString *bankURL;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *port;
@property (nonatomic, copy) NSString *chipCardId;

-(BOOL)isEqual: (User*)obj;

@end
