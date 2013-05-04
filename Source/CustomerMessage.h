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

@property (nonatomic, strong) NSString    *header;
@property (nonatomic, strong) NSNumber    *isSent;
@property (nonatomic, strong) NSString    *accountNumber;
@property (nonatomic, strong) NSString    *bankCode;
@property (nonatomic, strong) NSString    *message;
@property (nonatomic, strong) NSString    *receipient;
@property (nonatomic, strong) BankAccount *account;
@end
