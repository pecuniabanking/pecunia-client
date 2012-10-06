//
//  BankUser.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SigningOption.h"

typedef enum {
    Reg_notchecked = 0,
    Reg_ok,
    Reg_failed
} RegisterResult;

@class TanMedium;
@class TanMethod;

@interface BankUser : NSManagedObject {
    RegisterResult regResult;
}

@property (nonatomic, retain) NSString * bankCode;
@property (nonatomic, retain) NSString * bankName;
@property (nonatomic, retain) NSString * bankURL;
@property (nonatomic, retain) NSNumber * checkCert;
@property (nonatomic, retain) NSNumber * noBase64;
@property (nonatomic, retain) NSNumber * tanMediaFetched;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * customerId;
@property (nonatomic, retain) NSString * hbciVersion;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * port;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * chipCardId;
@property (nonatomic, retain) TanMethod * preferredTanMethod;
@property (nonatomic, retain) NSMutableSet* tanMedia;
@property (nonatomic, retain) NSMutableSet* tanMethods;
@property (nonatomic, retain) NSNumber *ddvPortIdx;
@property (nonatomic, retain) NSNumber *ddvReaderIdx;
@property (nonatomic, retain) NSNumber *secMethod;

@property (nonatomic, assign) RegisterResult regResult;

-(void)updateTanMethods:(NSArray*)methods;
-(void)updateTanMedia:(NSArray*)media;
-(NSArray*)getSigningOptions;
-(void)setpreferredSigningOption:(SigningOption*)option;
-(SigningOption*)preferredSigningOption;
-(int)getpreferredSigningOptionIdx;

+(NSArray*)allUsers;
+(BankUser*)userWithId:(NSString*)userId bankCode:(NSString*)bankCode;

@end
