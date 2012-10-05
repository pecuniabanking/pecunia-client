/***************************************************************************
 begin       : Wed Apr 14 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AB_DLG_NEW_USER_BE_H
#define AB_DLG_NEW_USER_BE_H


#include <aqbanking/banking.h>
#include <aqbanking/user.h>

#include <gwenhywfar/dialog.h>


#ifdef __cplusplus
extern "C" {
#endif



AQBANKING_API GWEN_DIALOG *AB_NewUserDialog_new(AB_BANKING *ab, const char *dname);

AQBANKING_API AB_BANKING *AB_NewUserDialog_GetBanking(const GWEN_DIALOG *dlg);

AQBANKING_API AB_USER *AB_NewUserDialog_GetUser(const GWEN_DIALOG *dlg);
AQBANKING_API void AB_NewUserDialog_SetUser(GWEN_DIALOG *dlg, AB_USER *u);


#ifdef __cplusplus
}
#endif



#endif

