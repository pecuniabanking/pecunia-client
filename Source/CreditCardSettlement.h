//
//  CreditCardSettlement.h
//  Pecunia
//
//  Created by Frank Emminghaus on 27.01.13.
//  Copyright (c) 2013 Frank Emminghaus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BankAccount;

@interface CreditCardSettlement : NSManagedObject

@property (nonatomic, strong) NSDecimalNumber * endBalance;
@property (nonatomic, strong) NSString * ccNumber;
@property (nonatomic, strong) NSDecimalNumber * startBalance;
@property (nonatomic, strong) NSDate *settleDate;
@property (nonatomic, strong) NSDecimalNumber * value;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) NSString * settleID;
@property (nonatomic, strong) NSDate *nextSettleDate;
@property (nonatomic, strong) NSString * currency;
@property (nonatomic, strong) NSDate *firstReceive;
@property (nonatomic, strong) NSData * document;
@property (nonatomic, strong) NSData * ackCode;
@property (nonatomic, strong) BankAccount *account;

@end
