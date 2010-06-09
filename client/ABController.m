//
//  ABController.m
//  MacBanking
//
//  Created by Frank Emminghaus on 03.01.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//
#include <gwenhywfar/gui_be.h>

#import "ABController.h"
#import "ABInputWindowController.h"
#import "ABInfoBoxController.h"
#import "ABProgressWindowController.h"
#import "ABAccount.h"
#import "User.h"
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

static ABController* abController;
static GWEN_GUI_CHECKCERT_FN	standardCertFn;

int MessageBox(
			GWEN_GUI	*gui,
			uint32_t   flags,
			const char *title,
			const char *text,
			const char *b1,
			const char *b2,
			const char *b3,
			uint32_t	guiid	) {
	
	NSRange range;
	NSString *sText;
	
	sText = [NSString stringWithUTF8String: text];
	range = [sText rangeOfString: @"<html>" ];
	if(range.location == NSNotFound) range.location = [sText length ];
	
	return NSRunAlertPanel([NSString stringWithUTF8String: title],
						   [sText substringToIndex: range.location],
						   b1 ? [NSString stringWithUTF8String: b1] : nil,
						   b2 ? [NSString stringWithUTF8String: b2] : nil,
						   b3 ? [NSString stringWithUTF8String: b3] : nil); 
}

int GetPassword (
			GWEN_GUI	*gui,
			uint32_t 	flags,
			const char	*token,
			const char	*title,
			const char	*text,
			char		*buffer,
			int			minLen,
			int			maxLen,
			uint32_t	guiid
			) 	
{
	int		res;
	BOOL	savePin = NO;
	
	// if PIN, try to retrieve saved PIN
	if(!(flags & GWEN_GUI_INPUT_FLAGS_TAN)) {
		if(token) {
			NSString*	passwd = [abController passwordForToken: [NSString stringWithUTF8String: token ] ];
			if(passwd) { strncpy(buffer, [passwd UTF8String ], maxLen); return 0; }
		}
		
		// Check keychain
		NSString* passwd = [Keychain passwordForService: @"Pecunia PIN" account: [NSString stringWithUTF8String: token ] ];
		if(passwd) {
			strncpy(buffer, [passwd UTF8String ], maxLen); 
			[abController setPassword: [NSString stringWithUTF8String: buffer ] forToken: [NSString stringWithUTF8String: token ] ];
			return 0;
		}
		
		// issue Password window
		NSRange  range;
		NSString *sText;
		
		sText = [NSString stringWithUTF8String: text];
		range = [sText rangeOfString: @"<html>" ];
		if(range.location == NSNotFound) range.location = [sText length ];
		
		PasswordWindow *pwWindow = [[PasswordWindow alloc] initWithText: [sText substringToIndex: range.location]
																  title: [NSString stringWithUTF8String: title]];
		
		res = [NSApp runModalForWindow: [pwWindow window]];
		if(res == 0) {
			const char* r = [[pwWindow result] UTF8String];
			strncpy(buffer, r, maxLen);
			if([pwWindow shouldSavePassword ]) savePin = YES;
		}
		[pwWindow release ];
		
	} else res=InputBox(gui, flags, title, text, buffer, minLen, maxLen);
	
	// if PIN, save it
	if(!(flags & GWEN_GUI_INPUT_FLAGS_TAN)) {
		if(res == 0 && token) {
			[abController setPassword: [NSString stringWithUTF8String: buffer ] forToken: [NSString stringWithUTF8String: token ] ];
			// save at keychain, if wanted
			if(savePin) {
				[Keychain setPassword: [NSString stringWithUTF8String: buffer ] forService: @"Pecunia PIN" account: [NSString stringWithUTF8String: token ] ];
			}
		}
	}
	return res;
}


int CheckCert(
			  GWEN_GUI *gui,
			  const GWEN_SSLCERTDESCR *cert,
			  GWEN_IO_LAYER *io,
			  uint32_t guiid)
{
	const char	*hash = GWEN_SslCertDescr_GetFingerPrint(cert);
	uint32		status = GWEN_SslCertDescr_GetStatusFlags(cert);
	NSMutableString	*certID = [NSMutableString stringWithUTF8String: hash ];
	[certID appendString: @"/" ];
	[certID appendString: [NSString stringWithFormat: @"%x", (int)status  ] ];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL accept = [defaults boolForKey: certID ];
	if(accept) return 0;
	
	int res = standardCertFn(gui, cert, io, guiid);
	if(res == 0) [defaults setBool: YES forKey: certID ];
	
	return res;
}


