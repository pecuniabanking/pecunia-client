//
//  BankSetupInfo.h
//  Pecunia
//
//  Created by Frank Emminghaus on 03.03.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankSetupInfo : NSObject {
    NSString    *info_userid;
    NSString    *info_customerid;
    NSNumber    *pinlen_min;
    NSNumber    *pinlen_max;
    NSNumber    *tanlen_max;
}

@property (nonatomic, retain) NSString *info_userid;
@property (nonatomic, retain) NSString *info_customerid;
@property (nonatomic, retain) NSNumber *pinlen_min;
@property (nonatomic, retain) NSNumber *pinlen_max;
@property (nonatomic, retain) NSNumber *tanlen_max;

@end

