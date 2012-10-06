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
	NSString    *website;
}

@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) NSString *branch;
@property (nonatomic, retain) NSString *bankCode;
@property (nonatomic, retain) NSString *bic;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *street;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *region;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *pinTanURL;
@property (nonatomic, retain) NSString *pinTanVersion;
@property (nonatomic, retain) NSString *website;

//-(id)initWithAB: (AB_BANKINFO*)bi;

@end
