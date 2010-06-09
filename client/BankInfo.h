//
//  BankInfo.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.01.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BankInfo : NSObject {
	NSString	*country;
	NSString	*branch;
	NSString	*bankCode;
	NSString	*bic;
	NSString	*name;
	NSString	*location;
	NSString	*street;
	NSString	*city;
	NSString	*region;
	NSString	*phone;
	NSString	*email;
	NSString	*host;
	NSString	*pinTanURL;
	NSString	*pinTanVersion;
	
}

@property (copy) NSString *country;
@property (copy) NSString *branch;
@property (copy) NSString *bankCode;
@property (copy) NSString *bic;
@property (copy) NSString *name;
@property (copy) NSString *location;
@property (copy) NSString *street;
@property (copy) NSString *city;
@property (copy) NSString *region;
@property (copy) NSString *phone;
@property (copy) NSString *email;
@property (copy) NSString *host;
@property (copy) NSString *pinTanURL;
@property (copy) NSString *pinTanVersion;

//-(id)initWithAB: (AB_BANKINFO*)bi;

@end
