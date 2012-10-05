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
}

@property (nonatomic, copy) NSDictionary *bpd;
@property (nonatomic, copy) NSDictionary *upd;

@end

