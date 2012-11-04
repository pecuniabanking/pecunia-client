//
//  StandingOrder.h
//  Pecunia
//
//  Created by Frank Emminghaus on 21.11.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BankAccount;

typedef enum {
	stord_weekly,
	stord_monthly
} StandingOrderPeriod;

typedef enum {
	stord_create,
	stord_change,
	stord_delete
} StandingOrderAction;

@interface StandingOrder : NSManagedObject {
	unsigned int jobId;
}

-(NSString*)purpose;
-(void)setJobId: (unsigned int)jid;
-(unsigned int)jobId;

@property (nonatomic, strong) NSDate * changeDate;
@property (nonatomic, strong) NSString * currency;
@property (nonatomic, strong) NSNumber * cycle;
@property (nonatomic, strong) NSNumber * executionDay;
@property (nonatomic, strong) NSDate * firstExecDate;
@property (nonatomic, strong) NSNumber * toDelete;
@property (nonatomic, strong) NSNumber * isSent;
@property (nonatomic, strong) NSDate * lastExecDate;
@property (nonatomic, strong) NSDate * nextExecDate;
@property (nonatomic, strong) NSString * orderKey;
@property (nonatomic, strong) NSNumber * period;
@property (nonatomic, strong) NSString * purpose1;
@property (nonatomic, strong) NSString * purpose2;
@property (nonatomic, strong) NSString * purpose3;
@property (nonatomic, strong) NSString * purpose4;
@property (nonatomic, strong) NSString * remoteAccount;
@property (nonatomic, strong) NSString * remoteBankCode;
@property (nonatomic, strong) NSString * remoteBankName;
@property (nonatomic, strong) NSString * remoteName;
@property (nonatomic, strong) NSString * remoteSuffix;
@property (nonatomic, strong) NSNumber * status;
@property (nonatomic, strong) NSNumber * subType;
@property (nonatomic, strong) NSNumber * type;
@property (nonatomic, strong) NSNumber * isChanged;
@property (nonatomic, strong) NSDecimalNumber * value;
@property (nonatomic, strong) BankAccount * account;
@property (nonatomic, strong) NSString * localAccount;
@property (nonatomic, strong) NSString * localBankCode;

@end
