/***************************************************************************
 begin       : Thu Apr 15 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQBANKING_EDITACCOUNT_DIALOG_H
#define AQBANKING_EDITACCOUNT_DIALOG_H


#include <aqbanking/banking.h>
#include <aqbanking/account.h>

#include <gwenhywfar/dialog.h>


#ifdef __cplusplus
extern "C" {
#endif



AQBANKING_API GWEN_DIALOG *AB_EditAccountDialog_new(AB_BANKING *ab, AB_ACCOUNT *a, int doLock);




#ifdef __cplusplus
}
#endif



#endif

