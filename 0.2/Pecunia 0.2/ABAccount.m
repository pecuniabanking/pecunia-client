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

-(id)init
{
	self = [super init ];
	if(self == nil) return self;
	abAcc = NULL;
	return self;
}

-(id)initWithAB: (const AB_ACCOUNT*)acc
{
	const char	*c;
	AB_JOB		*j;
	int			res;
	
	[super init ];
	
	self.name			= [NSString stringWithUTF8String: (c = AB_Account_GetAccountName(acc)) ? c: ""];
	self.accountNumber	= [NSString stringWithUTF8String: (c = AB_Account_GetAccountNumber(acc)) ? c: ""];
	self.bankName		= [NSString stringWithUTF8String: (c = AB_Account_GetBankName(acc)) ? c: ""];
	self.bankCode		= [NSString stringWithUTF8String: (c = AB_Account_GetBankCode(acc)) ? c: ""];
	self.ownerName		= [NSString stringWithUTF8String: (c = AB_Account_GetOwnerName(acc)) ? c: ""];
	self.country		= [NSString stringWithUTF8String: (c = AB_Account_GetCountry(acc)) ? c: ""];
	self.currency		= [NSString stringWithUTF8String: (c = AB_Account_GetCurrency(acc)) ? c: ""];
	self.iban			= [NSString stringWithUTF8String: (c = AB_Account_GetIBAN(acc)) ? c: ""];
	self.bic			= [NSString stringWithUTF8String: (c = AB_Account_GetBIC(acc)) ? c: ""];
	
	c = AH_Account_GetSuffix(acc);
	
	uid  = AB_Account_GetUniqueId(acc);
	type = AB_Account_GetAccountType(acc);

	uint32_t flags = AH_Account_GetFlags(acc);
	if(flags & AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER) collTransfer = NO; else collTransfer = YES;

	abAcc = (AB_ACCOUNT*)acc;

	j = (AB_JOB*)AB_JobInternalTransfer_new(abAcc);
	res = AB_Job_CheckAvailability(j);
	if(res) substInternalTransfers = YES; else substInternalTransfers = NO;
	AB_Job_free(j);
	return self;
}

-(void)createAB: (AB_ACCOUNT*)acc
{
	AB_Account_SetAccountName(acc, [name UTF8String ]);
	AB_Account_SetAccountNumber(acc, [accountNumber UTF8String ]);
	AB_Account_SetBankName(acc, [bankName UTF8String ]);
	AB_Account_SetBankCode(acc, [bankCode UTF8String ]);
	AB_Account_SetCountry(acc, [country UTF8String ]);
	AB_Account_SetOwnerName(acc, [ownerName UTF8String ]);
	AB_Account_SetCurrency(acc, [currency UTF8String ]);
	AB_Account_SetIBAN(acc, [iban UTF8String ]);
	AB_Account_SetBIC(acc, [bic UTF8String ]);
}

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

-(BOOL)isEqual: (id)obj
{
	if([accountNumber isEqual: ((ABAccount*)obj)->accountNumber ] && [bankCode isEqual: ((ABAccount*)obj)->bankCode ]) return YES;
	else return NO;
}

-(BOOL)isTransferSupportedForType: (TransferType)tt
{
	AB_JOB	*j;
	int		res;
	
	switch(tt) {
		case TransferTypeInternal:
			if(!substInternalTransfers) {
				j = (AB_JOB*)AB_JobInternalTransfer_new(abAcc);
				break;
			}
		case TransferTypeLocal: 
			j = (AB_JOB*)AB_JobSingleTransfer_new(abAcc);
			break;
		case TransferTypeEU:
			j = (AB_JOB*)AB_JobEuTransfer_new(abAcc);
			break;
		case TransferTypeDated:
			j = (AB_JOB*)AB_JobCreateDatedTransfer_new(abAcc);
			break;
	}
	res = AB_Job_CheckAvailability(j);
	if (res) {
		AB_Job_free(j);
		fprintf(stderr, "Job is not available (%d)\n", res);
		return NO;
	}
	AB_Job_free(j);
	return YES;
}

-(NSArray*)allowedCountries
{
	AB_JOB					*j;
	AB_EUTRANSFER_INFO_LIST	*cil;
	AB_EUTRANSFER_INFO		*ti;
	NSMutableDictionary		*_allowedCountries;

	if(allowedCountries) return allowedCountries;
	j = (AB_JOB*)AB_JobEuTransfer_new(abAcc);
	AB_Job_CheckAvailability(j);
	cil = AB_JobEuTransfer_GetCountryInfoList(j);
	if(!cil) return nil;
	ti = AB_EuTransferInfo_List_First(cil);
	if(ti) _allowedCountries = [NSMutableDictionary dictionaryWithCapacity: 20 ]; else return nil;
	NSDictionary* allCountries = [[ABController abController ] countries ];
	
	while(ti) {
		NSString	*key = [NSString stringWithUTF8String: AB_EuTransferInfo_GetCountryCode(ti) ];
		[_allowedCountries setValue: [[allCountries valueForKey: key ] name ] forKey: key ];
		ti = AB_EuTransferInfo_List_Next(ti);
	}
	allowedCountries = [_allowedCountries keysSortedByValueUsingSelector: @selector(caseInsensitiveCompare:) ];
	return [allowedCountries retain];
}


