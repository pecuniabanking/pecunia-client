//
//  ABController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 03.01.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//
#import "ABController.h"
#import "ABAccount.h"
#import "ABUser.h"
#import "Transaction.h"
#import "Transfer.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "TransactionLimits.h"
#import "Country.h"
#import "adduser.h"
#import "getsysid.h"
#import "BankInfo.h"
#import "Keychain.h"
#import "PasswordWindow.h"
#import "BankQueryResult.h"
#import "MOAssistant.h"
#import <aqhbci/user.h>
#import "BankingController.h"
#import "ImExporter.h"
#import "ImExporterProfile.h"
#import "ABConversion.h"
#import <AqBanking/aqbanking/eutransferinfo.h>
#import <AqBanking/aqbanking/jobeutransfer.h>
#import "ABControllerGui.h"
#import <AqBanking/aqhbci/account.h>

static ABController* abController;

@implementation ABController

-(id)init
{
	int rv;
	
	[super init ];
	accounts	= [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	users		= [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	abController = self;

	ab = AB_Banking_new("Pecunia", 0, 0);
	
	abGui = [[ABControllerGui alloc ] init ];
//	GWEN_GUI *gui = Cocoa_Gui_new();
	GWEN_Gui_SetGui([abGui gui ]);
		
//	AB_Banking_SetSetPinStatusFn(ab, SetPinStatus);
//	AB_Banking_SetSetTanStatusFn(ab, SetTanStatus);
//	AB_Banking_SetGetPinFn(ab, GetPin);
	
	// update Configuration
	rv=AB_Banking_HasConf4(ab);
	if (rv) {
		fprintf(stderr, "Config for AqBanking 4 not found, update needed (%d)\n", rv);
		rv=AB_Banking_HasConf3(ab);
		if (!rv) {
			/* import version 3 */
			rv=AB_Banking_ImportConf3(ab);
			if (rv<0) {
				fprintf(stderr, "Error importing configuration (%d)\n", rv);
			}
		}
	}
	
	rv=AB_Banking_Init(ab);
	if (rv) {
		fprintf(stderr, "Error on init (%d)\n", rv);
		return self;
	}
	
	rv=AB_Banking_OnlineInit(ab);
	if (rv) {
		fprintf(stderr, "Error on online-init (%d)\n", rv);
		return self;
	}

	// get User Data
	[self getUsers ];
	
	// get Account Data
	[self getAccounts ];
	
	// get Country data
	[self countries ];
	
	// get ImExporter Data
	[self getImExporters ];
	
	return self;
}

-(void)processContext:(AB_IMEXPORTER_CONTEXT*)ctx forAccounts:(NSMutableArray*)selAccounts
{
	ABAccount				*acc;
	BankQueryResult			*res;
	BOOL					found;

	NSManagedObjectContext *memContext = [[MOAssistant assistant ] memContext ];
	[memContext reset ];
	
	AB_IMEXPORTER_ACCOUNTINFO *ai;
	
	ai=AB_ImExporterContext_GetFirstAccountInfo(ctx);
	while(ai) {
		const AB_TRANSACTION *t;
		NSString *accountNumber = nil;
		NSString *bankCode = nil;
		
		found = NO;
		const char *c = AB_ImExporterAccountInfo_GetAccountNumber(ai);
		if (c && *c != 0) {
			accountNumber = [NSString stringWithUTF8String: c ];
			bankCode = [NSString stringWithUTF8String: AB_ImExporterAccountInfo_GetBankCode(ai) ];
			
			// find account
			acc = [self accountByNumber: accountNumber bankCode: bankCode];
			if(acc) {
				for(res in selAccounts) {
					if([res.accountNumber isEqualToString: accountNumber ] && [res.bankCode isEqualToString: bankCode ]) {
						found = YES;
						break;
					}
				}
			}
		}
		
		if (found == NO) {
			res = [[BankQueryResult alloc ] init ];
			res.accountNumber = accountNumber;
			res.bankCode = bankCode;
			[selAccounts addObject: res ];
		}
		
		t=AB_ImExporterAccountInfo_GetFirstTransaction(ai);
		if(t) res.statements = [NSMutableArray arrayWithCapacity:100 ];
		while(t) {
			BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement"
																inManagedObjectContext:memContext];
			convertStatement(t, stmt);
//			[stmt updateWithAB: t ];
			[res.statements addObject: stmt ];
			t=AB_ImExporterAccountInfo_GetNextTransaction(ai);
		} /* while transactions */
		
		t=AB_ImExporterAccountInfo_GetFirstStandingOrder(ai);
		if(t) res.standingOrders = [NSMutableArray arrayWithCapacity:10 ];
		while(t) {
			StandingOrder *stord = [NSEntityDescription insertNewObjectForEntityForName:@"StandingOrder"
																 inManagedObjectContext:memContext];
			convertToStandingOrder(t, stord);
			[res.standingOrders addObject: stord ];
			t=AB_ImExporterAccountInfo_GetNextStandingOrder(ai);
		} /* standing Orders */
		
		AB_ACCOUNT_STATUS* as = AB_ImExporterAccountInfo_GetFirstAccountStatus(ai);
		if(as) {
			const AB_BALANCE* bal = AB_AccountStatus_GetBookedBalance(as);
			const AB_VALUE	*val = 0;
			
			if(bal) val = AB_Balance_GetValue(bal);
			else {
				const AB_BALANCE *bal =AB_AccountStatus_GetNotedBalance(as);
				if(bal) val = AB_Balance_GetValue(bal);
			}
			if(val) {
				const char	*c = AB_Value_GetCurrency(val);
				res.currency = [NSString stringWithUTF8String: c ? c: ""];
				res.balance = convertValue(val);
			}
		}
		ai=AB_ImExporterContext_GetNextAccountInfo(ctx);
	} /* while ai */
}

-(void)standingOrdersForAccounts:(NSArray*)selAccounts
{
	AB_ACCOUNT				*a;
	AB_JOB_LIST2			*jl;
	AB_IMEXPORTER_CONTEXT	*ctx;
	int						rv;
	BankQueryResult			*res;
	NSMutableDictionary		*jobIDs = [NSMutableDictionary dictionaryWithCapacity:10  ];
	
	jl=AB_Job_List2_new();
	
	for(res in selAccounts) {
		// get Aq Object
		a = AB_Banking_GetAccountByCodeAndNumber(ab, [res.bankCode UTF8String], [res.accountNumber UTF8String]);
		if (a) {
			AB_JOB			*j;
						
			/* create a job which retrieves standing orders. */
			j=(AB_JOB*)AB_JobGetStandingOrders_new(a);
			rv=AB_Job_CheckAvailability(j);
			if (rv) {
				fprintf(stderr, "Job is not available (%d)\n", rv);
				goto error;
			}
			/* enqueue this job so that AqBanking knows we want it executed. */
			[jobIDs setObject:res forKey: [NSNumber numberWithInt: AB_Job_GetJobId(j) ] ];
			AB_Job_List2_PushBack(jl, j);
		}
	}
	// joblist is created
	
	ctx=AB_ImExporterContext_new();
	
	/* execute the queue. This effectivly sends all jobs which have been
	 * enqueued to the respective backends/banks.
	 * It only returns an error code (!=0) if not a single job could be
	 * executed successfully. */
	rv=AB_Banking_ExecuteJobs(ab, jl, ctx);
	if (rv) {
		fprintf(stderr, "Error on executeQueue (%d)\n", rv);
		goto error;
	}
	else {
		AB_JOB_LIST2_ITERATOR *it;
		
		it=(AB_JOB_LIST2_ITERATOR*)AB_Job_List2_First(jl);
		if(it) {
			AB_JOB *j=AB_Job_List2Iterator_Data(it);
			while(j) 
			{
				unsigned int jid = (unsigned int)AB_Job_GetJobId(j);
				res = (BankQueryResult*)[jobIDs objectForKey:[NSNumber numberWithInt: jid ] ];
				
				AB_JOB_STATUS status = AB_Job_GetStatus(j);
				if(status == AB_Job_StatusFinished || status == AB_Job_StatusPending) {
					res.account.isStandingOrderSupported = [NSNumber numberWithBool:YES ];
				} else {
					res.account.isStandingOrderSupported = [NSNumber numberWithBool:NO ];
				}

				j=AB_Job_List2Iterator_Next(it);
			}
			AB_Job_List2Iterator_free(it);
		}			
		
		[self processContext: ctx forAccounts: [selAccounts mutableCopy ]];
	} // if executeQueue successfull
	[[BankingController controller ] performSelectorOnMainThread: @selector(statementsNotification:) withObject: selAccounts waitUntilDone: YES ];
	return;
	
error:
	[[BankingController controller ] performSelectorOnMainThread: @selector(statementsNotification:) withObject: nil waitUntilDone: NO ];
	[selAccounts release ];
	return;
}

-(void)statementsForAccounts: (NSArray*)selAccounts
{
	AB_ACCOUNT				*a;
	AB_JOB_LIST2			*jl;
	AB_IMEXPORTER_CONTEXT	*ctx;
	int						rv;
	BankQueryResult			*res;
	
	jl=AB_Job_List2_new();
	
	for(res in selAccounts) {
		// get Aq Object
		a = AB_Banking_GetAccountByCodeAndNumber(ab, [res.bankCode UTF8String], [res.accountNumber UTF8String]);
		if (a) {
			AB_JOB			*j;

			/* create a job which retrieves balances */
			j=(AB_JOB*)AB_JobGetBalance_new(a);
			rv=AB_Job_CheckAvailability(j);
			if (rv) {
				fprintf(stderr, "Job is not available (%d)\n", rv);
				goto error;
			}
		
			/* add job to this list */
			AB_Job_List2_PushBack(jl, j);

			/* create a job which retrieves transaction statements. */
			j=(AB_JOB*)AB_JobGetTransactions_new(a);
			rv=AB_Job_CheckAvailability(j);
			if (rv) {
				fprintf(stderr, "Job is not available (%d)\n", rv);
				goto error;
			}
/*			
			NSDate *ltd = res.account.latestTransferDate;
			if (ltd) {
				GWEN_TIME *d = GWEN_Time_fromSeconds((unsigned int)[ltd timeIntervalSince1970 ]);
				AB_JobGetTransactions_SetFromTime(j, d);
				GWEN_Time_free(d);
			}
*/			
			/* enqueue this job so that AqBanking knows we want it executed. */
			AB_Job_List2_PushBack(jl, j);
		}
	}
	// joblist is created
	
	ctx=AB_ImExporterContext_new();
	
	/* execute the queue. This effectivly sends all jobs which have been
		* enqueued to the respective backends/banks.
		* It only returns an error code (!=0) if not a single job could be
		* executed successfully. */
	rv=AB_Banking_ExecuteJobs(ab, jl, ctx);
	if (rv) {
		fprintf(stderr, "Error on executeQueue (%d)\n", rv);
		goto error;
	}
	else {
		[self processContext: ctx forAccounts: [selAccounts mutableCopy ]];
	} // if executeQueue successfull
	[[BankingController controller ] performSelectorOnMainThread: @selector(statementsNotification:) withObject: selAccounts waitUntilDone: YES ];
	return;
	
error:
	[[BankingController controller ] performSelectorOnMainThread: @selector(statementsNotification:) withObject: nil waitUntilDone: NO ];
	[selAccounts release ];
	return;
}

-(BOOL)updateStandingOrders:(NSArray*)orders
{
	int						res;
	AB_TRANSACTION			*t;
	AB_JOB					*j;
	AB_JOB_LIST2			*jl;
	NSError					*error = nil;
	AB_IMEXPORTER_CONTEXT	*ctx;
	NSString				*accountNumber;
	NSString				*bankCode;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	NSMutableDictionary		*jobIDs = [NSMutableDictionary dictionaryWithCapacity:10  ];

	jl=AB_Job_List2_new();
	for(StandingOrder *stord in orders) {
		// todo: don't send unchanged orders
		if ([stord.isChanged boolValue] == NO && [stord.toDelete boolValue ] == NO) continue;
		
		// don't send sent orders without ID
		if ([stord.isSent boolValue ] == YES && stord.orderKey == nil) continue;
		
		t = convertStandingOrder(stord);
	
		accountNumber = [stord valueForKeyPath: @"account.accountNumber" ];
		bankCode = [stord valueForKeyPath: @"account.bankCode" ];
		
		AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [bankCode UTF8String], [accountNumber UTF8String]);
		if (acc == NULL) {
			fprintf(stderr, "Account not found (%s)\n", [accountNumber UTF8String]);
			continue;
		}
		
		// create job of correct type
		if (stord.orderKey == nil) {
			// create standing order
			j = (AB_JOB*)AB_JobCreateStandingOrder_new(acc);
			res = AB_Job_CheckAvailability(j);
		} else if ([stord.toDelete boolValue ] == YES ) {
			j = (AB_JOB*)AB_JobDeleteStandingOrder_new(acc);
		} else {
			j = (AB_JOB*)AB_JobModifyStandingOrder_new(acc);
		}
		res = AB_Job_CheckAvailability(j);
		if (res) {
			fprintf(stderr, "Orders could not be set (%d)\n", res);
			return NO;
		}

		switch (AB_Job_GetType(j)) {
			case AB_Job_TypeCreateStandingOrder:
				AB_JobCreateStandingOrder_SetTransaction(j, t);
				break;
			case AB_Job_TypeModifyStandingOrder:
				AB_JobModifyStandingOrder_SetTransaction(j, t);
				break;
			case AB_Job_TypeDeleteStandingOrder:
				AB_JobDeleteStandingOrder_SetTransaction(j, t);
				break;
			default:
				break;
		}
		
		[jobIDs setObject:stord forKey: [NSNumber numberWithInt: AB_Job_GetJobId(j) ] ];
		
		/* add job to this list */
		AB_Job_List2_PushBack(jl, j);
		AB_Transaction_free(t);
	}

	// send orders to bank
	ctx=AB_ImExporterContext_new();
	
	/* execute the queue. This effectivly sends all jobs which have been
	 * enqueued to the respective backends/banks.
	 * It only returns an error code (!=0) if not a single job could be
	 * executed successfully. */
	res=AB_Banking_ExecuteJobs(ab, jl, ctx);
	if (res) {
		fprintf(stderr, "Error on executeQueue (%d)\n", res);
		return NO;
	}
	else {
		AB_JOB_LIST2_ITERATOR *it;
		
		it=(AB_JOB_LIST2_ITERATOR*)AB_Job_List2_First(jl);
		if(it) {
			j=AB_Job_List2Iterator_Data(it);
			while(j) 
			{
				unsigned int jid = (unsigned int)AB_Job_GetJobId(j);
				StandingOrder *stord = (StandingOrder*)[jobIDs objectForKey:[NSNumber numberWithInt:jid ] ];
				AB_JOB_STATUS status = AB_Job_GetStatus(j);
				if(status == AB_Job_StatusFinished || status == AB_Job_StatusPending) {
					// todo
					[stord setValue: [NSNumber numberWithBool:YES] forKey: @"isSent" ];
					
					//
					AB_JOB_TYPE type = AB_Job_GetType(j);
					switch (type) {
						case AB_Job_TypeCreateStandingOrder: 
							{
								const AB_TRANSACTION *trans = (const AB_TRANSACTION *)AB_JobCreateStandingOrder_GetTransaction(j);
								const char *c = AB_Transaction_GetFiId(trans);
								if (c) stord.orderKey = [NSString stringWithUTF8String:c ];
								stord.isChanged = [NSNumber numberWithBool:NO ];
							}
							break;
						case AB_Job_TypeDeleteStandingOrder: 
							{
								[context deleteObject:stord ];
							}
						default: stord.isChanged = [NSNumber numberWithBool:NO ];
					}
				}
				j=AB_Job_List2Iterator_Next(it);
			}
			AB_Job_List2Iterator_free(it);
			
			// save everything			
			if([context save: &error ] == NO) {
				NSAlert *alert = [NSAlert alertWithError:error];
				[alert runModal];
				return NO;
			}
		}
	}
	return YES;
}

