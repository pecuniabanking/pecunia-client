//
//  BankUser.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TanMedium;

@interface BankUser : NSManagedObject {

}

@property (nonatomic, retain) NSString * bankCode;
@property (nonatomic, retain) NSString * bankName;
@property (nonatomic, retain) NSString * bankURL;
@property (nonatomic, retain) NSNumber * checkCert;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * customerId;
@property (nonatomic, retain) NSString * hbciVersion;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * port;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSManagedObject * preferredTanMethod;
@property (nonatomic, retain) NSMutableSet* tanMedia;
@property (nonatomic, retain) NSMutableSet* tanMethods;

-(void)updateTanMethods:(NSArray*)methods;
-(void)updateTanMedia:(NSArray*)media;

@end
