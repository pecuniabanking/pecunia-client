//
//  Transaction.m
//  MacBanking
//
//  Created by Frank Emminghaus on 24.03.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Transaction.h"


@implementation Transaction
-(id)initWithAB: (const AB_TRANSACTION*) t
{
	NSString*			s;
	const char*			c;
	NSMutableArray*		sl;
	const AB_VALUE*		val;
	const GWEN_TIME*	d;
	NSCalendarDate*		date;
	NSNumber*			num;
	
	[super init ];
	Infos = [[NSMutableDictionary dictionaryWithCapacity: 30 ] retain];
	
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalCountry(t)) ? c: ""];
	[Infos setObject: s forKey: _LocalCountry ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBankCode(t)) ? c: ""];
	[Infos setObject: s forKey: _LocalBankCode ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBranchId(t)) ? c: ""];
	[Infos setObject: s forKey: _LocalBranch ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalAccountNumber(t)) ? c: ""];
	[Infos setObject: s forKey: _LocalAccount ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalSuffix(t)) ? c: ""];
	[Infos setObject: s forKey: _LocalSuffix ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalName(t)) ? c: ""];
	[Infos setObject: s forKey: _LocalName ];
	
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteCountry(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteCountry ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankName(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteBankName ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankLocation(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteBankLocation ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankCode(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteBankCode ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBranchId(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteBranch ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteAccountNumber(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteAccount ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteSuffix(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteSuffix ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteIban(t)) ? c: ""];
	[Infos setObject: s forKey: _RemoteIban ];
	
	sl = [self stringsFromAB: AB_Transaction_GetRemoteName(t)];
	[Infos setObject: sl forKey: _RemoteNames ];
	
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetTransactionKey(t)) ? c: ""];
	[Infos setObject: s forKey: _TransactionKey ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetCustomerReference(t)) ? c: ""];
	[Infos setObject: s forKey: _CustomerReference ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetBankReference(t)) ? c: ""];
	[Infos setObject: s forKey: _BankReference ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetTransactionText(t)) ? c: ""];
	[Infos setObject: s forKey: _TransactionText ];
	s = [NSString stringWithUTF8String: (c = AB_Transaction_GetPrimanota(t)) ? c: ""];
	[Infos setObject: s forKey: _PrimaNota ];
	
	sl = [self stringsFromAB: AB_Transaction_GetPurpose(t)];
	[Infos setObject: sl forKey: _Purpose ];
	if( [sl count ] > 0 ) Purpose = [sl objectAtIndex: 0 ]; else Purpose = @"";
	
	sl = [self stringsFromAB: AB_Transaction_GetCategory(t)];
	[Infos setObject: sl forKey: _Category ];

	num = [NSNumber numberWithInt: AB_Transaction_GetTextKey(t) ];
	[Infos setObject: num forKey: _TextKey ];
	
	num = [NSNumber numberWithInt: AB_Transaction_GetTransactionCode(t) ];
	[Infos setObject: num forKey: _TransactionCode ];
	
	val = AB_Transaction_GetValue(t);
//	num = [NSNumber numberWithDouble: AB_Value_GetValue(val) ];
	[Infos setObject: num forKey: _Value ];
	
	s = [NSString stringWithUTF8String: (c = AB_Value_GetCurrency(val)) ? c: ""];
	[Infos setObject: s forKey: _Currency ];
	
	d = AB_Transaction_GetDate(t);
	date = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	[Infos setObject: date forKey: _Date ];
	
	d = AB_Transaction_GetValutaDate(t);
	date = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	[Infos setObject: date forKey: _ValutaDate ];
	
	return self;
}

-(NSMutableArray*)stringsFromAB: (const GWEN_STRINGLIST*)sl
{
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5 ];
	const char*	c;
	NSString*	s;
	GWEN_STRINGLISTENTRY* sle; 

	if(!sl) return result;
	sle = GWEN_StringList_FirstEntry(sl);
	while(sle) {
		s = [NSString stringWithUTF8String: (c = GWEN_StringListEntry_Data(sle)) ? c: ""];
	    [result addObject: s ];
		sle = GWEN_StringListEntry_Next(sle);
	}
	return result;
}

-(void)encodeWithCoder: (NSCoder*) coder
{
	[coder encodeObject: Infos forKey: _Infos ];
}

-(id)initWithCoder: (NSCoder*)coder
{
	NSArray* sl;
	
	[super init ];
	Infos = [coder decodeObjectForKey: _Infos ];
	if(Infos != NULL) {
		[Infos retain ];
		sl = [Infos objectForKey: _Purpose ];
		if( sl != NULL && [sl count ] > 0) Purpose = [sl objectAtIndex: 0 ]; else Purpose = nil;
	}
	return self;
}

-(NSString*)Purpose
{
	return Purpose;
}

-(NSString*)fullPurpose
{
	int					i;
	NSMutableString		*purp = [NSMutableString stringWithCapacity: 150 ];
	NSArray				*sl = [Infos objectForKey: _Purpose ];
	
	for(i=0; i<[sl count ]; i++)  
		[purp appendFormat: @"%@\n", [sl objectAtIndex: i ] ];
	return purp;
}

-(NSString*)remoteName
{
	NSArray* rNames = [Infos objectForKey: _RemoteNames ];
	if([rNames count ] > 0) return [rNames objectAtIndex: 0 ];
	else return @"";
}

-(BOOL)equalDate: (Transaction*)transaction
{
	return [[Infos objectForKey: _Date ] isEqual: [transaction->Infos objectForKey: _Date ] ];
}

-(NSComparisonResult)compareByDate: (Transaction*)transaction
{
	return [[self date ] compare: [transaction date ] ];
}

-(NSDate*)date { return [Infos objectForKey: _Date ]; }
-(NSDictionary*)infos { return Infos; }

-(void)dealloc
{
	[Infos release ];
	[super dealloc ];
}
@end
