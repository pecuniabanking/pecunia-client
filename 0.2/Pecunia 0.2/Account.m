//
//  Account.m
//  MacBanking
//
//  Created by Frank Emminghaus on 06.09.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Account.h"
#import "Transaction.h"
#import "AccountInfo.h"

@implementation Account


-(id)initWithAB: (const AB_ACCOUNT*)acc
{
	const char* c;
	
	[super init ];
	
	name			= [[NSString stringWithUTF8String: (c = AB_Account_GetAccountName(acc)) ? c: ""] retain];
	accountNumber	= [[NSString stringWithUTF8String: (c = AB_Account_GetAccountNumber(acc)) ? c: ""] retain];
	bankName		= [[NSString stringWithUTF8String: (c = AB_Account_GetBankName(acc)) ? c: ""] retain];
	bankCode		= [[NSString stringWithUTF8String: (c = AB_Account_GetBankCode(acc)) ? c: ""] retain];
	ownerName		= [[NSString stringWithUTF8String: (c = AB_Account_GetOwnerName(acc)) ? c: ""] retain];
	country			= [[NSString stringWithUTF8String: (c = AB_Account_GetCountry(acc)) ? c: ""] retain];
	currency		= [[NSString stringWithUTF8String: (c = AB_Account_GetCurrency(acc)) ? c: ""] retain];
	
	uid  = AB_Account_GetUniqueId(acc);
	type = AB_Account_GetAccountType(acc);

	balance=0.00f;

	NSString		*path = [NSString stringWithFormat: @"AccInfo%u", uid ];
	AccountInfo		*info = [NSKeyedUnarchiver unarchiveObjectWithFile: path ];
	if(!info) transactions = [[NSMutableArray arrayWithCapacity: 10 ] retain ]; 
	else {
		transactions = [[info transactions ] retain ];
		balance = [info balance ];
		[currency release ];
		currency = [[info currency ] retain ];
	}
	
	return self;
}

-(BOOL)isEqual: (id)obj
{
	if(accountNumber == ((Account*)obj)->accountNumber && bankCode == ((Account*)obj)->bankCode) return YES;
	else return NO;
}

-(void)updateTransactions: (NSArray*)transactions_new
{
	NSArray		*sorted_new = [transactions_new sortedArrayUsingSelector: @selector(compareByDate:) ];
	NSArray		*sorted_old = [transactions sortedArrayUsingSelector: @selector(compareByDate:) ];
	Transaction *last_old = [sorted_old lastObject ];
	int			i, count;
	
	if(last_old == nil) {
		[transactions addObjectsFromArray: transactions_new ];
		return;
	}
	count = [sorted_new count ];
	if(count == 0) return;
	for(i=count-1; i>=0; i--) {
		Transaction* trans = [sorted_new objectAtIndex: i ];
		if([trans compareByDate: last_old ] == NSOrderedDescending) [transactions addObject: trans ];
		else return;
		
	}
}

-(void)saveContent
{
	NSString	*path = [NSString stringWithFormat: @"AccInfo%u", uid ];
	AccountInfo	*info = [[AccountInfo alloc ] initWithAccount: self ];
	
	[NSKeyedArchiver archiveRootObject: info toFile: path ];
	[info release ];
}



NSString* set(NSString* x)
{
	return [x copy];
}

-(void)setBankName: (NSString*)x
{
	[bankName release];
	bankName = [x copy];
}

-(void)setBankCode: (NSString*)x
{
    [bankCode release];
	bankCode = [x copy];
}

-(void)setAccountNumber: (NSString*)x
{
	[accountNumber release];
	accountNumber = [x copy];
}

-(void)setBalance: (double)x withCurrency: curr
{
	balance = x;
	[currency release ];
	currency = [curr copy ];
}

-(NSString*)bankName { return bankName; }
-(NSString*)bankCode { return bankCode; }
-(NSString*)accountNumber {	return accountNumber; }
-(NSString*)name { return name; }
-(NSString*)ownerName { return ownerName; }
-(NSString*)currency { return currency; }
-(NSString*)country { return country; }

-(double)balance { return balance; }
-(NSArray*)transactions { return transactions; }

-(void) dealloc
{
	[name release];
	[bankName release];
	[bankCode release];
	[accountNumber release];
	[ownerName release];
	[country release];
	[currency release];
	[transactions release ];
	[super dealloc ];
}



-(NSComparisonResult)compareByBank: (Account*)x
{
	return [bankCode compare: x->bankCode];
}

+(SEL)getCBBSelector
{
	return @selector(compareByBank:);
}

@end
