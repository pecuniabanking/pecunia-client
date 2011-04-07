//
//  ABConversion.m
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.10.
//  Copyright 2010 Frank Emminghaus. All rights reserved.
//

#import "ABConversion.h"
#import "ABUser.h"
#import <aqhbci/user.h>
#import <aqhbci/account.h>
#import "TanMethod.h"
#import "BankInfo.h"
#import "Country.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "ABAccount.h"
#import "TransactionLimits.h"
#import "Transfer.h"
#import "HBCIClient.h"
#import "StandingOrder.h"
#import "ShortDate.h"

static NSDecimalNumber *hundred=nil;

ABUser *convertUser(AB_USER *usr)
{
	ABUser *user = [[[ABUser alloc ] init ] autorelease ];
	const char* c;

	if (usr == NULL) return nil;
	user.name		= [NSString stringWithUTF8String: (c = AB_User_GetUserName(usr)) ? c: ""];
	user.userId		= [NSString stringWithUTF8String: (c = AB_User_GetUserId(usr)) ? c: ""];
	user.customerId	= [NSString stringWithUTF8String: (c = AB_User_GetCustomerId(usr)) ? c: ""];
	user.bankCode	= [NSString stringWithUTF8String: (c = AB_User_GetBankCode(usr)) ? c: ""];
	user.country	= [NSString stringWithUTF8String: (c = AB_User_GetCountry(usr)) ? c: ""];
	user.uid		= AB_User_GetUniqueId(usr);
	user.mediumId	= [NSString stringWithUTF8String: (c = AH_User_GetTanMediumId(usr)) ? c: ""];
	user.hbciVersion = AH_User_GetHbciVersion(usr);
	
    const GWEN_URL *url = AH_User_GetServerUrl(usr);
	GWEN_BUFFER *buf = GWEN_Buffer_new(NULL, 200, 0, 0);
	GWEN_Url_toString(url, buf);
	
	user.bankURL = [NSString stringWithUTF8String: (c = GWEN_Buffer_GetStart(buf)) ? c: ""];
	
	uint32_t flags = AH_User_GetFlags(usr);
	if(flags & AH_USER_FLAGS_FORCE_SSL3) user.forceSSL3 = TRUE;
	if(flags & AH_USER_FLAGS_NO_BASE64) user.noBase64 = TRUE;

	// Tan Methods
	NSMutableArray *tanMethodList = [[NSMutableArray arrayWithCapacity: 10 ] retain ];

	//tanMethodList
	const AH_TAN_METHOD_LIST *ml = AH_User_GetTanMethodDescriptions(usr);
	if(ml) {
		int n = AH_User_GetTanMethodCount(usr);
		if(n>0) {
			const int *mList = AH_User_GetTanMethodList(usr);
			
			const AH_TAN_METHOD *tm = AH_TanMethod_List_First(ml);
			while(tm) {
				int function = AH_TanMethod_GetFunction(tm);
				int i;
				for(i=0; i<n;i++) {
					if(mList[i] == function) {
						TanMethod *tanM = [[[TanMethod alloc ] init ] autorelease ];
						tanM.function = function;
						tanM.description = [NSString stringWithUTF8String: (c = AH_TanMethod_GetMethodName(tm)) ? c: ""];
						[tanMethodList addObject: tanM ];
						break;
					}
				}
				tm = AH_TanMethod_List_Next(tm);
			}
		}
	}
	user.tanMethodNumber = AH_User_GetSelectedTanMethod(usr);	
	if([tanMethodList count ] == 0) {
		TanMethod *tanM = [[TanMethod alloc ] initDefault: user.tanMethodNumber ];
		[tanMethodList addObject: tanM ];
	}
	user.tanMethodList = tanMethodList;
	return user;
	
}

