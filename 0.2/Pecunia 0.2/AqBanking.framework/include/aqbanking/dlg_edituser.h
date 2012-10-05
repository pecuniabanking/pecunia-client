/***************************************************************************
 begin       : Fri Apr 16 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQBANKING_EDITUSER_DIALOG_H
#define AQBANKING_EDITUSER_DIALOG_H


#include <aqbanking/banking.h>
#include <aqbanking/user.h>

#include <gwenhywfar/dialog.h>


#ifdef __cplusplus
extern "C" {
#endif



AQBANKING_API GWEN_DIALOG *AB_EditUserDialog_new(AB_BANKING *ab, AB_USER *u, int doLock);




#ifdef __cplusplus
}
#endif



#endif

