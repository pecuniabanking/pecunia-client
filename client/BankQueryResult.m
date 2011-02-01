//
//  BankQueryResult.m
//  Pecunia
//
//  Created by Frank Emminghaus on 11.08.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "BankQueryResult.h"


@implementation BankQueryResult

@synthesize accountNumber;
@synthesize bankCode;
@synthesize currency;
@synthesize balance;
@synthesize statements;
@synthesize account;
@synthesize userId;
@synthesize standingOrders;
@synthesize isImport;


-(void)dealloc
{
	[accountNumber release ];
	[bankCode release ];
	[userId release ];
	[currency release ];
	[balance release ];
	[statements release ];
	[standingOrders release ];
	
	[super dealloc ];
}


@end