BankInfo *convertBankInfo(AB_BANKINFO *bi)
{
	const char* c;
	
	BankInfo *info = [[[BankInfo alloc ] init ] autorelease ];
	
	info.name		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetBankName(bi)) ? c: ""];
	info.country	= [NSString stringWithUTF8String: (c = AB_BankInfo_GetCountry(bi)) ? c: ""];
	info.branch		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetBranchId(bi)) ? c: ""];
	info.bankCode	= [NSString stringWithUTF8String: (c = AB_BankInfo_GetBankId(bi)) ? c: ""];
	info.bic		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetBic(bi)) ? c: ""];
	info.location	= [NSString stringWithUTF8String: (c = AB_BankInfo_GetLocation(bi)) ? c: ""];
	info.street		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetStreet(bi)) ? c: ""];
	info.city		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetCity(bi)) ? c: ""];
	info.region		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetRegion(bi)) ? c: ""];
	info.phone		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetPhone(bi)) ? c: ""];
	info.email		= [NSString stringWithUTF8String: (c = AB_BankInfo_GetEmail(bi)) ? c: ""];
	info.website	= [NSString stringWithUTF8String: (c = AB_BankInfo_GetWebsite(bi)) ? c: ""];
	
	return info;
}

Country *convertCountry(const AB_COUNTRY* cnty)
{
	const char* c;
	Country *country = [[[Country alloc ] init ] autorelease ];
	
	country.name =		[NSString stringWithUTF8String: (c = AB_Country_GetLocalName(cnty)) ? c: ""];
	country.code =		[NSString stringWithUTF8String: (c = AB_Country_GetCode(cnty)) ? c: ""];
	country.currency =	[NSString stringWithUTF8String: (c = AB_Country_GetCurrencyCode(cnty)) ? c: ""];
	return country;
}

void convertToAccount(BankAccount *account, AB_ACCOUNT *acc)
{
	AB_Account_SetAccountName(acc, [account.name UTF8String ]);
	AB_Account_SetAccountNumber(acc, [account.accountNumber UTF8String ]);
	AB_Account_SetBankName(acc, [account.bankName UTF8String ]);
	AB_Account_SetBankCode(acc, [account.bankCode UTF8String ]);
	AB_Account_SetCountry(acc, [account.country UTF8String ]);
	AB_Account_SetOwnerName(acc, [account.owner UTF8String ]);
	AB_Account_SetCurrency(acc, [account.currency UTF8String ]);
	AB_Account_SetIBAN(acc, [account.iban UTF8String ]);
	AB_Account_SetBIC(acc, [account.bic UTF8String ]);
}

NSString *convertStringListToString(const GWEN_STRINGLIST* sl, NSString *separator)
{
	NSMutableString* result = [NSMutableString stringWithCapacity: 100 ];
	const char*	c;
	NSString*	s;
	GWEN_STRINGLISTENTRY* sle; 
	
	if(!sl) return result;
	sle = GWEN_StringList_FirstEntry(sl);
	while(sle) {
		s = [NSString stringWithUTF8String: (c = GWEN_StringListEntry_Data(sle)) ? c: ""];
	    [result appendString:s ];
		sle = GWEN_StringListEntry_Next(sle);
		if(sle) [result appendString: separator ];
	}
	return result;
}

NSArray *convertStringList(const GWEN_STRINGLIST* sl)
{
	NSMutableArray *strings = [NSMutableArray arrayWithCapacity:5 ];
	
	if(sl) {
		const char*	c;
		NSString*	s;
		
		GWEN_STRINGLISTENTRY* sle; 
		
		sle = GWEN_StringList_FirstEntry(sl);
		while(sle) {
			c = GWEN_StringListEntry_Data(sle);
			if(c) {
				s = [NSString stringWithUTF8String: c ];
				[strings addObject: s ];
			}
			sle = GWEN_StringListEntry_Next(sle);
		}
	}
	return strings;
}

NSDecimalNumber *convertValue(const AB_VALUE *val)
{
	double dValue;
	int	iValue;
	
	if (val == NULL) return [NSDecimalNumber zero ];
	if (hundred == nil) hundred = [[NSDecimalNumber numberWithInt:100 ] retain ];
	dValue = AB_Value_GetValueAsDouble(val);
	iValue = (int)(dValue*100);
	NSDecimalNumber *decVal = (NSDecimalNumber*)[NSDecimalNumber numberWithInt:iValue ];
	return [decVal decimalNumberByDividingBy:hundred ];
}