-(BOOL)sendTransfers: (NSArray*)transfers
{
	int						i, res;
	AB_TRANSACTION			*t;
	AB_JOB					*j;
	AB_JOB_LIST2			*jl;
	NSError					*error = nil;
	AB_IMEXPORTER_CONTEXT	*ctx;
	NSString				*accountNumber;
	NSString				*bankCode;
	TransferType            tt;
	NSManagedObjectContext	*context = [[MOAssistant assistant ] context ];
	
	jl=AB_Job_List2_new();
	for(i=0; i<[transfers count ]; i++) {
		Transfer *transfer = [transfers objectAtIndex: i ];
		
		// don't send already sent transfers again
		if( transfer == nil || [[transfer valueForKey: @"isSent" ] boolValue ] == YES) continue;
		
		t = convertTransfer(transfer);
		
		accountNumber = [transfer valueForKeyPath: @"account.accountNumber" ];
		bankCode = [transfer valueForKeyPath: @"account.bankCode" ];
		
		AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [bankCode UTF8String], [accountNumber UTF8String]);
		if (acc == NULL) {
			fprintf(stderr, "Account not found (%s)\n", [accountNumber UTF8String]);
			continue;
		}
		
		// create job of correct type
		tt = [[transfer valueForKey: @"type" ] intValue ];
		switch(tt) {
			case TransferTypeInternal:
				j = (AB_JOB*)AB_JobInternalTransfer_new(acc);
				res = AB_Job_CheckAvailability(j);
				if (res) {
					// internal transfer not supported, try local transfer
					AB_Job_free(j);
					j = (AB_JOB*)AB_JobSingleTransfer_new(acc);
					AB_Job_CheckAvailability(j);
					res = AB_JobSingleTransfer_SetTransaction(j, t);
				} else res = AB_JobInternalTransfer_SetTransaction(j, t);
				break;
			case TransferTypeLocal:
				j = (AB_JOB*)AB_JobSingleTransfer_new(acc);
				AB_Job_CheckAvailability(j);
				res = AB_JobSingleTransfer_SetTransaction(j, t);
				break;
			case TransferTypeDated:
				j = (AB_JOB*)AB_JobCreateDatedTransfer_new(acc);
				AB_Job_CheckAvailability(j);
				res = AB_JobCreateDatedTransfer_SetTransaction(j, t);
				break;
			case TransferTypeEU:
				j = (AB_JOB*)AB_JobEuTransfer_new(acc);
				AB_Job_CheckAvailability(j);
				res = AB_JobEuTransfer_SetTransaction(j, t);
				AB_JobEuTransfer_SetChargeWhom(j, [[transfer valueForKey: @"chargedBy" ] intValue ]);
				break;
		}
		
		if (res) {
			fprintf(stderr, "Transaction could not be set (%d)\n", res);
			return NO;
		}

		[transfer setJobId: AB_Job_GetJobId(j) ];
		
		/* add job to this list */
		AB_Job_List2_PushBack(jl, j);
		AB_Transaction_free(t);
	}
	
	if(AB_Job_List2_GetSize(jl) == 0) {
		fprintf(stderr, "No Transactions to be sent");
		AB_Job_List2_free(jl);
		return YES;
	}