-(TransactionLimits*)limitsForType: (TransferType)tt country: (NSString*)ctry
{
	AB_JOB				*j;
	int					res;
	TransactionLimits	*limits;
	
	switch(tt) {
		case TransferTypeInternal:
			if(!substInternalTransfers) {
				j = (AB_JOB*)AB_JobInternalTransfer_new(abAcc);
				break;
			}
			case TransferTypeLocal: 
				j = (AB_JOB*)AB_JobSingleTransfer_new(abAcc);
				break;
			case TransferTypeEU:
				if(!ctry) return nil;
				j = (AB_JOB*)AB_JobEuTransfer_new(abAcc);
				break;
			case TransferTypeDated:
				j = (AB_JOB*)AB_JobCreateDatedTransfer_new(abAcc);
				break;
	}
	res = AB_Job_CheckAvailability(j);
	if (res) {
		AB_Job_free(j);
		fprintf(stderr, "Job is not available (%d)\n", res);
		return nil;
	}
	
	switch(tt) {
		case TransferTypeInternal: 
			if(!substInternalTransfers) {
				const AB_TRANSACTION_LIMITS* tl = (AB_TRANSACTION_LIMITS*)AB_JobInternalTransfer_GetFieldLimits (j);
				if(!tl) return nil;
				limits = [[TransactionLimits alloc ] initWithAB: tl];
				break;
			}
		case TransferTypeLocal: { 
			const AB_TRANSACTION_LIMITS* tl = (AB_TRANSACTION_LIMITS*)AB_JobSingleTransfer_GetFieldLimits(j);
			if(!tl) return nil;
			limits = [[TransactionLimits alloc ] initWithAB: tl];
			break;
		}
		case TransferTypeDated: {
			const AB_TRANSACTION_LIMITS* tl = (AB_TRANSACTION_LIMITS*)AB_JobCreateDatedTransfer_GetFieldLimits(j);
			if(!tl) return nil;
			limits = [[TransactionLimits alloc ] initWithAB: tl];
			break;
		}
		case TransferTypeEU: {
			const AB_EUTRANSFER_INFO* inf = (AB_EUTRANSFER_INFO*)AB_JobEuTransfer_FindCountryInfo (j, [ctry UTF8String ]);
			if(!inf) return nil;
			limits = [[TransactionLimits alloc ] initWithEUInfo: inf];
			break;
		}
	}
	AB_Job_free(j);
	return [limits autorelease ];
}


-(unsigned int)uid { return uid; }

-(AB_ACCOUNT*)abRef { return abAcc; }

-(BankAccount*)cdAccount { return cdAccount; }

-(void)setCDAccount: (BankAccount*)account
{
	cdAccount = account;
}

-(void)setRef: (const AB_ACCOUNT*)ref
{
	if(ref) abAcc = (AB_ACCOUNT*)ref;
}


-(void) dealloc
{
	if(cdAccount) [cdAccount release ];
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


	[super dealloc ];
}

-(int)removeUser: (User*)user
{
	AB_USER_LIST2			*ul = AB_Account_GetUsers(abAcc);
	AB_USER_LIST2_ITERATOR	*it;
	const AB_USER			*usr=0;
	int						res=0;
	
	if(!ul) return 0;
	uint32_t  uuid = [user uid ];
	
	/* List2's are traversed using iterators. An iterator is an object
		* which points to a single element of a list.
		* If the list is empty NULL is returned.
		*/
	it=AB_User_List2_First(ul);
	if (it) {
		/* this function returns a pointer to the element of the list to
		* which the iterator currently points to */
		usr = AB_User_List2Iterator_Data(it);
		while(usr) {
			if(uuid == AB_User_GetUniqueId(usr)) break;
			usr=AB_User_List2Iterator_Next(it);
		}
		/* the iterator must be freed after using it */
		AB_User_List2Iterator_free(it);
	}
	/* as discussed the list itself is only a container which has to be freed
		* after use. This explicitly does not free any of the elements in that
		* list, and it shouldn't because AqBanking still is the owner of the
		* accounts */
	
	if(usr) {
		AB_User_List2_Remove(ul, usr);
		AB_Account_SetUsers(abAcc, ul);
	}
	
	res = AB_User_List2_GetSize(ul);
	AB_User_List2_free(ul);
	return res;
}


-(NSComparisonResult)compareByBank: (ABAccount*)x
{
	return [bankCode compare: x->bankCode];
}

-(void)setFlags: (uint32_t)flags
{
	AH_Account_SetFlags(abAcc, flags);
}

-(uint32_t)flags
{
	return AH_Account_GetFlags(abAcc);
}


+(SEL)getCBBSelector
{
	return @selector(compareByBank:);
}

@end


