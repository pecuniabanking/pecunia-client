//
//  TanSigningOptions.h
//  Pecunia
//
//  Created by Frank Emminghaus on 07.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TanSigningOption : NSObject {
    NSString    *tanMethod;
    NSString    *tanMethodName;
    NSString    *tanMediumName;
    NSString    *mobileNumber;
}

@property (nonatomic, copy) NSString *tanMethod;
@property (nonatomic, copy) NSString *tanMethodName;
@property (nonatomic, copy) NSString *tanMediumName;
@property (nonatomic, copy) NSString *mobileNumber;

@end

