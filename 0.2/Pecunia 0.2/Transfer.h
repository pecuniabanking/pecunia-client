//
//  Transfer.h
//  MacBanking
//
//  Created by Frank Emminghaus on 21.07.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TransactionLimits;

typedef enum {
	TransferTypeLocal=0,
	TransferTypeEU,
	TransferTypeDated,
	TransferTypeInternal
} TransferType;

@interface Transfer : NSManagedObject {
	unsigned int jobId;
}

-(NSString*)purpose;
-(void)copyFromTemplate: (Transfer*)t withLimits:(TransactionLimits*)limits;
-(void)setJobId: (unsigned int)jid;
-(unsigned int)jobId;

@end
