/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef AO_ACCOUNT_H
#define AO_ACCOUNT_H

#include <aqbanking/account_be.h>
#include <aqofxconnect/provider.h>


#ifdef __cplusplus
extern "C" {
#endif


AQOFXCONNECT_API void AO_Account_Extend(AB_ACCOUNT *a, AB_PROVIDER *pro,
					AB_PROVIDER_EXTEND_MODE em,
					GWEN_DB_NODE *dbBackend);

AQOFXCONNECT_API int AO_Account_GetMaxPurposeLines(const AB_ACCOUNT *a);
AQOFXCONNECT_API void AO_Account_SetMaxPurposeLines(AB_ACCOUNT *a, int i);

AQOFXCONNECT_API int AO_Account_GetDebitAllowed(const AB_ACCOUNT *a);
AQOFXCONNECT_API void AO_Account_SetDebitAllowed(AB_ACCOUNT *a, int i);



#ifdef __cplusplus
}
#endif


#endif
