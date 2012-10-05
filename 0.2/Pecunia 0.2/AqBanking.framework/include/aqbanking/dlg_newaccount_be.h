/***************************************************************************
 begin       : Wed Apr 14 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AB_DLG_NEW_ACCOUNT_BE_H
#define AB_DLG_NEW_ACCOUNT_BE_H


#include <aqbanking/banking.h>
#include <aqbanking/account.h>

#include <gwenhywfar/dialog.h>


#ifdef __cplusplus
extern "C" {
#endif



AQBANKING_API GWEN_DIALOG *AB_NewAccountDialog_new(AB_BANKING *ab, const char *dname);

AQBANKING_API AB_ACCOUNT *AB_NewAccountDialog_GetAccount(const GWEN_DIALOG *dlg);
AQBANKING_API void AB_NewAccountDialog_SetAccount(GWEN_DIALOG *dlg, AB_ACCOUNT *a);


#ifdef __cplusplus
}
#endif



#endif

