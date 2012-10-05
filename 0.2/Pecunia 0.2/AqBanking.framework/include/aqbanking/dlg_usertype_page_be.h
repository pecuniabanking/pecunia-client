/***************************************************************************
 begin       : Fri Jul 30 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AB_DLG_USERTYPE_PAGE_BE_H
#define AB_DLG_USERTYPE_PAGE_BE_H


#include <aqbanking/banking.h>

#include <gwenhywfar/dialog.h>


#ifdef __cplusplus
extern "C" {
#endif


/**
 * This is the base class for a user setup type page.
 * It is the page shown after the user selected a backend for which a new user is to
 * be created. This page will then allow the user to choose the type of user setup.
 * For HBCI there are many options (like PinTan, chipcard, keyfile etc). For others
 * there might be only one option.
 */
AQBANKING_API GWEN_DIALOG *AB_UserTypePageDialog_new(AB_BANKING *ab, const char *dname);

AQBANKING_API AB_BANKING *AB_UserTypePageDialog_GetBanking(const GWEN_DIALOG *dlg);

AQBANKING_API int AB_UserTypePageDialog_GetSelectedType(const GWEN_DIALOG *dlg);
AQBANKING_API void AB_UserTypePageDialog_SetSelectedType(GWEN_DIALOG *dlg, int t);


#ifdef __cplusplus
}
#endif



#endif

