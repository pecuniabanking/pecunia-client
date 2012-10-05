/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_ACCOUNT_H
#define AQBANKING_ACCOUNT_H

#include <gwenhywfar/misc.h>
#include <gwenhywfar/list2.h>
#include <gwenhywfar/inherit.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/stringlist.h>
#include <aqbanking/error.h> /* for AQBANKING_API */


/** @addtogroup G_AB_ACCOUNT Accounts
 *
 * @brief This group represents accounts.
 *
 * Accounts are only created by AB_PROVIDERs, not by the application.
 *
 * Please note: Changing any of the attributes of an account permanently requires
 * calling @ref AB_Banking_BeginExclUseAccount() before the modifications
 * and @ref AB_Banking_EndExclUseAccount() afterwards.
 * This locking makes sure that concurrent access to the settings doesn't corrupt
 * the configuration database.
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif


typedef struct AB_ACCOUNT AB_ACCOUNT;
GWEN_INHERIT_FUNCTION_LIB_DEFS(AB_ACCOUNT, AQBANKING_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(AB_ACCOUNT, AB_Account, AQBANKING_API)
/* Do not terminate these lines with semicolon because they are
   macros, not functions, and ISO C89 does not allow a semicolon
   there. */
void AB_Account_List2_FreeAll(AB_ACCOUNT_LIST2 *al);

typedef enum {
  AB_AccountType_Unknown=0,
  AB_AccountType_Bank,
  AB_AccountType_CreditCard,
  AB_AccountType_Checking,
  AB_AccountType_Savings,
  AB_AccountType_Investment,
  AB_AccountType_Cash,
  AB_AccountType_MoneyMarket
} AB_ACCOUNT_TYPE;

#ifdef __cplusplus
}
#endif


#include <aqbanking/banking.h>
#include <aqbanking/provider.h>
#include <aqbanking/job.h>
#include <aqbanking/user.h>


#ifdef __cplusplus
extern "C" {
#endif

AQBANKING_API 
void AB_Account_free(AB_ACCOUNT *acc);

AQBANKING_API 
AB_BANKING *AB_Account_GetBanking(const AB_ACCOUNT *acc);

AQBANKING_API 
AB_ACCOUNT_TYPE AB_Account_GetAccountType(const AB_ACCOUNT *acc);
AQBANKING_API 
void AB_Account_SetAccountType(AB_ACCOUNT *acc, AB_ACCOUNT_TYPE t);

AQBANKING_API 
uint32_t AB_Account_GetUniqueId(const AB_ACCOUNT *acc);

AQBANKING_API
void AB_Account_SetUniqueId(AB_ACCOUNT *acc, uint32_t id);

AQBANKING_API 
const char *AB_Account_GetBackendName(const AB_ACCOUNT *acc);


AQBANKING_API 
AB_PROVIDER *AB_Account_GetProvider(const AB_ACCOUNT *acc);

AQBANKING_API 
const char *AB_Account_GetAccountNumber(const AB_ACCOUNT *acc);
AQBANKING_API 
void AB_Account_SetAccountNumber(AB_ACCOUNT *acc, const char *s);

AQBANKING_API 
const char *AB_Account_GetBankCode(const AB_ACCOUNT *acc);
AQBANKING_API 
void AB_Account_SetBankCode(AB_ACCOUNT *acc, const char *s);

/** Returns the name of the account product (really:
 "Kontoproduktbezeichnung" according to HBCI spec). This may or
 may not be useful for your application. The bank may freely
 choose what to say in here. */
AQBANKING_API 
const char *AB_Account_GetAccountName(const AB_ACCOUNT *acc);
AQBANKING_API 
void AB_Account_SetAccountName(AB_ACCOUNT *acc, const char *s);

/** Returns the name of the bank, or NULL if none was set. */
AQBANKING_API 
const char *AB_Account_GetBankName(const AB_ACCOUNT *acc);
AQBANKING_API 
void AB_Account_SetBankName(AB_ACCOUNT *acc, const char *s);

AQBANKING_API 
const char *AB_Account_GetIBAN(const AB_ACCOUNT *a);
AQBANKING_API 
void AB_Account_SetIBAN(AB_ACCOUNT *a, const char *s);


AQBANKING_API 
const char *AB_Account_GetBIC(const AB_ACCOUNT *a);
AQBANKING_API 
void AB_Account_SetBIC(AB_ACCOUNT *a, const char *s);


AQBANKING_API 
const char *AB_Account_GetOwnerName(const AB_ACCOUNT *acc);
AQBANKING_API
void AB_Account_SetOwnerName(AB_ACCOUNT *acc, const char *s);

AQBANKING_API 
const char *AB_Account_GetCurrency(const AB_ACCOUNT *acc);

AQBANKING_API 
void AB_Account_SetCurrency(AB_ACCOUNT *acc, const char *s);

/**
 * Returns the two-character ISO 3166 country code ("de" for Germany).
 */
AQBANKING_API 
const char *AB_Account_GetCountry(const AB_ACCOUNT *acc);

AQBANKING_API
void AB_Account_SetCountry(AB_ACCOUNT *acc, const char *s);

/**
 * Returns a stringlist containing the unique ids of the users assigned to
 * this account. The caller is responsible for freeing the list returned
 * (if any).
 */
AQBANKING_API
AB_USER_LIST2 *AB_Account_GetUsers(const AB_ACCOUNT *acc);

AQBANKING_API
AB_USER *AB_Account_GetFirstUser(const AB_ACCOUNT *acc);

AQBANKING_API
void AB_Account_SetUsers(AB_ACCOUNT *acc, const AB_USER_LIST2 *ul);

AQBANKING_API
void AB_Account_SetUser(AB_ACCOUNT *acc, const AB_USER *u);


AQBANKING_API
AB_USER_LIST2 *AB_Account_GetSelectedUsers(const AB_ACCOUNT *acc);

AQBANKING_API
AB_USER *AB_Account_GetFirstSelectedUser(const AB_ACCOUNT *acc);

AQBANKING_API
void AB_Account_SetSelectedUsers(AB_ACCOUNT *acc, const AB_USER_LIST2 *ul);

AQBANKING_API
void AB_Account_SetSelectedUser(AB_ACCOUNT *a, const AB_USER *u);


#ifdef __cplusplus
}
#endif


/*@}*/ /* defgroup */


#endif /* AQBANKING_ACCOUNT_H */
