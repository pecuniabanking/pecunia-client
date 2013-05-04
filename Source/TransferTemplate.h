//
//  TransferTemplate.h
//  Pecunia
//
//  Created by Frank Emminghaus on 26.09.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TransferTemplate : NSManagedObject {
}

- (NSString *)purpose;

@property (nonatomic, strong) NSString        *currency;
@property (nonatomic, strong) NSString        *name;
@property (nonatomic, strong) NSString        *purpose1;
@property (nonatomic, strong) NSString        *purpose2;
@property (nonatomic, strong) NSString        *purpose3;
@property (nonatomic, strong) NSString        *purpose4;
@property (nonatomic, strong) NSString        *remoteAccount;
@property (nonatomic, strong) NSString        *remoteBankCode;
@property (nonatomic, strong) NSString        *remoteBIC;
@property (nonatomic, strong) NSString        *remoteCountry;
@property (nonatomic, strong) NSString        *remoteIBAN;
@property (nonatomic, strong) NSString        *remoteName;
@property (nonatomic, strong) NSString        *remoteSuffix;
@property (nonatomic, strong) NSDecimalNumber *value;
@property (nonatomic, strong) NSNumber        *type;
@end
