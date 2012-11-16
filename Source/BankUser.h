//
//  BankUser.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SigningOption.h"

@class TanMedium;
@class TanMethod;

@interface BankUser : NSManagedObject {
    BOOL    isRegistered;
}

@property (nonatomic, strong) NSString * bankCode;
@property (nonatomic, strong) NSString * bankName;
@property (nonatomic, strong) NSString * bankURL;
@property (nonatomic, strong) NSNumber * checkCert;
@property (nonatomic, strong) NSNumber * noBase64;
@property (nonatomic, strong) NSNumber * tanMediaFetched;
@property (nonatomic, strong) NSString * country;
@property (nonatomic, strong) NSString * customerId;
@property (nonatomic, strong) NSString * hbciVersion;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * port;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * chipCardId;
@property (nonatomic, strong) TanMethod * preferredTanMethod;
@property (nonatomic, strong) NSMutableSet* tanMedia;
@property (nonatomic, strong) NSMutableSet* tanMethods;
@property (nonatomic, strong) NSNumber *ddvPortIdx;
@property (nonatomic, strong) NSNumber *ddvReaderIdx;
@property (nonatomic, strong) NSNumber *secMethod;

@property (nonatomic, assign) BOOL isRegistered;

-(void)updateTanMethods:(NSArray*)methods;
-(void)updateTanMedia:(NSArray*)media;
-(NSArray*)getSigningOptions;
-(void)setpreferredSigningOption:(SigningOption*)option;
-(SigningOption*)preferredSigningOption;
-(int)getpreferredSigningOptionIdx;

+(NSArray*)allUsers;
+(BankUser*)userWithId:(NSString*)userId bankCode:(NSString*)bankCode;

@end
