//
//  BankInfo.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.01.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BankInfo : NSObject {
    NSString *country;
    NSString *branch;
    NSString *bankCode;
    NSString *bic;
    NSString *name;
    NSString *location;
    NSString *street;
    NSString *city;
    NSString *region;
    NSString *phone;
    NSString *email;
    NSString *host;
    NSString *pinTanURL;
    NSString *pinTanVersion;
    NSString *hbciVersion;
    NSString *website;
}

@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *branch;
@property (nonatomic, strong) NSString *bankCode;
@property (nonatomic, strong) NSString *bic;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *pinTanURL;
@property (nonatomic, strong) NSString *pinTanVersion;
@property (nonatomic, strong) NSString *hbciVersion;
@property (nonatomic, strong) NSString *website;

@end
