/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Apr 05 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_ACCSTATUS_H
#define AQBANKING_ACCSTATUS_H

#include <aqbanking/value.h>
#include <aqbanking/balance.h>

#include <gwenhywfar/gwentime.h>
#include <gwenhywfar/list2.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef struct AB_ACCOUNT_STATUS AB_ACCOUNT_STATUS;

GWEN_LIST2_FUNCTION_LIB_DEFS(AB_ACCOUNT_STATUS, AB_AccountStatus,
                             AQBANKING_API)


AQBANKING_API 
AB_ACCOUNT_STATUS *AB_AccountStatus_new();
AQBANKING_API 
AB_ACCOUNT_STATUS *AB_AccountStatus_dup(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
AB_ACCOUNT_STATUS *AB_AccountStatus_fromDb(GWEN_DB_NODE *db);
AQBANKING_API 
int AB_AccountStatus_toDb(const AB_ACCOUNT_STATUS *as, GWEN_DB_NODE *db);

AQBANKING_API 
void AB_AccountStatus_free(AB_ACCOUNT_STATUS *as);


AQBANKING_API 
const GWEN_TIME*
  AB_AccountStatus_GetTime(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
void AB_AccountStatus_SetTime(AB_ACCOUNT_STATUS *as,
                              const GWEN_TIME *t);
AQBANKING_API 
const AB_VALUE*
  AB_AccountStatus_GetBankLine(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
void AB_AccountStatus_SetBankLine(AB_ACCOUNT_STATUS *as,
                                  const AB_VALUE *v);

AQBANKING_API 
const AB_VALUE*
  AB_AccountStatus_GetDisposable(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
void AB_AccountStatus_SetDisposable(AB_ACCOUNT_STATUS *as,
                                    const AB_VALUE *v);

AQBANKING_API 
const AB_VALUE*
  AB_AccountStatus_GetDisposed(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
void AB_AccountStatus_SetDisposed(AB_ACCOUNT_STATUS *as,
                                  const AB_VALUE *v);

AQBANKING_API 
const AB_BALANCE*
  AB_AccountStatus_GetBookedBalance(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
void AB_AccountStatus_SetBookedBalance(AB_ACCOUNT_STATUS *as,
                                       const AB_BALANCE *b);

AQBANKING_API 
const AB_BALANCE*
  AB_AccountStatus_GetNotedBalance(const AB_ACCOUNT_STATUS *as);
AQBANKING_API 
void AB_AccountStatus_SetNotedBalance(AB_ACCOUNT_STATUS *as,
                                      const AB_BALANCE *b);


AQBANKING_API 
void AB_AccountStatus_List2_freeAll(AB_ACCOUNT_STATUS_LIST2 *asl);


#ifdef __cplusplus
}
#endif


#endif /* AQBANKING_ACCSTATUS_H */