void convertStatement(AB_TRANSACTION *t, BankStatement *stmt)
{
	const char*			c;
	const AB_VALUE*		val;
	const GWEN_TIME*	d;
	
	AB_TRANSACTION_TYPE		type;
	AB_TRANSACTION_SUBTYPE	stype;
	
	type = AB_Transaction_GetType(t);
	stype = AB_Transaction_GetSubType(t);
	
	stmt.localBankCode = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBankCode(t)) ? c: ""];
	stmt.localAccount = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalAccountNumber(t)) ? c: ""];
	stmt.localSuffix =  (c = AB_Transaction_GetLocalSuffix(t)) ? [NSString stringWithUTF8String: c ]:nil;
	stmt.remoteCountry = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteCountry(t)) ? c: ""];
	stmt.remoteBankName = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankName(t)) ? c: ""];
	stmt.remoteBankLocation = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankLocation(t)) ? c: ""];
	if(type != AB_Transaction_TypeEuTransfer) {
		stmt.remoteBankCode = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankCode(t)) ? c: ""];
	}
	
	if(type != AB_Transaction_TypeEuTransfer) {
		stmt.remoteAccount = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteAccountNumber(t)) ? c: ""];
	}
	
	stmt.remoteIBAN = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteIban(t)) ? c: ""];
	stmt.remoteBIC = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBic(t)) ? c: ""];
	stmt.remoteName = convertStringListToString(AB_Transaction_GetRemoteName(t), @"");
	stmt.remoteSuffix = (c = AB_Transaction_GetRemoteSuffix(t)) ? [NSString stringWithUTF8String: c ]:nil;
	stmt.customerReference = [NSString stringWithUTF8String: (c = AB_Transaction_GetCustomerReference(t)) ? c: ""];
	stmt.bankReference = [NSString stringWithUTF8String: (c = AB_Transaction_GetBankReference(t)) ? c: ""];
	stmt.transactionText = [NSString stringWithUTF8String: (c = AB_Transaction_GetTransactionText(t)) ? c: ""];
	stmt.transactionCode = [NSString stringWithFormat:@"%0.3d", AB_Transaction_GetTextKey(t) ];
	stmt.primaNota = [NSString stringWithUTF8String: (c = AB_Transaction_GetPrimanota(t)) ? c: ""];
	stmt.purpose = convertStringListToString(AB_Transaction_GetPurpose(t), @"\n");
	
	val = AB_Transaction_GetValue(t);
	stmt.value = convertValue(val);
	stmt.currency = [NSString stringWithUTF8String: (c = AB_Value_GetCurrency(val)) ? c: ""];
	
	d = AB_Transaction_GetDate(t);
	if(d) {
		stmt.date = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	}
	
	d = AB_Transaction_GetValutaDate(t);
	if(d) { 
		stmt.valutaDate = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	}	
}

ABAccount *convertAccount(AB_ACCOUNT *acc)
{
	const char	*c;
	AB_JOB		*j;
	int			res;
	
	ABAccount *account = [[[ABAccount alloc ] init ] autorelease ];
	
	account.name			= [NSString stringWithUTF8String: (c = AB_Account_GetAccountName(acc)) ? c: ""];
	account.accountNumber	= [NSString stringWithUTF8String: (c = AB_Account_GetAccountNumber(acc)) ? c: ""];
	account.bankName		= [NSString stringWithUTF8String: (c = AB_Account_GetBankName(acc)) ? c: ""];
	account.bankCode		= [NSString stringWithUTF8String: (c = AB_Account_GetBankCode(acc)) ? c: ""];
	account.ownerName		= [NSString stringWithUTF8String: (c = AB_Account_GetOwnerName(acc)) ? c: ""];
	account.country			= [NSString stringWithUTF8String: (c = AB_Account_GetCountry(acc)) ? c: ""];
	account.currency		= [NSString stringWithUTF8String: (c = AB_Account_GetCurrency(acc)) ? c: ""];
	account.iban			= [NSString stringWithUTF8String: (c = AB_Account_GetIBAN(acc)) ? c: ""];
	account.bic				= [NSString stringWithUTF8String: (c = AB_Account_GetBIC(acc)) ? c: ""];
//	account.accountSuffix   = (c = (const char*)AH_Account_GetSuffix(acc)) ? [NSString stringWithUTF8String: c ]:nil;
	
	account.uid  = AB_Account_GetUniqueId(acc);
	account.type = AB_Account_GetAccountType(acc);
	
	uint32_t flags = AH_Account_GetFlags(acc);
	if(flags & AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER) account.collTransfer = NO; else account.collTransfer = YES;
	
	AB_USER *usr = AB_Account_GetFirstUser(acc);
	account.userId = [NSString stringWithUTF8String: (c = AB_User_GetUserId(usr)) ? c: ""];
	account.customerId = [NSString stringWithUTF8String: (c = AB_User_GetCustomerId(usr)) ? c: ""];
	
	j = (AB_JOB*)AB_JobInternalTransfer_new(acc);
	res = AB_Job_CheckAvailability(j);
	if(res) account.substInternalTransfers = YES; else account.substInternalTransfers = NO;
	AB_Job_free(j);
	return account;
}

