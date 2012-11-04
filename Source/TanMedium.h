//
//  TanMedium.h
//  Pecunia
//
//  Created by Frank Emminghaus on 05.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankUser;

@interface TanMedium : NSManagedObject {
    
}

@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *cardNumber;
@property (nonatomic, strong) NSString *cardSeqNumber;
@property (nonatomic, strong) NSNumber *cardType;
@property (nonatomic, strong) NSDate *validFrom;
@property (nonatomic, strong) NSDate *validTo;
@property (nonatomic, strong) NSString *tanListNumber;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *mobileNumber;
@property (nonatomic, strong) NSString *mobileNumberSecure;
@property (nonatomic, strong) NSNumber *freeTans;
@property (nonatomic, strong) NSDate *lastUse;
@property (nonatomic, strong) NSDate *activatedOn;
@property (nonatomic, strong) BankUser *user;

@end

