//
//  BankParameter.h
//  Pecunia
//
//  Created by Frank Emminghaus on 20.08.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BankParameter : NSObject {
	NSDictionary		*bpd;
	NSDictionary		*upd;
    NSString            *bpd_raw;
    NSString            *upd_raw;
}

@property (nonatomic, retain) NSString *bpd_raw;
@property (nonatomic, retain) NSString *upd_raw;
@property (nonatomic, retain) NSDictionary *bpd;
@property (nonatomic, retain) NSDictionary *upd;

@end