TransactionLimits *convertLimits(const AB_TRANSACTION_LIMITS *t)
{
	TransactionLimits *limits = [[[TransactionLimits alloc ] init ] autorelease ];
	
	limits.maxLenRemoteName = AB_TransactionLimits_GetMaxLenRemoteName(t);
	limits.maxLinesRemoteName = AB_TransactionLimits_GetMaxLinesRemoteName(t);
	limits.maxLenPurpose = AB_TransactionLimits_GetMaxLenPurpose(t);
	limits.maxLinesPurpose = AB_TransactionLimits_GetMaxLinesPurpose(t);
	limits.minSetupTime = AB_TransactionLimits_GetMinValueSetupTime(t);
	limits.maxSetupTime = AB_TransactionLimits_GetMaxValueSetupTime(t);
	
	GWEN_STRINGLIST* sl = AB_TransactionLimits_GetValuesTextKey(t);
	if(sl) limits.allowedTextKeys = convertStringList(sl);
	limits.localLimit = limits.foreignLimit = 0.0;
	
	// Standing Order
	sl = AB_TransactionLimits_GetValuesCycleWeek(t);
	if(sl) limits.weekCycles = convertStringList(sl);
	sl = AB_TransactionLimits_GetValuesCycleMonth(t);
	if(sl) limits.monthCycles = convertStringList(sl);
	sl = AB_TransactionLimits_GetValuesExecutionDayWeek(t);
	if(sl) limits.execDaysWeek = convertStringList(sl);
	sl = AB_TransactionLimits_GetValuesExecutionDayMonth(t);
	if(sl) limits.execDaysMonth = convertStringList(sl);
	limits.allowWeekly = AB_TransactionLimits_GetAllowWeekly(t)==1?YES:NO;
	limits.allowMonthly = AB_TransactionLimits_GetAllowMonthly(t)==1?YES:NO;
	limits.allowChangeRemoteName = AB_TransactionLimits_GetAllowChangeRecipientName(t)==1?YES:NO;
	limits.allowChangeRemoteAccount = AB_TransactionLimits_GetAllowChangeRecipientAccount(t)==1?YES:NO;
	limits.allowChangeValue = AB_TransactionLimits_GetAllowChangeValue(t)==1?YES:NO;
	limits.allowChangePurpose = AB_TransactionLimits_GetAllowChangePurpose(t)==1?YES:NO;
	limits.allowChangeFirstExecDate = AB_TransactionLimits_GetAllowChangeFirstExecutionDate(t)==1?YES:NO;
	limits.allowChangeLastExecDate = AB_TransactionLimits_GetAllowChangeLastExecutionDate(t)==1?YES:NO;
	limits.allowChangeCycle = AB_TransactionLimits_GetAllowChangeCycle(t)==1?YES:NO;
	limits.allowChangePeriod = AB_TransactionLimits_GetAllowChangePeriod(t)==1?YES:NO;
	limits.allowChangeExecDay = AB_TransactionLimits_GetAllowChangeExecutionDay(t)==1?YES:NO;
	
	return limits;
}

TransactionLimits *convertEULimits(const AB_EUTRANSFER_INFO* t)
{
	TransactionLimits *limits = convertLimits(AB_EuTransferInfo_GetFieldLimits(t));
	const AB_VALUE*	val = AB_EuTransferInfo_GetLimitLocalValue(t);
	if(val) limits.localLimit = AB_Value_GetValueAsDouble(val);;
	val = AB_EuTransferInfo_GetLimitForeignValue(t);
	if(val) limits.foreignLimit = AB_Value_GetValueAsDouble(val);
	return limits;
}

