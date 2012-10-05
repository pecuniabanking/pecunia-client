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

@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *cardNumber;
@property (nonatomic, retain) NSString *cardSeqNumber;
@property (nonatomic, retain) NSNumber *cardType;
@property (nonatomic, retain) NSDate *validFrom;
@property (nonatomic, retain) NSDate *validTo;
@property (nonatomic, retain) NSString *tanListNumber;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *mobileNumber;
@property (nonatomic, retain) NSString *mobileNumberSecure;
@property (nonatomic, retain) NSNumber *freeTans;
@property (nonatomic, retain) NSDate *lastUse;
@property (nonatomic, retain) NSDate *activatedOn;
@property (nonatomic, retain) BankUser *user;

@end

