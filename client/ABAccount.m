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
	
	name			= [[NSString stringWithUTF8String: (c = AB_Account_GetAccountName(acc)) ? c: ""] retain];
	accountNumber	= [[NSString stringWithUTF8String: (c = AB_Account_GetAccountNumber(acc)) ? c: ""] retain];
	bankName		= [[NSString stringWithUTF8String: (c = AB_Account_GetBankName(acc)) ? c: ""] retain];
	bankCode		= [[NSString stringWithUTF8String: (c = AB_Account_GetBankCode(acc)) ? c: ""] retain];
	ownerName		= [[NSString stringWithUTF8String: (c = AB_Account_GetOwnerName(acc)) ? c: ""] retain];
	country			= [[NSString stringWithUTF8String: (c = AB_Account_GetCountry(acc)) ? c: ""] retain];
	currency		= [[NSString stringWithUTF8String: (c = AB_Account_GetCurrency(acc)) ? c: ""] retain];
	iban			= [[NSString stringWithUTF8String: (c = AB_Account_GetIBAN(acc)) ? c: ""] retain];
	bic				= [[NSString stringWithUTF8String: (c = AB_Account_GetBIC(acc)) ? c: ""] retain];
	
	uid  = AB_Account_GetUniqueId(acc);
	type = AB_Account_GetAccountType(acc);

	uint32_t flags = AH_Account_GetFlags(acc);
	if(flags & AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER) collTransfer = NO; else collTransfer = YES;

	abAcc = (AB_ACCOUNT*)acc;

	j = (AB_JOB*)AB_JobInternalTransfer_new(abAcc);
	res = AB_Job_CheckAvailability(j, 0);
	if(res) substInternalTransfers = YES; else substInternalTransfers = NO;
	AB_Job_free(j);
	return self;
}

-(void)initAB: (AB_ACCOUNT*)acc
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
	AB_Account_SetAccountName(abAcc, [name UTF8String ]);
	AB_Account_SetOwnerName(abAcc, [ownerName UTF8String ]);
	AB_Account_SetIBAN(abAcc, [iban UTF8String ]);
	AB_Account_SetBIC(abAcc, [bic UTF8String ]);
}

-(BOOL)isEqual: (id)obj
{
	if([accountNumber isEqual: ((ABAccount*)obj)->accountNumber ] && [bankCode isEqual: ((ABAccount*)obj)->bankCode ]) return YES;
	else return NO;
}

// Accessor methods
- (BOOL)substInternalTransfers { return substInternalTransfers; }
- (AB_ACCOUNT_TYPE)type { return type; }

- (void)setType:(AB_ACCOUNT_TYPE)value {
    if (type != value) {
		type = value;
		if(abAcc) AB_Account_SetAccountType(abAcc, type);
    }
}

- (NSString *)name {
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)value {
    if (name != value) {
        [name release];
        name = [value copy];
		if(abAcc) AB_Account_SetAccountName(abAcc, [value UTF8String ]);
    }
}

- (NSString *)bankName {
    return [[bankName retain] autorelease];
}

- (void)setBankName:(NSString *)value {
    if (bankName != value) {
        [bankName release];
        bankName = [value copy];
		if(abAcc) AB_Account_SetBankName(abAcc, [value UTF8String ]);
    }
}

- (NSString *)bankCode {
    return [[bankCode retain] autorelease];
}

- (void)setBankCode:(NSString *)value {
    if (bankCode != value) {
        [bankCode release];
        bankCode = [value copy];
		if(abAcc) AB_Account_SetBankCode(abAcc, [value UTF8String ]);
    }
}

- (NSString *)accountNumber {
    return [[accountNumber retain] autorelease];
}

- (void)setAccountNumber:(NSString *)value {
    if (accountNumber != value) {
        [accountNumber release];
        accountNumber = [value copy];
		if(abAcc) AB_Account_SetAccountNumber(abAcc, [value UTF8String ]);
    }
}

- (NSString *)ownerName {
    return [[ownerName retain] autorelease];
}

- (void)setOwnerName:(NSString *)value {
    if (ownerName != value) {
        [ownerName release];
        ownerName = [value copy];
		if(abAcc) AB_Account_SetOwnerName(abAcc, [value UTF8String ]);
    }
}

- (NSString *)currency {
    return [[currency retain] autorelease];
}

- (void)setCurrency:(NSString *)value {
    if (currency != value) {
        [currency release];
        currency = [value copy];
		if(abAcc) AB_Account_SetCurrency(abAcc, [value UTF8String ]);
    }
}

- (NSString *)country {
    return [[country retain] autorelease];
}

- (void)setCountry:(NSString *)value {
    if (country != value) {
        [country release];
        country = [value copy];
		if(abAcc) AB_Account_SetCountry(abAcc, [value UTF8String ]);
    }
}

- (NSString *)iban {
    return [[iban retain] autorelease];
}

- (void)setIban:(NSString *)value {
    if (iban != value) {
        [iban release];
        iban = [value copy];
		if(abAcc) AB_Account_SetIBAN(abAcc, [value UTF8String ]);
    }
}

- (NSString *)bic {
    return [[bic retain] autorelease];
}

- (void)setBic:(NSString *)value {
    if (bic != value) {
        [bic release];
        bic = [value copy];
		if(abAcc) AB_Account_SetBIC(abAcc, [value UTF8String ]);
    }
}

- (BOOL)collTransfer {
    return collTransfer;
}

- (void)setCollTransfer:(BOOL)value {
    if (collTransfer != value) {
        collTransfer = value;
		if(abAcc) {
			uint32_t flags = AH_Account_GetFlags(abAcc);
			if(value == TRUE) flags |= AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER;
			else flags = (0xFFFF ^ AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER) & flags;
			AH_Account_SetFlags(abAcc, flags);
		}
    }
}
// End access methods


NSString* set(NSString* x)
{
	return [x copy];
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
	res = AB_Job_CheckAvailability(j, 0);
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
	AB_Job_CheckAvailability(j, 0);
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
	res = AB_Job_CheckAvailability(j, 0);
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
	[name release];
	[bankName release];
	[bankCode release];
	[accountNumber release];
	[ownerName release];
	[country release];
	[currency release];
	[iban release ];
	[bic release ];
	if(cdAccount) [cdAccount release ];
	[allowedCountries release ];
//	if(limits) [limits release ];
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