int InputBox(
     		GWEN_GUI	*gui,
			uint32_t	flags, 
			const char	*title, 
			const char	*text, 
			char		*buffer, 
			int			minLen, 
			int			maxLen,
			uint32_t	guiid)
{
	int      res;
	NSRange  range;
	NSString *sText;
	
	sText = [NSString stringWithUTF8String: text];
	range = [sText rangeOfString: @"<html>" ];
	if(range.location == NSNotFound) range.location = [sText length ];
		
	ABInputWindowController *abInputController = [[ABInputWindowController alloc] 
												 initWithText: [sText substringToIndex: range.location]
													    title: [NSString stringWithUTF8String: title]];
	
	
	res = [NSApp runModalForWindow: [abInputController window]];
    const char* r = [[abInputController result] UTF8String];
	strncpy(buffer, r, maxLen);
	[abInputController release ];
	return res;
}

uint32_t ShowBox(
			GWEN_GUI		*gui,
			uint32_t		flags, 
			const char		*title, 
			const char		*text,
			uint32_t		guiid)
{
	unsigned int n;
	
	ABInfoBoxController* abBoxController = [[ABInfoBoxController alloc] 
											initWithText:[NSString stringWithUTF8String: text]
												   title: [NSString stringWithUTF8String: title]];
	[abBoxController showWindow: nil];
	n = [abController addInfoBox: abBoxController];
	return (uint32_t)n;
}

void HideBox(GWEN_GUI *gui, uint32_t n)
{
	[abController hideInfoBox: (unsigned int)n];
}



uint32_t ProgressStart(
					GWEN_GUI	*gui,
					uint32_t	progressFlags,
				    const char	*title, 
					const char	*text,
					uint64_t	total,
					uint32_t	guiid)
{
	unsigned int n;
	
	if(progressFlags & GWEN_GUI_PROGRESS_DELAY) return (uint32_t)20;

	ABProgressWindowController *abProgressController = [[ABProgressWindowController alloc] 
													   initWithText: [NSString stringWithUTF8String: text?text:""] 
															  title: [NSString stringWithUTF8String: title?title:""]];
	
	if(progressFlags & GWEN_GUI_PROGRESS_KEEP_OPEN) [abProgressController setKeepOpen: TRUE ];
	[abProgressController setProgressMaxValue: (double)total];
	if(progressFlags & GWEN_GUI_PROGRESS_SHOW_LOG == 0) [abProgressController hideLog ];
	if(progressFlags & GWEN_GUI_PROGRESS_SHOW_PROGRESS == 0) [abProgressController hideProgressIndicator ];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults ];
	BOOL hideProgressWindow = [defaults boolForKey: @"hideProgressWindow" ];
	if(!hideProgressWindow)	[abProgressController showWindow: nil];
	n = [abController addLogBox: abProgressController];
	return (uint32_t)n;
}

int ProgressAdvance(
					GWEN_GUI	*gui,
					uint32_t	handle,
					uint64_t	progress)
{
	ABProgressWindowController *bc;
	
	if(handle == 20) return 0;
	bc = [abController getLogBox: (unsigned int)handle];
    if(progress != GWEN_GUI_PROGRESS_NONE) [bc setProgressCurrentValue: (double)progress];
	return 0;
}

int ProgressLog(
				GWEN_GUI			*gui,
				uint32_t			handle,
				GWEN_LOGGER_LEVEL	level,
				const char			*text)
{
	ABProgressWindowController  *bc;
	
	if(handle == 20) return 0;
	bc = [abController getLogBox: (unsigned int)handle];
	[bc addLog: [NSString stringWithUTF8String: text] withLevel: level ];
	return 0;
}
	
int ProgressEnd(GWEN_GUI *gui, uint32_t handle)
{
	if(handle == 20) return 0;
	[abController hideLogBox: (unsigned int)handle];
	return 0;
}

