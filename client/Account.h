//
//  Account.h
//  Client
//
//  Created by Frank Emminghaus on 22.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Account : NSObject {
	NSString	*name;
	NSString	*bankName;
	NSString	*bankCode;
	NSString	*accountNumber;
	NSString	*ownerName;
	NSString	*currency;
	NSString	*country;
	NSString	*iban;
	NSString	*bic;
	NSString	*userId;
	NSString	*customerId;
	NSString	*subNumber;
}

-(BOOL)isEqual: (id)obj;


@property (copy) NSString *name;
@property (copy) NSString *bankName;
@property (copy) NSString *bankCode;
@property (copy) NSString *accountNumber;
@property (copy) NSString *ownerName;
@property (copy) NSString *currency;
@property (copy) NSString *country;
@property (copy) NSString *iban;
@property (copy) NSString *bic;
@property (copy) NSString *userId;
@property (copy) NSString *customerId;
@property (copy) NSString *subNumber;


@end