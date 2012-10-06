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

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * inputInfo;
@property (nonatomic, retain) NSNumber * maxTanLength;
@property (nonatomic, retain) NSString * method;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * needTanMedia;
@property (nonatomic, retain) NSString * process;
@property (nonatomic, retain) NSString * zkaMethodName;
@property (nonatomic, retain) NSString * zkaMethodVersion;
@property (nonatomic, retain) TanMedium * preferredMedium;
@property (nonatomic, retain) BankUser * user;

@end

