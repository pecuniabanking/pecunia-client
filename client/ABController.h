//
//  ABController.h
//  MacBanking
//
//  Created by Frank Emminghaus on 03.01.07.
//  Copyright 2007 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <aqbanking/banking.h>
#include <gwenhywfar/gui.h>
#import "ABAccount.h"

@class ABInputWindowController;
@class ABInfoBoxController;
@class ABProgressWindowController;
@class BankAccount;
@class Transfer;
@class User;
@class TransactionLimits;
@class BankInfo;

@interface ABController : NSObject {

	NSMutableDictionary		*boxes;
    unsigned int			handle;
	unsigned int			lastHandle;
	AB_BANKING				*ab;
	GWEN_GUI				*gui;
	NSMutableArray			*accounts;
	NSMutableArray			*users;
	NSMutableDictionary		*passwords;
	NSMutableDictionary		*countries;
	NSManagedObjectContext	*context;

}
-(id)initWithContext: (NSManagedObjectContext *)con;
-(unsigned int)addInfoBox: (ABInfoBoxController *)x;
-(unsigned int)addLogBox: (ABProgressWindowController *)x;
-(void)hideInfoBox: (unsigned int)n;
-(void)hideLogBox: (unsigned int)n;
-(ABProgressWindowController*)getLogBox: (unsigned int)n;
-(NSMutableArray*)getAccounts;
-(NSMutableArray*)accounts;
-(NSMutableArray*)getUsers;
-(NSMutableArray*)users;
-(ABAccount*)accountByNumber: (NSString*)n bankCode: (NSString*)c;
-(BOOL)checkAccount: (NSString*)accountNumber forBank: (NSString*)bankCode inCountry: (NSString*)country;
-(BOOL)addAccount: (ABAccount*)account forUser: (User*)user;
-(BOOL)deleteAccount: (ABAccount*)account;
-(BOOL)sendTransfers: (NSArray*)transfers;
-(void)initAB: (AB_TRANSACTION*)t fromTransfer: (Transfer*)transfer;
-(BOOL)checkIBAN: (NSString*)iban;
-(void)statementsForAccounts: (NSArray*)selAccounts;
-(void)save;

-(AB_BANKING*)abBankingHandle;

-(NSString*)bankNameForCode: (NSString*)bankCode inCountry: (NSString*)country;
-(NSString*)bankNameForBic: (NSString*)bic inCountry: (NSString*)country;
-(BankInfo*)infoForBankCode: (NSString*)code inCountry: (NSString*)country;

-(NSString*)addBankUser: (User*)user;
-(BOOL)removeBankUser: (User*)user;
-(NSString*)getSystemIDForUser: (User*)user;

// security
-(void)setPassword: (NSString*)pwd forToken: (NSString*)token;
-(NSString*)passwordForToken: (NSString*)token;
-(void)clearCache;
-(void)clearCacheForToken: (NSString*)token;
-(void)clearKeyChain;

-(NSDictionary*)countries;


+(ABController*)abController;
@end
