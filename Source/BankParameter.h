//
//  BankParameter.h
//  Pecunia
//
//  Created by Frank Emminghaus on 20.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankParameter : NSObject {
    NSDictionary *bpd;
    NSDictionary *upd;
    NSString     *bpd_raw;
    NSString     *upd_raw;
}

@property (nonatomic, strong) NSString     *bpd_raw;
@property (nonatomic, strong) NSString     *upd_raw;
@property (nonatomic, strong) NSDictionary *bpd;
@property (nonatomic, strong) NSDictionary *upd;

@end
