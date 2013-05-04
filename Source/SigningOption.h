//
//  SigningOption.h
//  Pecunia
//
//  Created by Frank Emminghaus on 04.08.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    SecMethod_PinTan = 0,
    SecMethod_DDV
} SecurityMethod;

@interface SigningOption : NSObject {
    SecurityMethod secMethod;

    NSString *tanMethod;
    NSString *tanMethodName;
    NSString *tanMediumName;
    NSString *tanMediumCategory;
    NSString *mobileNumber;
    NSString *userId;
    NSString *userName;
    NSString *cardId;

}

@property (nonatomic, copy) NSString         *userId;
@property (nonatomic, copy) NSString         *userName;
@property (nonatomic, copy) NSString         *cardId;
@property (nonatomic, copy) NSString         *tanMethod;
@property (nonatomic, copy) NSString         *tanMethodName;
@property (nonatomic, copy) NSString         *tanMediumName;
@property (nonatomic, copy) NSString         *tanMediumCategory;
@property (nonatomic, copy) NSString         *mobileNumber;
@property (nonatomic, assign) SecurityMethod secMethod;


@end