NSString *standardSwiftString(NSString* str)
{
	NSRange r;
	NSString*	s = str;
	
	r = [s rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"äÄöÖüÜß" ] ];
	if(r.location == NSNotFound) return s;
	s = [s stringByReplacingOccurrencesOfString: @"ä" withString: @"ae" ];
	s = [s stringByReplacingOccurrencesOfString: @"Ä" withString: @"Ae" ];
	s = [s stringByReplacingOccurrencesOfString: @"ö" withString: @"oe" ];
	s = [s stringByReplacingOccurrencesOfString: @"Ö" withString: @"Oe" ];
	s = [s stringByReplacingOccurrencesOfString: @"ü" withString: @"ue" ];
	s = [s stringByReplacingOccurrencesOfString: @"Ü" withString: @"Ue" ];
	s = [s stringByReplacingOccurrencesOfString: @"ß" withString: @"ss" ];
	return s;
}

AB_TRANSACTION *convertTransfer(Transfer *transfer)
{
	AB_TRANSACTION		*t = AB_Transaction_new();
	NSString			*s;
	NSNumber			*n;
	AB_VALUE			*val;
	TransferType		tt = [transfer.type intValue ];
	
	BankAccount *account = transfer.account;
	
	AB_Transaction_SetLocalAccountNumber(t, [account.accountNumber UTF8String]);
	AB_Transaction_SetLocalBankCode(t, [account.bankCode UTF8String]);
	
	// set local IBAN/BIC
	s = account.iban;
	if(s && [s length ]>0) AB_Transaction_SetLocalIban(t, [s UTF8String ]);
	
	s = account.bic;
	if(s && [s length ]>0) AB_Transaction_SetLocalBic(t, [s UTF8String ]);
	
	// split remote name according to limits
	TransactionLimits *limits = [[HBCIClient hbciClient ] limitsForType: tt account: account country: transfer.remoteCountry ];
	s = transfer.remoteName;
	if(limits) {
		int i = 0;
		while([s length ] > [limits maxLenRemoteName ] && i < [limits maxLinesRemoteName ]) {
			NSString *tmp = [s substringToIndex: [limits maxLenRemoteName ] ];
			if(tmp) AB_Transaction_AddRemoteName(t, [tmp UTF8String ], 0);
			i++;
			s = [s substringFromIndex: [limits maxLenRemoteName ] ];
		}
		if(i < [limits maxLinesRemoteName ] && [s length ] > 0) AB_Transaction_AddRemoteName(t, [s UTF8String ], 0);
	} else {
		AB_Transaction_AddRemoteName(t, [s UTF8String ], 0);
	}
	
	s = transfer.remoteIBAN;
	if(s) AB_Transaction_SetRemoteIban(t, [s UTF8String ]);
	
	s = transfer.remoteBIC;
	if(s) AB_Transaction_SetRemoteBic(t, [s UTF8String ]);
	
	s = transfer.remoteAccount;
	if(s) AB_Transaction_SetRemoteAccountNumber(t, [s UTF8String ]);
	
	s = transfer.remoteBankCode;
	if(s) AB_Transaction_SetRemoteBankCode(t, [s UTF8String ]);
	
	s = transfer.remoteCountry;
	if(s) AB_Transaction_SetRemoteCountry(t, [s UTF8String ]);
	
	s = transfer.remoteBankName;
	s = standardSwiftString(s);
	if(s) AB_Transaction_SetRemoteBankName(t, [s UTF8String ]);
	
	s = transfer.purpose1;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = transfer.purpose2;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = transfer.purpose3;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = transfer.purpose4;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = transfer.currency;
	n = transfer.value;
	val = AB_Value_fromDouble([n doubleValue ]);
	if(!s || [s length ] == 0) AB_Value_SetCurrency(val, "EUR");
	else AB_Value_SetCurrency(val, [s UTF8String ]);
	
	// dated transfer
	if(tt == TransferTypeDated) {
		NSDate *date = transfer.valutaDate;
		GWEN_TIME *d = GWEN_Time_fromSeconds((unsigned int)[date timeIntervalSince1970 ]);
		AB_Transaction_SetValutaDate(t, d);
		AB_Transaction_SetDate(t, d);
		GWEN_Time_free(d);
	}
	
	switch(tt) {
		case TransferTypeLocal:
		case TransferTypeDated:
		case TransferTypeInternal:
			AB_Transaction_SetType(t, AB_Transaction_TypeTransfer);
			AB_Transaction_SetSubType(t, AB_Transaction_SubTypeStandard);
			break;
		case TransferTypeEU:
			AB_Transaction_SetType(t, AB_Transaction_TypeEuTransfer);
			AB_Transaction_SetSubType(t, AB_Transaction_SubTypeEuStandard);
			break;
	}
	AB_Transaction_SetValue(t, val);
	
	// set text key
	AB_Transaction_SetTextKey(t, 51);
	if(limits) {
		NSArray* keys = [limits allowedTextKeys ];
		if(keys && [keys count ]>0) {
			NSString* key = [keys objectAtIndex:0 ];
			AB_Transaction_SetTextKey(t, [key intValue ]);
		}
	}
	return t;
}

