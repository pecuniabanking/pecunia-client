//
//  CustomerMessage.h
//  Pecunia
//
//  Created by Frank Emminghaus on 20.01.12.
//  Copyright 2012 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;

@interface CustomerMessage : NSManagedObject {

}

@property (nonatomic, retain) NSString * header;
@property (nonatomic, retain) NSNumber * isSent;
@property (nonatomic, retain) NSString * accountNumber;
@property (nonatomic, retain) NSString * bankCode;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * receipient;
@property (nonatomic, retain) BankAccount * account;
@end
