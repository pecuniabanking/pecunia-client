//
//  TanMethod.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.07.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TanMedium;
@class BankUser;

@interface TanMethod : NSManagedObject {
}

@property (nonatomic, strong) NSString  *identifier;
@property (nonatomic, strong) NSString  *inputInfo;
@property (nonatomic, strong) NSNumber  *maxTanLength;
@property (nonatomic, strong) NSString  *method;
@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSString  *needTanMedia;
@property (nonatomic, strong) NSString  *process;
@property (nonatomic, strong) NSString  *zkaMethodName;
@property (nonatomic, strong) NSString  *zkaMethodVersion;
@property (nonatomic, strong) TanMedium *preferredMedium;
@property (nonatomic, strong) BankUser  *user;

@end