// send statements to bank
	ctx=AB_ImExporterContext_new();
	
	/* execute the queue. This effectivly sends all jobs which have been
		* enqueued to the respective backends/banks.
		* It only returns an error code (!=0) if not a single job could be
		* executed successfully. */
	res=AB_Banking_ExecuteJobs(ab, jl, ctx);
	if (res) {
		fprintf(stderr, "Error on executeQueue (%d)\n", res);
		return NO;
	}
	else {
		AB_JOB_LIST2_ITERATOR *it;
		
		it=(AB_JOB_LIST2_ITERATOR*)AB_Job_List2_First(jl);
		if(it) {
			j=AB_Job_List2Iterator_Data(it);
			while(j) 
			{
				unsigned int jid = (unsigned int)AB_Job_GetJobId(j);
				for(i=0; i<[transfers count ]; i++) {
					Transfer* transfer = [transfers objectAtIndex: i ];
					if([transfer jobId ] != jid) continue;
					AB_JOB_STATUS status = AB_Job_GetStatus(j);
					if(status == AB_Job_StatusFinished || status == AB_Job_StatusPending) {
						const char *c = AB_Job_GetUsedTan(j);
						if(c) [transfer setValue: [NSString stringWithUTF8String: c ] forKey: @"usedTAN" ];
						[transfer setValue: [NSNumber numberWithBool:YES] forKey: @"isSent" ];
					}
					break;
				}
				j=AB_Job_List2Iterator_Next(it);
			}
			AB_Job_List2Iterator_free(it);
			
// save everything			
			if([context save: &error ] == NO) {
				NSAlert *alert = [NSAlert alertWithError:error];
				[alert runModal];
				return NO;
			}
		}
	}
	AB_Job_List2_free(jl);
	return YES;
}