void convertToStandingOrder(const AB_TRANSACTION *t, StandingOrder *stord)
{
	const char*			c;
	int					i;
	const AB_VALUE*		val;
	const GWEN_TIME*	d;
	
	AB_TRANSACTION_TYPE		type;
	AB_TRANSACTION_SUBTYPE	stype;
	
	type = AB_Transaction_GetType(t);
	stype = AB_Transaction_GetSubType(t);
	
//	stord.localBankCode = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalBankCode(t)) ? c: ""];
//	stord.localAccount = [NSString stringWithUTF8String: (c = AB_Transaction_GetLocalAccountNumber(t)) ? c: ""];
	stord.remoteBankName = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankName(t)) ? c: ""];
	stord.remoteBankCode = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteBankCode(t)) ? c: ""];
	stord.remoteAccount = [NSString stringWithUTF8String: (c = AB_Transaction_GetRemoteAccountNumber(t)) ? c: ""];
	stord.remoteName = convertStringListToString(AB_Transaction_GetRemoteName(t), @"");
	stord.remoteSuffix = (c = AB_Transaction_GetRemoteSuffix(t)) ? [NSString stringWithUTF8String: c ]:nil;
	NSArray *purposes = convertStringList(AB_Transaction_GetPurpose(t));
	stord.period = [NSNumber numberWithInt: AB_Transaction_GetPeriod(t) ];
	stord.cycle = [NSNumber numberWithInt: AB_Transaction_GetCycle(t) ];
	stord.executionDay = [NSNumber numberWithInt: AB_Transaction_GetExecutionDay(t) ];
	stord.type = [NSNumber numberWithInt: AB_Transaction_GetUniqueId(t) ];
	stord.orderKey = (c = AB_Transaction_GetFiId(t)) ? [NSString stringWithUTF8String: c ]:nil;
		
	for(i=0; i<[purposes count ]; i++) {
		NSString *s = [purposes objectAtIndex:i ];
		switch (i) {
			case 0: stord.purpose1 = s; break;
			case 1: stord.purpose2 = s; break;
			case 2: stord.purpose3 = s; break;
			case 3: stord.purpose4 = s; break;
		}
	}	
	
	val = AB_Transaction_GetValue(t);
	stord.value = convertValue(val);
	stord.currency = [NSString stringWithUTF8String: (c = AB_Value_GetCurrency(val)) ? c: ""];
	
	d = AB_Transaction_GetFirstExecutionDate(t);
	if(d) {
		stord.firstExecDate = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	}
	
	d = AB_Transaction_GetLastExecutionDate(t);
	if(d) { 
		stord.lastExecDate = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	} else {
		stord.lastExecDate = [[ShortDate dateWithYear:2999 month:12 day:31 ] lowDate ];
	}

	
	d = AB_Transaction_GetNextExecutionDate(t);
	if(d) { 
		stord.nextExecDate = [NSDate dateWithTimeIntervalSince1970: (NSTimeInterval)GWEN_Time_Seconds(d) ];
	}
	
	AB_TRANSACTION_PERIOD period = AB_Transaction_GetPeriod(t);
	switch (period) {
		case AB_Transaction_PeriodWeekly: stord.period = [NSNumber numberWithInt: stord_weekly ]; break;
		default: stord.period = [NSNumber numberWithInt: stord_monthly ]; break;
	}
	
}

