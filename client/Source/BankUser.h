//
//  BankUser.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TanMedium;
@class TanMethod;

@interface BankUser : NSManagedObject {

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
@property (nonatomic, retain) TanMethod * preferredTanMethod;
@property (nonatomic, retain) NSMutableSet* tanMedia;
@property (nonatomic, retain) NSMutableSet* tanMethods;

-(void)updateTanMethods:(NSArray*)methods;
-(void)updateTanMedia:(NSArray*)media;
-(NSArray*)getTanSigningOptions;

+(NSArray*)allUsers;
+(BankUser*)userWithId:(NSString*)userId bankCode:(NSString*)bankCode;

@end
