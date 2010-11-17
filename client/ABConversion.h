//
//  ABConversion.h
//  Pecunia
//
//  Created by Frank Emminghaus on 31.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <aqbanking/banking.h>
#import <aqbanking/eutransferinfo.h>

@class ABUser;
@class Country;
@class BankInfo;
@class BankAccount;
@class TransactionLimits;
@class ABAccount;
@class Transfer;

ABUser *convertUser(AB_USER *user);
BankInfo *convertBankInfo(AB_BANKINFO *bi);
Country *convertCountry(const AB_COUNTRY* cnty);
void convertToAccount(BankAccount *account, AB_ACCOUNT *acc);
ABAccount *convertAccount(AB_ACCOUNT *acc);
TransactionLimits *convertLimits(const AB_TRANSACTION_LIMITS *t);
TransactionLimits *convertEULimits(const AB_EUTRANSFER_INFO* t);
AB_TRANSACTION *convertTransfer(Transfer *transfer);
NSDecimalNumber *convertValue(const AB_VALUE *val);