int SetPasswordStatus(GWEN_GUI *gui,
					  const char *token,
					  const char *pin,
					  GWEN_GUI_PASSWORD_STATUS status,
					  uint32_t guiid) 
{
	if (token==NULL && pin==NULL && status==GWEN_Gui_PasswordStatus_Remove) [abController clearCache ];
	else {
		if(status == GWEN_Gui_PasswordStatus_Remove || status == GWEN_Gui_PasswordStatus_Bad) {
			NSRunCriticalAlertPanel(NSLocalizedString(@"AP66", @""),
									NSLocalizedString(@"AP67", @""),
									NSLocalizedString(@"ok", @"Ok"),
									nil,
									nil,
									[NSString stringWithUTF8String: token],
									[NSString stringWithUTF8String: pin]
									);
									
			[abController clearCacheForToken: [NSString stringWithUTF8String: token] ];
		}
	}
	return 0;
}	

int Print(GWEN_GUI		*gui,
		  const char	*docTitle,
	      const char	*docType,
		  const char	*descr,
		  const char	*text,
		  uint32_t		guiid)
{
	return 0;
}

//------------------------------------------------------
/*
int AlwaysAskForCert(const AB_BANKING *ab)
{
	// to be enhanced
	return 1;
}


int PinCacheEnabled(const AB_BANKING *ab)
{
	// to be enhanced
	return 0;
}

int SetPinStatus(AB_BANKING *ab,
				 const char *token,
				 const char *pin,
				 AB_BANKING_PINSTATUS status)
{
	return 0;
}

int SetTanStatus(AB_BANKING *ab,
				 const char *token,
				 const char *pin,
				 AB_BANKING_TANSTATUS status)
{
	return 0;
}
*/
		
@interface ABController()
-(void)restoreAqConfig;
-(void)saveAqConfig;
@end

//**************************************************************************************************
@implementation ABController


