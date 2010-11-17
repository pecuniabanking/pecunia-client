//
//  Account.m
//  MacBanking
//
//  Created by Frank Emminghaus on 06.09.06.
//  Copyright 2006 Frank Emminghaus. All rights reserved.
//

#import "ABAccount.h"
#import "TransactionLimits.h"
#import "ABController.h"
#include <aqhbci/account.h>

@implementation ABAccount

@synthesize userId;
@synthesize customerId;
@synthesize substInternalTransfers;
@synthesize type;
@synthesize name;
@synthesize bankName;
@synthesize bankCode;
@synthesize accountNumber;
@synthesize ownerName;
@synthesize currency;
@synthesize country;
@synthesize iban;
@synthesize bic;
@synthesize collTransfer;
@synthesize uid;

-(id)init
{
	self = [super init ];
	if(self == nil) return self;
	return self;
}

// still needed?
/*
-(void)updateChanges
{
	if(abAcc == NULL) return;
	
	int rv = AB_Banking_BeginExclUseAccount([[ABController abController ] handle], abAcc);
	if (rv == 0) {
		AB_Account_SetAccountName(abAcc, [name UTF8String ]);
		AB_Account_SetOwnerName(abAcc, [ownerName UTF8String ]);
		AB_Account_SetIBAN(abAcc, [iban UTF8String ]);
		AB_Account_SetBIC(abAcc, [bic UTF8String ]);
		
		uint32_t flags = AH_Account_GetFlags(abAcc);
		if(!collTransfer) flags |= AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER;
		else flags = (0xFFFF ^ AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER) & flags;
		AH_Account_SetFlags(abAcc, flags);
		
		AB_Banking_EndExclUseAccount([[ABController abController ] handle], abAcc, NO);
	}
}
*/

-(BOOL)isEqual: (id)obj
{
	if([accountNumber isEqual: ((ABAccount*)obj)->accountNumber ] && [bankCode isEqual: ((ABAccount*)obj)->bankCode ]) return YES;
	else return NO;
}


-(void) dealloc
{
	[allowedCountries release ];
//	if(limits) [limits release ];
	[name release], name = nil;
	[bankName release], bankName = nil;
	[bankCode release], bankCode = nil;
	[accountNumber release], accountNumber = nil;
	[ownerName release], ownerName = nil;
	[currency release], currency = nil;
	[country release], country = nil;
	[iban release], iban = nil;
	[bic release], bic = nil;
	[userId release], userId = nil;
	[customerId release], customerId = nil;

	[super dealloc ];
}

-(NSComparisonResult)compareByBank: (ABAccount*)x
{
	return [bankCode compare: x->bankCode];
}


@end