-(NSMutableArray*)users
{
	return users;
}


-(NSMutableArray *)getUsers
{
	AB_USER_LIST2*  usr;
	ABUser*			user;
	
	[users removeAllObjects	];
	usr=AB_Banking_GetUsers(ab);
	if(usr) {
		AB_USER_LIST2_ITERATOR *it;
		
		it=(AB_USER_LIST2_ITERATOR*)AB_User_List2_First(usr);
		if(it) {
			AB_USER *u;
			
			u=AB_User_List2Iterator_Data(it);
			while(u) 
			{
				user = convertUser(u);
				[users addObject: user ];				
				u=AB_User_List2Iterator_Next(it);
			}
			AB_User_List2Iterator_free(it);
		}
	}
	AB_User_List2_free(usr);
	return users;
}


-(NSMutableArray *)getAccounts
{
	AB_ACCOUNT_LIST2*	accs;
	ABAccount*			acc;

	[accounts removeAllObjects ];
	accs=AB_Banking_GetAccounts(ab);
	if (accs) {
		AB_ACCOUNT_LIST2_ITERATOR *it;
		it=AB_Account_List2_First(accs);
		if (it) {
			AB_ACCOUNT *a;
			
			a = AB_Account_List2Iterator_Data(it);
			while(a) {
				acc = convertAccount(a);
				[accounts addObject: acc];

				a=AB_Account_List2Iterator_Next(it);
			}
			AB_Account_List2Iterator_free(it);
		}
		AB_Account_List2_free(accs);
	}
	return accounts;
}


-(void)dealloc
{
	int rv;
	
	rv=AB_Banking_OnlineFini(ab);
	if (rv) {
		fprintf(stderr, "ERROR: Error on online-deinit (%d)\n", rv);
		return;
	}

	rv=AB_Banking_Fini(ab);
	if (rv) {
		fprintf(stderr, "ERROR: Error on deinit (%d)\n", rv);
		return;
	}
	
	AB_Banking_free(ab);
	
	[users release ];
	[accounts release ];
	[countries release ];
	[abGui release ];
	[super dealloc ];
}

-(ABAccount*)accountByNumber: (NSString*)n bankCode: (NSString*)c
{
	int i, count = [accounts count ];
	ABAccount	*acc;
	
	for( i = 0; i < count; i++) {
		acc = [accounts objectAtIndex: i ];
		if([[acc accountNumber ] isEqual: n] && [[acc bankCode ] isEqual: c]) return acc;
	}
	return nil;
}

-(NSMutableArray*)accounts
{
	return accounts;
}

-(BOOL)checkAccount: (NSString*)accountNumber forBank: (NSString*)bankCode inCountry: (NSString*)country
{
	
	AB_BANKINFO_CHECKRESULT res;
	
	res = AB_Banking_CheckAccount (ab, 
								   (country == nil) ? "de":[country UTF8String ], 
								   NULL,
								   [bankCode UTF8String ],
								   [accountNumber UTF8String ]);
	
	if(res == AB_BankInfoCheckResult_Ok ||
	   res == AB_BankInfoCheckResult_UnknownResult ||
	   res == AB_BankInfoCheckResult_UnknownBank) return YES; else return NO;
}

-(AB_BANKING*)handle
{
	return ab;
}

-(BankInfo*)infoForBankCode: (NSString*)code inCountry: (NSString*)country
{
	AB_BANKINFO		*bi;
	
	if(code == nil || [code isEqual: @"" ]) return nil;
	
	bi = AB_Banking_GetBankInfo(ab, [country UTF8String ], NULL, [code UTF8String ]);
	if(!bi) return nil;
	BankInfo *bankInfo = convertBankInfo(bi);
	AB_BankInfo_free(bi);
	return bankInfo;	
}