-(id)init
{
	int rv;
	
	[super init ];
	boxes		= [[NSMutableDictionary dictionaryWithCapacity: 10] retain];
	accounts	= [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	users		= [[NSMutableArray arrayWithCapacity: 10 ] retain ];
	handle = 1;
	abController = self;

	// restore destroyed AqConfig if necessary
	[self restoreAqConfig ];
	
	ab = AB_Banking_new("MacBanking", 0, 0);
	gui = GWEN_Gui_new();
	GWEN_Gui_SetGui(gui);
	
	GWEN_Gui_SetHideBoxFn(gui, HideBox);
	GWEN_Gui_SetInputBoxFn(gui, InputBox);
	GWEN_Gui_SetMessageBoxFn(gui, MessageBox);
	GWEN_Gui_SetPrintFn(gui, Print);
	GWEN_Gui_SetProgressAdvanceFn(gui, ProgressAdvance);
	GWEN_Gui_SetProgressEndFn(gui, ProgressEnd);
	GWEN_Gui_SetProgressLogFn(gui, ProgressLog);
	GWEN_Gui_SetProgressStartFn(gui, ProgressStart);
	GWEN_Gui_SetGetPasswordFn(gui, GetPassword);
	GWEN_Gui_SetSetPasswordStatusFn(gui, SetPasswordStatus);
	standardCertFn = GWEN_Gui_SetCheckCertFn(gui, CheckCert);
	
//	AB_Banking_SetSetPinStatusFn(ab, SetPinStatus);
//	AB_Banking_SetSetTanStatusFn(ab, SetTanStatus);
	GWEN_Gui_SetShowBoxFn(gui, ShowBox);
//	AB_Banking_SetGetPinFn(ab, GetPin);
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
	
	return self;
}

-(NSString*)standardSwiftString: (NSString*)str
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

-(id)initWithContext: (NSManagedObjectContext*)con
{
	[self init ];
	context = con;
	return self;
}

-(unsigned int)addInfoBox: (ABInfoBoxController *)x
{
	unsigned int n = handle++;

	[boxes setObject: x forKey: [NSNumber numberWithUnsignedInt: n]];
	lastHandle = n;
	return n;
}

-(unsigned int)addLogBox: (ABProgressWindowController *)x
{
	unsigned int n = handle++;
	
	[boxes setObject: x forKey: [NSNumber numberWithUnsignedInt: n]];
	lastHandle = n;
	return n;
}

-(void)hideInfoBox: (unsigned int)n
{
	unsigned int x;
	ABInfoBoxController	*bc;
	
	if(!n) x = lastHandle; else x = n;
	bc = [boxes objectForKey: [NSNumber numberWithUnsignedInt: x]];
	[boxes removeObjectForKey: [NSNumber numberWithUnsignedInt: x]];
	[bc close];
	[bc release];
}
	
	
-(void)hideLogBox: (unsigned int)n
{
	unsigned int x;
	ABProgressWindowController	*bc;
	
	if(!n) x = lastHandle; else x = n;
	bc = [boxes objectForKey: [NSNumber numberWithUnsignedInt: x]];
	[boxes removeObjectForKey: [NSNumber numberWithUnsignedInt: x]];
	if([bc stop] == FALSE) [bc release ];
}

-(ABProgressWindowController*)getLogBox: (unsigned int)n
{
	unsigned int x;
	
	if(!n) x = lastHandle; else x = n;
	return [boxes objectForKey: [NSNumber numberWithUnsignedInt: x]];
}

-(void)statementsForAccounts: (NSArray*)selAccounts
{
	AB_ACCOUNT				*a;
	AB_JOB_LIST2			*jl;
	AB_IMEXPORTER_CONTEXT	*ctx;
	ABAccount				*acc;
	int						rv;
	BankQueryResult			*res;
	
	jl=AB_Job_List2_new();
	
	for(res in selAccounts) {
		
		// create statement collection and add it to results
		NSMutableArray *stats = [NSMutableArray arrayWithCapacity: 100 ];
		res.statements = stats;
		
		// get Aq Object
		a = AB_Banking_GetAccountByCodeAndNumber(ab,
												 [res.bankCode cStringUsingEncoding: NSUTF8StringEncoding],
												 [res.accountNumber cStringUsingEncoding: NSUTF8StringEncoding]
												 );
		if (a) {
			AB_JOB			*j;

			/* create a job which retrieves balances */
			j=(AB_JOB*)AB_JobGetBalance_new(a);
			rv=AB_Job_CheckAvailability(j, 0);
			if (rv) {
				fprintf(stderr, "Job is not available (%d)\n", rv);
				goto error;
			}
			
			/* add job to this list */
			AB_Job_List2_PushBack(jl, j);
			
			/* create a job which retrieves transaction statements. */
			j=(AB_JOB*)AB_JobGetTransactions_new(a);
			rv=AB_Job_CheckAvailability(j, 0);
			if (rv) {
				fprintf(stderr, "Job is not available (%d)\n", rv);
				goto error;
			}
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
	rv=AB_Banking_ExecuteJobs(ab, jl, ctx, 0);
	if (rv) {
		fprintf(stderr, "Error on executeQueue (%d)\n", rv);
		goto error;
	}
	else {
		NSManagedObjectContext *memContext = [[MOAssistant assistant ] memContext ];
		[memContext reset ];
		
		AB_IMEXPORTER_ACCOUNTINFO *ai;
		
		ai=AB_ImExporterContext_GetFirstAccountInfo(ctx);
		while(ai) {
			const AB_TRANSACTION *t;
			
			NSString *accountNumber = [NSString stringWithUTF8String: AB_ImExporterAccountInfo_GetAccountNumber(ai) ];
			NSString *bankCode = [NSString stringWithUTF8String: AB_ImExporterAccountInfo_GetBankCode(ai) ];
			
			// find account
			acc = [self accountByNumber: accountNumber bankCode: bankCode];
			if(acc) {
				for(res in selAccounts) {
					if([res.accountNumber isEqualToString: accountNumber ] && [res.bankCode isEqualToString: bankCode ]) break;
				}
				
				t=AB_ImExporterAccountInfo_GetFirstTransaction(ai);
				while(t) {
					BankStatement *stmt = [NSEntityDescription insertNewObjectForEntityForName:@"BankStatement"
																		inManagedObjectContext:memContext];
					[stmt updateWithAB: t ];
					[res.statements addObject: stmt ];
					t=AB_ImExporterAccountInfo_GetNextTransaction(ai);
				} /* while transactions */
			

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
						res.balance = (NSDecimalNumber*)[NSDecimalNumber numberWithDouble: AB_Value_GetValueAsDouble(val) ];
					}
				}
            ai=AB_ImExporterContext_GetNextAccountInfo(ctx);
			}
		} /* while ai */
	} /* if executeQueue successfull */
	[[BankingController controller ] performSelectorOnMainThread: @selector(statementsNotification:) withObject: selAccounts waitUntilDone: YES ];
	return;
	
error:
	[[BankingController controller ] performSelectorOnMainThread: @selector(statementsNotification:) withObject: nil waitUntilDone: NO ];
	[selAccounts release ];
	return;
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
	
	jl=AB_Job_List2_new();
	for(i=0; i<[transfers count ]; i++) {
		t = AB_Transaction_new();
		Transfer *transfer = [transfers objectAtIndex: i ];
		
		// don't send already sent transfers again
		if( transfer == nil || [[transfer valueForKey: @"isSent" ] boolValue ] == YES) continue;
		
		[self initAB: t fromTransfer: transfer ];
		
		accountNumber = [transfer valueForKeyPath: @"account.accountNumber" ];
		bankCode = [transfer valueForKeyPath: @"account.bankCode" ];
		
		ABAccount	*acc = [self accountByNumber: accountNumber bankCode: bankCode ];
		if(!acc) {
			fprintf(stderr, "Account not found (%s)\n", [accountNumber UTF8String]);
			continue;
		}
		
		// create job of correct type
		tt = [[transfer valueForKey: @"type" ] intValue ];
		switch(tt) {
			case TransferTypeInternal:
				if([acc substInternalTransfers ] == NO) {
					j = (AB_JOB*)AB_JobInternalTransfer_new([acc abRef ]);
					AB_Job_CheckAvailability(j, 0);
					res = AB_JobInternalTransfer_SetTransaction(j, t);
					break;
				}
			case TransferTypeLocal:
				j = (AB_JOB*)AB_JobSingleTransfer_new([acc abRef ]);
				AB_Job_CheckAvailability(j, 0);
				res = AB_JobSingleTransfer_SetTransaction(j, t);
				break;
			case TransferTypeDated:
				j = (AB_JOB*)AB_JobCreateDatedTransfer_new([acc abRef ]);
				AB_Job_CheckAvailability(j, 0);
				res = AB_JobCreateDatedTransfer_SetTransaction(j, t);
				break;
			case TransferTypeEU:
				j = (AB_JOB*)AB_JobEuTransfer_new([acc abRef ]);
				AB_Job_CheckAvailability(j, 0);
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
	res=AB_Banking_ExecuteJobs(ab, jl, ctx, 0);
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

-(void)initAB: (AB_TRANSACTION*)t fromTransfer: (Transfer*)transfer
{
	NSString			*s, *accountNumber, *bankCode;
	ABAccount			*account;
	NSNumber			*n;
	AB_VALUE			*val;
	TransactionLimits	*limits;
	TransferType		tt = [[transfer valueForKey: @"type" ] intValue ];
	
	accountNumber = [transfer valueForKeyPath: @"account.accountNumber" ];
	bankCode = [transfer valueForKeyPath: @"account.bankCode" ];
	
	account = [self accountByNumber: accountNumber bankCode: bankCode ];    
	if(!account) {
		fprintf(stderr, "Account not found (%s)\n", [accountNumber UTF8String]);
		return;
	}
	
	AB_Transaction_SetLocalAccountNumber(t, [accountNumber UTF8String]);
	AB_Transaction_SetLocalBankCode(t, [bankCode UTF8String]);

	s = [account iban ];
	if(s) AB_Transaction_SetLocalIban(t, [s UTF8String ]);

	s = [account bic ];
	if(s) AB_Transaction_SetLocalBic(t, [s UTF8String ]);
	
	// splite remote name according to limits
	limits = [account limitsForType: tt country: [transfer valueForKey: @"remoteCountry" ] ];
	s = [transfer valueForKey: @"remoteName" ];
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
	
	s = [transfer valueForKey: @"remoteIBAN" ];
	if(s) AB_Transaction_SetRemoteIban(t, [s UTF8String ]);
	
	s = [transfer valueForKey: @"remoteBIC" ];
	if(s) AB_Transaction_SetRemoteBic(t, [s UTF8String ]);
	
	s = [transfer valueForKey: @"remoteAccount" ];
	if(s) AB_Transaction_SetRemoteAccountNumber(t, [s UTF8String ]);
	
	s = [transfer valueForKey: @"remoteBankCode" ];
	if(s) AB_Transaction_SetRemoteBankCode(t, [s UTF8String ]);
	
	s = [transfer valueForKey: @"remoteCountry" ];
	if(s) AB_Transaction_SetRemoteCountry(t, [s UTF8String ]);

	s = [transfer valueForKey: @"remoteBankName" ];
	s = [self standardSwiftString: s ];
	if(s) AB_Transaction_SetRemoteBankName(t, [s UTF8String ]);
	
	s = [transfer valueForKey: @"purpose1" ];
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = [transfer valueForKey: @"purpose2" ];
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = [transfer valueForKey: @"purpose3" ];
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = [transfer valueForKey: @"purpose4" ];
	if(s && [s length ] > 0) AB_Transaction_AddPurpose(t, [s UTF8String ], 0);
	
	s = [transfer valueForKey: @"currency" ];
	n = [transfer valueForKey: @"value" ];
	val = AB_Value_fromDouble([n doubleValue ]);
	if(!s || [s length ] == 0) AB_Value_SetCurrency(val, "EUR");
	else AB_Value_SetCurrency(val, [s UTF8String ]);
	
	// dated transfer
	if(tt == TransferTypeDated) {
		NSDate *date = [transfer valueForKey: @"valutaDate" ];
		GWEN_TIME *d = GWEN_Time_fromSeconds((unsigned int)[date timeIntervalSince1970 ]);
		AB_Transaction_SetValutaDate(t, d);
		AB_Transaction_SetDate(t, d);
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
}

-(NSMutableArray*)users
{
	return users;
}


-(NSMutableArray *)getUsers
{
	AB_USER_LIST2*  usr;
	User*			user;
	int				idx;
	
	usr=AB_Banking_GetUsers(ab);
	if(usr) {
		AB_USER_LIST2_ITERATOR *it;
		
		it=(AB_USER_LIST2_ITERATOR*)AB_User_List2_First(usr);
		if(it) {
			AB_USER *u;
			
			u=AB_User_List2Iterator_Data(it);
			while(u) 
			{
				user = [[[User alloc ] initWithAB: u ] autorelease ];
				if((idx = [users indexOfObject: user ]) == NSNotFound) [users addObject: user ];
				else {
					[[users objectAtIndex: idx ] setUser: u];
				}
				
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
	int					idx;

	accs=AB_Banking_GetAccounts(ab);
	if (accs) {
		AB_ACCOUNT_LIST2_ITERATOR *it;
		
		/* List2's are traversed using iterators. An iterator is an object
		* which points to a single element of a list.
		* If the list is empty NULL is returned.
		*/
		it=AB_Account_List2_First(accs);
		if (it) {
			const AB_ACCOUNT *a;
			
			/* this function returns a pointer to the element of the list to
			* which the iterator currently points to */
			a = AB_Account_List2Iterator_Data(it);
			while(a) {
				acc = [[[ABAccount alloc] initWithAB: a] autorelease ];
				
				// check wheter account already exists
				if((idx = [accounts indexOfObject: acc ]) == NSNotFound) [accounts addObject: acc];
				else {
					[[accounts objectAtIndex: idx ] setRef: a ];
				}
				
				a=AB_Account_List2Iterator_Next(it);
			}
			/* the iterator must be freed after using it */
			AB_Account_List2Iterator_free(it);
		}
		/* as discussed the list itself is only a container which has to be freed
			* after use. This explicitly does not free any of the elements in that
			* list, and it shouldn't because AqBanking still is the owner of the
			* accounts */
		AB_Account_List2_free(accs);
		
		
		[accounts sortUsingSelector: [ABAccount getCBBSelector]];
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
	
	[boxes release ];
	[users release ];
	[accounts release ];
	[countries release ];
	if(passwords) [passwords release ];
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
	   res == AB_BankInfoCheckResult_UnknownResult) return YES; else return NO;
}

-(AB_BANKING*)abBankingHandle
{
	return ab;
}

-(BankInfo*)infoForBankCode: (NSString*)code inCountry: (NSString*)country
{
	AB_BANKINFO		*bi;
	
	if(code == nil || [code isEqual: @"" ]) return nil;
	
	bi = AB_Banking_GetBankInfo(ab, [country UTF8String ], NULL, [code UTF8String ]);
	if(!bi) return nil;
	BankInfo *bankInfo = [[BankInfo alloc ] initWithAB: bi ];
	AB_BankInfo_free(bi);
	return [bankInfo autorelease];	
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

-(void)saveAqConfig
{
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSError *error;
	NSString *path = [ @"~/.aqbanking/settings.conf" stringByExpandingTildeInPath ];
	NSDictionary *attrs = [fm attributesOfItemAtPath: path error: &error ];
	if(!attrs) {
		NSLog(@"Error reading attributes of settings.conf: %@", [error localizedDescription ]);
		return;
	}
	NSNumber *nsize = [attrs objectForKey: NSFileSize ];
	if([nsize intValue ] < 5000) {
		NSLog(@"Save AqConfig failed: file size is too small (%@)", nsize);
		return;
	}
	//  now copy, delete old file if necessary
	NSString *destPath = [ @"~/.aqbanking/settings.conf.save" stringByExpandingTildeInPath ];
	if([fm fileExistsAtPath: destPath ]) {
		BOOL success = [fm removeItemAtPath: destPath error: &error ];
		if(!success) {
			NSLog(@"Deletion of backup file failed: %@", [error localizedDescription ]);
			return;
		}
	}
	BOOL success = [fm copyItemAtPath: path toPath: destPath error: &error ];
	if(!success) {
		NSLog(@"Copy of settings.conf failed: %@", [error localizedDescription ]);
		return;
	}
}

-(void)restoreAqConfig
{
	NSFileManager *fm = [NSFileManager defaultManager ];
	NSError *error;
	NSString *path = [ @"~/.aqbanking/settings.conf" stringByExpandingTildeInPath ];
	NSDictionary *attrs = [fm attributesOfItemAtPath: path error: &error ];
	if(!attrs) {
		NSLog(@"Restore AqConfig failed: %@", [error localizedDescription ]);
		return;
	}
	NSNumber *nsize = [attrs objectForKey: NSFileSize ];
	if([nsize intValue ] > 5000) {
		NSLog(@"Settings.conf seems to be o.k. (%@ Bytes)", nsize);
		return;
	}
	
	NSString *sourcePath = [ @"~/.aqbanking/settings.conf.save" stringByExpandingTildeInPath ];
	if([fm fileExistsAtPath: sourcePath ]) {
		BOOL success = [fm removeItemAtPath: path error: &error ];
		if(!success) {
			NSLog(@"Deletion of settings.conf failed: %@", [error localizedDescription ]);
			return;
		}
		
		success = [fm copyItemAtPath: sourcePath toPath: path error: &error ];
		if(!success) {
			NSLog(@"Copy of settings.conf failed: %@", [error localizedDescription ]);
			return;
		}
	}
}

-(NSString*)addBankUser: (User*)user
{
	char		*errmsg;
	int			rv;
	uint32_t	flags = 0;

	if([user forceSSL3 ]) flags = flags ^ AH_USER_FLAGS_FORCE_SSL3;
	int au = addUser( ab, [[user bankCode ] UTF8String], [[user userId ] UTF8String],
						  [[user customerId ] UTF8String], [[user mediumId ] UTF8String], [[user bankURL ] UTF8String], 
						  [[user name ] UTF8String ], 0 , flags, [[user hbciVersion ] intValue ], &errmsg );
	
	if( au != 0 )
	{
		return [NSString stringWithUTF8String: errmsg];
	}
	else
	{
		int si = getSysId( ab, [[user bankCode ] UTF8String], [[user userId ] UTF8String], [[user customerId ] UTF8String], &errmsg );
		if(si != 0) {
		// try again with forceSSL3
			AB_USER* usr = AB_Banking_FindUser(ab, "aqhbci", "de", [[user bankCode ] UTF8String],
											   [[user userId ] UTF8String], [[user customerId ] UTF8String]);
			if(usr) {
				uint32 flags = AH_User_GetFlags(usr);
				flags ^= AH_USER_FLAGS_FORCE_SSL3;
				AH_User_SetFlags(usr, flags);
				si = getSysId( ab, [[user bankCode ] UTF8String], [[user userId ] UTF8String], [[user customerId ] UTF8String], &errmsg );
			}
		}

		if( si != 0 )
		{			
			// delete user first
			AB_USER* usr = AB_Banking_FindUser(ab, "aqhbci", "de", [[user bankCode ] UTF8String],
											   [[user userId ] UTF8String], [[user customerId ] UTF8String]);
			if(usr) AB_Banking_DeleteUser(ab, usr);
			AB_Banking_Save(ab);
			return [NSString stringWithUTF8String: errmsg];
		}
		//AB_Banking_Save(ab);

		// workaround for AqBanking issue: getAccounts provides unproper data
		rv=AB_Banking_OnlineFini(ab);
		if (rv) return NSLocalizedString(@"AP40", @"");
		
		[self saveAqConfig ];
		
		rv=AB_Banking_OnlineInit(ab);
		if (rv) return NSLocalizedString(@"AP40", @"");

		[self getUsers ];
		[self getAccounts ];
	}
//	AB_Banking_Save(ab);
	return nil;
}

-(NSString*)getSystemIDForUser: (User*)user
{
	char		*errmsg;

	int si = getSysId( ab, [[user bankCode ] UTF8String], [[user userId ] UTF8String], [[user customerId ] UTF8String], &errmsg );
	if( si != 0 ) return [NSString stringWithUTF8String: errmsg];
	[self getAccounts ];
	AB_Banking_Save(ab);
	return nil;
}



-(void)setPassword: (NSString*)pwd forToken:(NSString*)token
{
	if(!passwords) passwords = [[NSMutableDictionary dictionaryWithCapacity: 5 ] retain ];
	[passwords setObject: pwd forKey: token ];
}

-(NSString*)passwordForToken: (NSString*)token
{
	if(!passwords) return nil;
	return [passwords valueForKey: token ];
}

-(void)clearCache
{
	[passwords release ];
	passwords = nil;
}

-(void)clearCacheForToken: (NSString*)token
{
	[passwords removeObjectForKey: token ];
	[Keychain deletePasswordForService: @"Pecunia PIN" account: token ];
}

-(BOOL)removeBankUser: (User*)user
{
	AB_USER*	usr = AB_Banking_GetUser(ab, (uint32_t)[user uid ]);
	int	i, res;
	
	if(!usr) return FALSE;
	AB_ACCOUNT*	acc = AB_Banking_FindFirstAccountOfUser(ab, usr);
	if(acc) {
		res = NSRunAlertPanel(NSLocalizedString(@"AP16", @"Warning"),
							  NSLocalizedString(@"AP17", @"There are still bank accounts assigned to the user. Do you want to delete the accounts as well?"),
							  NSLocalizedString(@"cancel", @"Cancel"),
							  NSLocalizedString(@"yes", @"Yes"),
							  NSLocalizedString(@"no", @"No")
							  );
//		if(res == NSAlertDefaultReturn || res == NSAlertOtherReturn) return FALSE;
		if(res == NSAlertDefaultReturn) return NO;
		// remove user from all accounts
		for(i=0; i < [accounts count ]; i++) {
			ABAccount *acc = [accounts objectAtIndex:i ];
			int n = [acc removeUser: user ];
			// if there is no user anymore for an account, delete it
			if(n == 0) {
				AB_Banking_DeleteAccount(ab, [acc abRef ]);
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
//		AB_Banking_Save(ab);
		return NO;
	}
	
	if(res == NSAlertAlternateReturn) {
		[[BankingController controller ] removeDeletedAccounts ];
	};
	
	//	AB_Banking_Save(ab);
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
			Country* country = [[Country alloc ] initWithAB: abCountry ];
			[countries setObject: country forKey: [country code ] ];
			
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

-(void)save
{
	AB_Banking_Save(ab);
}

-(BOOL)addAccount: (ABAccount*)account forUser: (User*)user
{
	int res;
	
	AB_ACCOUNT	*abAcc = AB_Banking_CreateAccount(ab, "aqhbci");
	if(abAcc == NULL) {
		fprintf(stderr, "Could not create bank account\n");
		return NO;
	}
	[account initAB: abAcc ];
	AB_USER	*abUser = AB_Banking_GetUser(ab, [user uid ]);
	if(abUser == NULL) {
		fprintf(stderr, "Could not find user %d\n", [user uid ]);
		return NO;
	}
	AB_Account_SetUser(abAcc, abUser);
	res = AB_Banking_AddAccount(ab, abAcc);
	if(res) {
		fprintf(stderr, "Error creating account: %d\n", res);
		return NO;
	}
	
	// add account internally
	ABAccount	*acc = [[ABAccount alloc] initWithAB: abAcc];
	// check wheter account already exists
	if( [accounts indexOfObject: acc ] == NSNotFound) [accounts addObject: acc];
	[accounts sortUsingSelector: [ABAccount getCBBSelector]];

	return YES;
}

-(BOOL)deleteAccount: (ABAccount*)account
{
	// remove account in backend
	if(account == nil || [account abRef ] == NULL) return YES;
	int res = AB_Banking_DeleteAccount(ab, [account abRef ]);
	if(res) return NO;
	[accounts removeObject: account ];
	return YES;
}

-(void)clearKeyChain
{
	[Keychain deletePasswordsForService: @"Pecunia PIN" ];
	[passwords release ];
	passwords = nil;
}

+(ABController*)abController { return abController; }

@end
