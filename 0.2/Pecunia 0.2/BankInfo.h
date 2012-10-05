//
//  BankInfo.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.01.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <aqbanking/bankinfo.h>

@interface BankInfo : NSObject {
	NSString	*country;
	NSString	*branch;
	NSString	*bankID;
	NSString	*bic;
	NSString	*name;
	NSString	*location;
	NSString	*street;
	NSString	*city;
	NSString	*region;
	NSString	*phone;
	NSString	*email;
	NSString	*website;
}

@property (copy) NSString *country;
@property (copy) NSString *branch;
@property (copy) NSString *bankID;
@property (copy) NSString *bic;
@property (copy) NSString *name;
@property (copy) NSString *location;
@property (copy) NSString *street;
@property (copy) NSString *city;
@property (copy) NSString *region;
@property (copy) NSString *phone;
@property (copy) NSString *email;
@property (copy) NSString *website;

-(id)initWithAB: (AB_BANKINFO*)bi;

@end