AB_TRANSACTION *convertStandingOrder(StandingOrder *stord)
{
	AB_TRANSACTION		*t = AB_Transaction_new();
	NSString			*s;
	NSNumber			*n;
	AB_VALUE			*val;
	
	BankAccount *account = stord.account;
	
	AB_Transaction_SetLocalAccountNumber(t, [account.accountNumber UTF8String]);
	AB_Transaction_SetLocalBankCode(t, [account.bankCode UTF8String]);
		
	// split remote name according to limits
	TransactionLimits *limits = [[HBCIClient hbciClient ] standingOrderLimitsForAccount:account action:stord_create ];
	s = stord.remoteName;
	if(limits) {
		int i = 0;
		while([s length ] > [limits maxLenRemoteName ] && i < [limits maxLinesRemoteName ]) {
			NSString *tmp = [s substringToIndex: [limits maxLenRemoteName ] ];
			if(tmp) AB_Transaction_AddRemoteName(t, [tmp UTF8String ], 0);
			i++;
			s = [s substringFromIndex: [limits maxLenRemoteName ] ];
		}
		if(i < [limits maxLinesRemoteName ] && [s length ] > 0) AB_Transaction_AddRemoteName(t, [s UTF8String ], 0);
	} else {
		AB_Transaction_AddRemoteName(t, [s UTF8String ], 0);
	}
		
	s = stord.remoteAccount;
	if(s) AB_Transaction_SetRemoteAccountNumber(t, [s UTF8String ]);
	
	s = stord.remoteBankCode;
	if(s) AB_Transaction_SetRemoteBankCode(t, [s UTF8String ]);
	
	s = stord.remoteBankName;
	s = standardSwiftString(s);
	if(s) AB_Transaction_SetRemoteBankName(t, [s UTF8String ]);
	
	s = stord.purpose1;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = stord.purpose2;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = stord.purpose3;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = stord.purpose4;
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = stord.currency;
	n = stord.value;
	val = AB_Value_fromDouble([n doubleValue ]);
	if(!s || [s length ] == 0) AB_Value_SetCurrency(val, "EUR");
	else AB_Value_SetCurrency(val, [s UTF8String ]);
	AB_Transaction_SetValue(t, val);
	
	AB_Transaction_SetType(t, AB_Transaction_TypeTransfer);
	AB_Transaction_SetSubType(t, AB_Transaction_SubTypeStandingOrder);
	
	switch ([stord.period intValue ]) {
		case stord_weekly: AB_Transaction_SetPeriod(t, AB_Transaction_PeriodWeekly); break;
		default: AB_Transaction_SetPeriod(t, AB_Transaction_PeriodMonthly); break;
	}
	AB_Transaction_SetCycle(t, [stord.cycle intValue ]);
	AB_Transaction_SetExecutionDay(t, [stord.executionDay intValue ]);
	
	if (stord.firstExecDate) {
		NSDate *date = stord.firstExecDate;
		GWEN_TIME *d = GWEN_Time_fromSeconds((unsigned int)[date timeIntervalSince1970 ]);
		AB_Transaction_SetFirstExecutionDate(t, d);
		GWEN_Time_free(d);
	}
	if (stord.lastExecDate) {
		ShortDate *sDate = [ShortDate dateWithDate:stord.lastExecDate ];
		if (sDate.year < 2100) {
			NSDate *date = stord.lastExecDate;
			GWEN_TIME *d = GWEN_Time_fromSeconds((unsigned int)[date timeIntervalSince1970 ]);
			AB_Transaction_SetLastExecutionDate(t, d);
			GWEN_Time_free(d);
		}
	}
	
	if (stord.orderKey) {
		AB_Transaction_SetFiId(t, [stord.orderKey UTF8String ]);
	}
	
	// set text key
	AB_Transaction_SetTextKey(t, 51);
	if(limits) {
		NSArray* keys = [limits allowedTextKeys ];
		if(keys && [keys count ]>0) {
			NSString* key = [keys objectAtIndex:0 ];
			AB_Transaction_SetTextKey(t, [key intValue ]);
		}
	}
	return t;
}