-(NSString*)bankNameForCode: (NSString*)bankCode inCountry: (NSString*)country
{
	AB_BANKINFO		*bi;
	NSString		*bankName;
	
	if(bankCode == nil || [bankCode isEqual: @"" ]) return @"";

	bi = AB_Banking_GetBankInfo(ab, [country UTF8String ], NULL, [bankCode UTF8String ]);

	if(!bi) return NSLocalizedString(@"unknown", @"- unknown -");
	bankName = [NSString stringWithUTF8String: AB_BankInfo_GetBankName(bi) ];
	AB_BankInfo_free(bi);
	return bankName;	
}

-(NSString*)bankNameForBic: (NSString*)bic inCountry: (NSString*)country
{
	if(bic == nil || [bic isEqual: @"" ]) return @"";
	
	AB_BANKINFO_LIST2	*bil = AB_BankInfo_List2_new();
	AB_BANKINFO			*bi = AB_BankInfo_new();
	NSString			*bankName;
	
	AB_BankInfo_SetBic(bi, [bic UTF8String ]);
	
	AB_Banking_GetBankInfoByTemplate(ab, [country UTF8String ], bi, bil);
	AB_BankInfo_free(bi);
	bi = AB_BankInfo_List2_GetFront(bil);
	if(!bi) {
		AB_BankInfo_List2_free(bil);
		return NSLocalizedString(@"unknown", @"- unknown -");
	}
	bankName = [NSString stringWithUTF8String: AB_BankInfo_GetBankName(bi) ];
	AB_BankInfo_List2_free(bil);
	return bankName;
}

-(NSString*)addBankUser: (ABUser*)user
{
	char		*errmsg;
	int			rv;
	uint32_t	flags = AH_USER_FLAGS_FORCE_SSL3;

//	if([user forceSSL3 ]) flags = flags ^ AH_USER_FLAGS_FORCE_SSL3;
	int au = addUser( ab, [user.bankCode UTF8String], [user.userId UTF8String],
						  [user.customerId UTF8String], [user.mediumId UTF8String], [user.bankURL UTF8String], 
						  [user.name UTF8String ], 0 , flags, user.hbciVersion, &errmsg );
	
	if( au != 0 )
	{
		return [NSString stringWithUTF8String: errmsg];
	}
	else
	{
		int si = getSysId( ab, [user.bankCode UTF8String], [user.userId UTF8String], [user.customerId UTF8String], &errmsg );
		if(si != 0) {
		// try again with forceSSL3
			AB_USER* usr = AB_Banking_FindUser(ab, "aqhbci", "de", [user.bankCode UTF8String],
											   [user.userId UTF8String], [user.customerId UTF8String]);
			if(usr) {
				uint32 flags = AH_User_GetFlags(usr);
				flags ^= AH_USER_FLAGS_FORCE_SSL3;
				rv=AB_Banking_BeginExclUseUser(ab, usr);
				if (rv ==  0) {
					AH_User_SetFlags(usr, flags);
					AB_Banking_EndExclUseUser(ab, usr, 0);
					si = getSysId( ab, [user.bankCode UTF8String], [user.userId UTF8String], [user.customerId UTF8String], &errmsg );
				}
			}
		}

		if( si != 0 )
		{			
			// delete user first
			AB_USER* usr = AB_Banking_FindUser(ab, "aqhbci", "de", [user.bankCode UTF8String],
											   [user.userId UTF8String], [user.customerId UTF8String]);
			if(usr) AB_Banking_DeleteUser(ab, usr);
			return [NSString stringWithUTF8String: errmsg];
		}
		[self getUsers ];
		[self getAccounts ];
		
		// search for accounts and change all user accounts to single transfer
		for(ABAccount *account in accounts) {
			if ([account.userId isEqualToString:user.userId ] && [account.customerId isEqualToString:user.customerId ]) {
				AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String ], [account.accountNumber UTF8String ]);
				int rv = AB_Banking_BeginExclUseAccount(ab, acc);
				if (rv == 0) {
					AH_Account_AddFlags(acc, AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER);
					AB_Banking_EndExclUseAccount(ab, acc, NO);
				}
			}
		}
		
	}
	return nil;
}


-(NSString*)getSystemIDForUser: (ABUser*)user
{
	char		*errmsg;

	int si = getSysId( ab, [user.bankCode UTF8String], [user.userId UTF8String], [user.customerId UTF8String], &errmsg );
	if( si != 0 ) return [NSString stringWithUTF8String: errmsg];
	[self getAccounts ];
	return nil;
}

-(void)changePinTanMethodForUser:(ABUser*)user method:(int)method
{
	if (user == nil) return;
	AB_USER* usr = AB_Banking_FindUser(ab, "aqhbci", "de", [user.bankCode UTF8String], [user.userId UTF8String], [user.customerId UTF8String]);
	if (usr) {
		int rv = AB_Banking_BeginExclUseUser(ab, usr );
		if (rv == 0) {
			//tanMethodList
			const AH_TAN_METHOD_LIST *ml = AH_User_GetTanMethodDescriptions(usr);
			if(ml) {
				const AH_TAN_METHOD *tm = AH_TanMethod_List_First(ml);
				int version = 0;
				while(tm) {
					int function = AH_TanMethod_GetFunction(tm);
					if(method == function) {
						// select highest version
						int mv = AH_TanMethod_GetGvVersion(tm);
						if (mv > version) {
							int methodVersion = mv*1000 + method;
							AH_User_SetSelectedTanMethod(usr, methodVersion);
							version = mv;
						}
					}
					tm = AH_TanMethod_List_Next(tm);
				}
			}
			AB_Banking_EndExclUseUser(ab, usr, NO);
		} else return;
	}
}

