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


@end

@interface StandingOrder (CoreDataGeneratedAccessors)
@property (nonatomic, retain) NSDate * changeDate;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSNumber * cycle;
@property (nonatomic, retain) NSNumber * executionDay;
@property (nonatomic, retain) NSDate * firstExecDate;
@property (nonatomic, retain) NSNumber * isDeleted;
@property (nonatomic, retain) NSNumber * isSent;
@property (nonatomic, retain) NSDate * lastExecDate;
@property (nonatomic, retain) NSDate * nextExecDate;
@property (nonatomic, retain) NSString * orderKey;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSString * purpose1;
@property (nonatomic, retain) NSString * purpose2;
@property (nonatomic, retain) NSString * purpose3;
@property (nonatomic, retain) NSString * purpose4;
@property (nonatomic, retain) NSString * remoteAccount;
@property (nonatomic, retain) NSString * remoteBankCode;
@property (nonatomic, retain) NSString * remoteBankName;
@property (nonatomic, retain) NSString * remoteName;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * subType;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * isChanged;
@property (nonatomic, retain) NSDecimalNumber * value;
@property (nonatomic, retain) BankAccount * account;

@end
