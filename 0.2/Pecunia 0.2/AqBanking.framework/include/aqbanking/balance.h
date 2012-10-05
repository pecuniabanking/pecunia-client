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


#ifndef AQBANKING_BALANCE_H
#define AQBANKING_BALANCE_H

#include <gwenhywfar/gwentime.h>
#include <aqbanking/value.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AB_BALANCE AB_BALANCE;

AQBANKING_API 
AB_BALANCE *AB_Balance_new(const AB_VALUE *v, const GWEN_TIME *t);
AQBANKING_API 
AB_BALANCE *AB_Balance_fromDb(GWEN_DB_NODE *db);
AQBANKING_API 
int AB_Balance_toDb(const AB_BALANCE *b, GWEN_DB_NODE *db);

AQBANKING_API 
AB_BALANCE *AB_Balance_dup(const AB_BALANCE *b);
AQBANKING_API 
void AB_Balance_free(AB_BALANCE *b);

AQBANKING_API 
const AB_VALUE *AB_Balance_GetValue(const AB_BALANCE *b);
AQBANKING_API 
void AB_Balance_SetValue(AB_BALANCE *b, const AB_VALUE *v);
AQBANKING_API 
const GWEN_TIME *AB_Balance_GetTime(const AB_BALANCE *b);

#ifdef __cplusplus
}
#endif

#endif /* AQBANKING_BALANCE_H */