-(int)removeUser:(AB_USER*)user fromAccount: (AB_ACCOUNT*)acc
{
	AB_USER_LIST2			*ul = AB_Account_GetUsers(acc);
	AB_USER_LIST2_ITERATOR	*it;
	const AB_USER			*usr=0;
	int						res=0;
	
	if(!ul) return 0;
	uint32_t  uuid = AB_User_GetUniqueId(user);
	
	it=AB_User_List2_First(ul);
	if (it) {
		usr = AB_User_List2Iterator_Data(it);
		while(usr) {
			if(uuid == AB_User_GetUniqueId(usr)) break;
			usr=AB_User_List2Iterator_Next(it);
		}
		AB_User_List2Iterator_free(it);
	}
	if(usr) {
		AB_User_List2_Remove(ul, usr);
		AB_Account_SetUsers(acc, ul);
	}
	
	res = AB_User_List2_GetSize(ul);
	AB_User_List2_free(ul);
	return res;
}

-(BOOL)deleteBankUser: (ABUser*)user
{
	int	i, res;
	AB_USER*	usr = AB_Banking_GetUser(ab, (uint32_t)user.uid);
	
	if(!usr) return FALSE;
	AB_ACCOUNT*	acc = AB_Banking_FindFirstAccountOfUser(ab, usr);
	if(acc) {
		res = NSRunAlertPanel(NSLocalizedString(@"AP16", @"Warning"),
							  NSLocalizedString(@"AP17", @"There are still bank accounts assigned to the user. Do you want to delete the accounts as well?"),
							  NSLocalizedString(@"cancel", @"Cancel"),
							  NSLocalizedString(@"yes", @"Yes"),
							  NSLocalizedString(@"no", @"No")
							  );
		
		if(res == NSAlertDefaultReturn) return NO;
		// remove user from all accounts
		
		for(i=0; i < [accounts count ]; i++) {
			ABAccount *acc = [accounts objectAtIndex:i ];
			AB_ACCOUNT  *abAcc = AB_Banking_GetAccountByCodeAndNumber(ab, [acc.bankCode UTF8String], [acc.accountNumber UTF8String]);

			int n = [self removeUser: usr fromAccount: abAcc ];
			// if there is no user anymore for an account, delete it
			if(n == 0) {
				AB_Banking_DeleteAccount(ab, abAcc);
				[accounts removeObject: acc ];
				i--;
			}
		}
	}

	if(AB_Banking_DeleteUser(ab, usr)) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"AP101", @"Error"),
								NSLocalizedString(@"AP86", @"Bank ID could not be deleted"),
								NSLocalizedString(@"ok", @"Ok"),
								nil, nil
								);
		return NO;
	}
	
	if(res == NSAlertAlternateReturn) {
		[[BankingController controller ] removeDeletedAccounts ];
	};
	
	return TRUE;
}

-(NSDictionary*)countries
{
	if(countries) return countries;
	AB_COUNTRY_CONSTLIST2* abCountries = AB_Banking_ListCountriesByName(ab, "*");
	if(!abCountries) return nil;
	AB_COUNTRY_CONSTLIST2_ITERATOR* it = AB_Country_ConstList2_First(abCountries);
	if(it) {
		countries = [[NSMutableDictionary dictionaryWithCapacity: 40 ] retain ];
		const AB_COUNTRY *abCountry = AB_Country_ConstList2Iterator_Data(it);
		while(abCountry) {
			Country* country = convertCountry(abCountry);
			[countries setObject: country forKey: country.code ];
			
			abCountry = AB_Country_ConstList2Iterator_Next(it);
		}
		AB_Country_ConstList2Iterator_free(it);
		
	}
	AB_Country_ConstList2_free(abCountries);
	return countries;
}

-(BOOL)checkIBAN: (NSString*)iban
{
	if(iban == nil || [iban isEqual: @"" ]) return YES;
	int res = AB_Banking_CheckIban([iban UTF8String ]);
 	if(res) return NO; else return YES;
}

-(BOOL)addAccount: (BankAccount*)account forUser: (ABUser*)user
{
	int res;
	
	AB_ACCOUNT	*acc = AB_Banking_CreateAccount(ab, "aqhbci");
	if(acc == NULL) {
		fprintf(stderr, "Could not create bank account\n");
		return NO;
	}
	// convert to AB account
	convertToAccount(account, acc);
	
	AB_USER	*abUser = AB_Banking_GetUser(ab, user.uid);
	if(abUser == NULL) {
		fprintf(stderr, "Could not find user %d\n", user.uid);
		return NO;
	}
	AB_Account_SetUser(acc, abUser);
	res = AB_Banking_AddAccount(ab, acc);
	if(res) {
		fprintf(stderr, "Error creating account: %d\n", res);
		return NO;
	}
	
	// set collectiveTransfer
	int rv = AB_Banking_BeginExclUseAccount(ab, acc);
	if (rv == 0) {
		if([account.collTransfer boolValue ] == NO) AH_Account_AddFlags(acc, AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER);
		else AH_Account_SubFlags(acc, AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER);
		AB_Banking_EndExclUseAccount(ab, acc, NO);
	}
	
	// add account internally
	[self getAccounts ];
	return YES;
}

-(BOOL)changeAccount:(BankAccount*)account
{
	if(account == nil) return NO;
	AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String ], [account.accountNumber UTF8String ]);

	int rv = AB_Banking_BeginExclUseAccount(ab, acc);
	if (rv == 0) {
		AB_Account_SetAccountName(acc, [account.name UTF8String ]);
		AB_Account_SetOwnerName(acc, [account.owner UTF8String ]);
		AB_Account_SetIBAN(acc, [account.iban UTF8String ]);
		AB_Account_SetBIC(acc, [account.bic UTF8String ]);
		
		if([account.collTransfer boolValue ] == NO) AH_Account_AddFlags(acc, AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER);
		else AH_Account_SubFlags(acc, AH_BANK_FLAGS_PREFER_SINGLE_TRANSFER);
		
		AB_Banking_EndExclUseAccount(ab, acc, NO);
	}
	
	// update Accounts
	[self getAccounts ];
	if (rv == 0) return YES; else return NO;
}

-(BOOL)deleteAccount: (BankAccount*)account
{
	// remove account in backend
	if(account == nil) return YES;
	AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String ], [account.accountNumber UTF8String ]);
	if (acc == NULL) return YES;
	int res = AB_Banking_DeleteAccount(ab, acc);
	if(res) return NO;
	
	for(ABAccount *abAcc in accounts) {
		if ([abAcc.accountNumber isEqualToString: account.accountNumber ] &&
			[abAcc.bankCode isEqualToString:account.bankCode ]) {
			[accounts removeObject: abAcc ];
			break;
		}
	}
	return YES;
}

