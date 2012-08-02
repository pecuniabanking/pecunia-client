//
//  Account.m
//  Client
//
//  Created by Frank Emminghaus on 22.11.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "Account.h"


@implementation Account

@synthesize name;
@synthesize bankName;
@synthesize bankCode;
@synthesize accountNumber;
@synthesize ownerName;
@synthesize currency;
@synthesize country;
@synthesize iban;
@synthesize bic;
@synthesize userId;
@synthesize customerId;
@synthesize subNumber;
@synthesize type;

@synthesize collTransfer;
@synthesize substInternalTransfers;

-(void)dealloc
{
	[name release ];
	[bankName release ];
	[bankCode release ];
	[accountNumber release ];
	[ownerName release ];
	[currency release ];
	[country release ];
	[iban release ];
	[bic release ];
	[userId release ];
	[customerId release ];
	[subNumber release ];
    [type release ];
	[super dealloc ];
}

-(BOOL)isEqual: (id)obj
{
	if([accountNumber isEqual: ((Account*)obj)->accountNumber ] && [bankCode isEqual: ((Account*)obj)->bankCode ]) {
        if ((subNumber == nil && ((Account*)obj)->subNumber == nil) || [subNumber isEqual: ((Account*)obj)->subNumber ]) {
            return YES;
        }
    }
    return NO;
}


@end