-(BOOL)isTransferSupported:(TransferType)tt forAccount:(BankAccount*)account
{
	AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String], [account.accountNumber UTF8String]);
	AB_JOB	*j;
	int		res;
	
	switch(tt) {
		case TransferTypeInternal:
			j = (AB_JOB*)AB_JobInternalTransfer_new(acc);
			res = AB_Job_CheckAvailability(j);
			if (res) {
				// internal transfer not supported, try local transfer
				AB_Job_free(j);
				j = (AB_JOB*)AB_JobSingleTransfer_new(acc);
			}
			break;
		case TransferTypeLocal: 
			j = (AB_JOB*)AB_JobSingleTransfer_new(acc);
			break;
		case TransferTypeEU:
			j = (AB_JOB*)AB_JobEuTransfer_new(acc);
			break;
		case TransferTypeDated:
			j = (AB_JOB*)AB_JobCreateDatedTransfer_new(acc);
			break;
	}
	res = AB_Job_CheckAvailability(j);
	if (res) {
		AB_Job_free(j);
		return NO;
	}
	AB_Job_free(j);
	return YES;	
}

-(BOOL)isStandingOrderSupportedForAccount:(BankAccount*)account
{
	AB_ACCOUNT  *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String], [account.accountNumber UTF8String]);
	
	AB_JOB *j = (AB_JOB*)AB_JobCreateStandingOrder_new(acc);
	int res = AB_Job_CheckAvailability(j);
	if (res) {
		AB_Job_free(j);
		return NO;
	}
	AB_Job_free(j);
	return YES;
}

-(TransactionLimits*)limitsForType:(TransferType)tt account:(BankAccount*)account country:(NSString*)ctry
{
	AB_JOB				*j;
	int					res;
	TransactionLimits	*limits = nil;
	
	AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String], [account.accountNumber UTF8String]);
	switch(tt) {
		case TransferTypeInternal:
			j = (AB_JOB*)AB_JobInternalTransfer_new(acc);
			res = AB_Job_CheckAvailability(j);
			if (res) {
				// internal transfer not supported, try local transfer
				AB_Job_free(j);
				j = (AB_JOB*)AB_JobSingleTransfer_new(acc);
				tt = TransferTypeLocal;
			}
			break;
		case TransferTypeLocal: 
			j = (AB_JOB*)AB_JobSingleTransfer_new(acc);
			break;
		case TransferTypeEU:
			if(!ctry) return nil;
			j = (AB_JOB*)AB_JobEuTransfer_new(acc);
			break;
		case TransferTypeDated:
			j = (AB_JOB*)AB_JobCreateDatedTransfer_new(acc);
			break;
	}
	res = AB_Job_CheckAvailability(j);
	if (res) {
		AB_Job_free(j);
		fprintf(stderr, "Job is not available (%d)\n", res);
		return nil;
	}
	
	switch(tt) {
		case TransferTypeInternal: {
			const AB_TRANSACTION_LIMITS* tl = (AB_TRANSACTION_LIMITS*)AB_JobInternalTransfer_GetFieldLimits (j);
			if(tl) limits = convertLimits(tl);
			break;
		}
		case TransferTypeLocal: { 
			const AB_TRANSACTION_LIMITS* tl = (AB_TRANSACTION_LIMITS*)AB_JobSingleTransfer_GetFieldLimits(j);
			if(tl) limits = convertLimits(tl);
			break;
		}
		case TransferTypeDated: {
			const AB_TRANSACTION_LIMITS* tl = (AB_TRANSACTION_LIMITS*)AB_JobCreateDatedTransfer_GetFieldLimits(j);
			if(tl) limits = convertLimits(tl);
			break;
		}
		case TransferTypeEU: {
			const AB_EUTRANSFER_INFO* inf = (AB_EUTRANSFER_INFO*)AB_JobEuTransfer_FindCountryInfo (j, [ctry UTF8String ]);
			if(inf) limits = convertEULimits(inf);
			break;
		}
	}
	AB_Job_free(j);
	return limits;
}

-(TransactionLimits*)standingOrderLimitsForAccount:(BankAccount*)account action:(StandingOrderAction)action
{
	AB_JOB		*j;
	AB_ACCOUNT  *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String], [account.accountNumber UTF8String]);
	TransactionLimits *limits = nil;
	const AB_TRANSACTION_LIMITS* tl;
	
	switch (action) {
		case stord_create: j = (AB_JOB*)AB_JobCreateStandingOrder_new(acc); break;
		case stord_change: j = (AB_JOB*)AB_JobModifyStandingOrder_new(acc); break;
		case stord_delete: j = (AB_JOB*)AB_JobDeleteStandingOrder_new(acc); break;
	}
	int res = AB_Job_CheckAvailability(j);
	if (res) {
		AB_Job_free(j);
		fprintf(stderr, "Job is not available (%d)\n", res);
		return nil;
	}
	switch (action) {
		case stord_create: tl = (AB_TRANSACTION_LIMITS*)AB_JobCreateStandingOrder_GetFieldLimits(j); break;
		case stord_change: tl = (AB_TRANSACTION_LIMITS*)AB_JobModifyStandingOrder_GetFieldLimits(j); break;
		case stord_delete: tl = (AB_TRANSACTION_LIMITS*)AB_JobDeleteStandingOrder_GetFieldLimits(j); break;
	}
	if(tl) limits = convertLimits(tl);
	
	// on create action, all fields are changeable...
	if (action == stord_create) {
		limits.allowChangeRemoteName = YES;
		limits.allowChangeRemoteAccount = YES;
		limits.allowChangeValue = YES;
		limits.allowChangePurpose = YES;
		limits.allowChangeFirstExecDate = YES;
		limits.allowChangeLastExecDate = YES;
		limits.allowChangeCycle = YES;
		limits.allowChangePeriod = YES;
		limits.allowChangeExecDay = YES;
	}
	AB_Job_free(j);
	return limits;
}

-(NSArray*)allowedCountriesForAccount:(BankAccount*)account
{
	AB_JOB							*j;
	int								res;
	const AB_EUTRANSFER_INFO_LIST	*cil;
	AB_EUTRANSFER_INFO				*ti;
	NSMutableArray					*allowedCountries;
	
	AB_ACCOUNT *acc = AB_Banking_GetAccountByCodeAndNumber(ab, [account.bankCode UTF8String], [account.accountNumber UTF8String]);
	
	j = (AB_JOB*)AB_JobEuTransfer_new(acc);
	res = AB_Job_CheckAvailability(j);
	if (res) return nil;
	cil = AB_JobEuTransfer_GetCountryInfoList(j);
	if(!cil) return [countries allValues ];
	ti = AB_EuTransferInfo_List_First(cil);
	if(ti) allowedCountries = [NSMutableArray arrayWithCapacity: 20 ]; else return [countries allValues ];
	
	while(ti) {
		NSString *code = [NSString stringWithUTF8String: AB_EuTransferInfo_GetCountryCode(ti) ];
		[allowedCountries addObject: [countries valueForKey: code ]];
		ti = AB_EuTransferInfo_List_Next(ti);
	}
	return allowedCountries;
}

-(void)setLogLevel:(LogLevel)level
{
	GWEN_LOGGER_LEVEL gwenLevel;
	
	switch (level) {
		case LogLevel_Error: gwenLevel = GWEN_LoggerLevel_Error; break;
		case LogLevel_Warning: gwenLevel = GWEN_LoggerLevel_Warning; break;
		case LogLevel_Notice: gwenLevel = GWEN_LoggerLevel_Notice; break;
		case LogLevel_Info: gwenLevel = GWEN_LoggerLevel_Info; break;
		case LogLevel_Debug: gwenLevel = GWEN_LoggerLevel_Debug; break;
		case LogLevel_Verbous: gwenLevel = GWEN_LoggerLevel_Verbous; break;
		case LogLevel_None: gwenLevel = GWEN_LoggerLevel_Critical; break;
		default: gwenLevel = GWEN_LoggerLevel_Warning; break;
	}
	
	GWEN_Logger_SetLevel(AQHBCI_LOGDOMAIN, gwenLevel);
	GWEN_Logger_SetLevel(AQBANKING_LOGDOMAIN, gwenLevel);
	if (level = LogLevel_Verbous) {
		GWEN_Logger_SetLevel(GWEN_LOGDOMAIN, GWEN_LoggerLevel_Verbous);
	} else GWEN_Logger_SetLevel(GWEN_LOGDOMAIN, GWEN_LoggerLevel_Error);
}

//******************* Im-/Exporter *****
-(NSArray*)getImExporters
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:10 ];
	GWEN_PLUGIN_DESCRIPTION_LIST2	*il = AB_Banking_GetImExporterDescrs(ab);
	if (il) {
		GWEN_PLUGIN_DESCRIPTION_LIST2_ITERATOR *it = GWEN_PluginDescription_List2_First(il);
		if (it) {
			GWEN_PLUGIN_DESCRIPTION *pd = GWEN_PluginDescription_List2Iterator_Data(it);
			while (pd) {
				const char *c;
				ImExporter *ie = [[[ImExporter alloc ] init ] autorelease ];
				ie.name = [NSString stringWithUTF8String: (c = GWEN_PluginDescription_GetName(pd)) ? c: ""];
				ie.description = [NSString stringWithUTF8String: (c = GWEN_PluginDescription_GetShortDescr(pd)) ? c: ""];
				ie.longDescription = [NSString stringWithUTF8String: (c = GWEN_PluginDescription_GetLongDescr(pd)) ? c: ""];
				
				NSMutableArray *profiles = [NSMutableArray arrayWithCapacity:10 ];
				
				GWEN_DB_NODE *node = AB_Banking_GetImExporterProfiles(ab, GWEN_PluginDescription_GetName(pd));
				if(node) {
					GWEN_DB_NODE *group = GWEN_DB_GetFirstGroup(node);
					while (group) {
						ImExporterProfile *profile = [[[ImExporterProfile alloc ] init ] autorelease ];
						GWEN_DB_NODE *var = GWEN_DB_FindFirstVar(group, "name");
						if (var) {
							GWEN_DB_NODE *val = GWEN_DB_GetFirstValue(var);
							if (val) {
								const char *c = GWEN_DB_GetCharValueFromNode(val);
								if (c) {
									profile.name = [NSString stringWithUTF8String: c ];
								} 
							} 
						} 
						
						var = GWEN_DB_FindFirstVar(group, "shortDescr");
						if (var) {
							GWEN_DB_NODE *val = GWEN_DB_GetFirstValue(var);
							if (val) {
								const char *c = GWEN_DB_GetCharValueFromNode(val);
								if (c) {
									profile.shortDescription = [NSString stringWithUTF8String: c ];
								}
							}
						}
						
						var = GWEN_DB_FindFirstVar(group, "longDescr");
						if (var) {
							GWEN_DB_NODE *val = GWEN_DB_GetFirstValue(var);
							if (val) {
								const char *c = GWEN_DB_GetCharValueFromNode(val);
								if (c) {
									profile.longDescription = [NSString stringWithUTF8String: c ];
								}
							}
						}
						
						if (profile.name) [profiles addObject:profile ];
						group = GWEN_DB_GetNextGroup(group);
					}
				}
				
				ie.profiles = profiles;
				[result addObject:ie ];
				pd = GWEN_PluginDescription_List2Iterator_Next(it);
			}
			GWEN_PluginDescription_List2Iterator_free(it);
		}
		GWEN_PluginDescription_List2_free(il);
	}
	return result;
}

-(void)importForAccounts:(NSMutableArray*)selAccounts module:(ImExporter*)ie profile:(ImExporterProfile*)iep dataFile:(NSString*)file 
{	
	AB_IMEXPORTER_CONTEXT *ctx = AB_ImExporterContext_new();
	int rv = AB_Banking_ImportFileWithProfile (ab, [ie.name UTF8String ], ctx, [iep.name UTF8String ],NULL, [file UTF8String ]);
	if (rv == 0) {
		[self processContext:ctx forAccounts:selAccounts ];
	}
}

+(ABController*)controller { return abController; }

@end
