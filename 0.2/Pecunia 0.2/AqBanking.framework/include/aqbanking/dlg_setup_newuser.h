/***************************************************************************
 begin       : Fri Jul 30 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQBANKING_DLG_SETUP_NEWUSER_H
#define AQBANKING_DLG_SETUP_NEWUSER_H


#include <gwenhywfar/dialog.h>

#include <aqbanking/banking.h>



/** @defgroup G_AB_DIALOGS_SETUP_NEWUSER Generic New User Dialog
 * @ingroup G_AB_DIALOGS
 *
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif



/**
 * Creates a user creation assistent.
 *
 * @return pointer to the created dialog.
 *
 * @param banking pointer to the AqBanking object

 */
AQBANKING_API GWEN_DIALOG *AB_SetupNewUserDialog_new(AB_BANKING *ab);


const char *AB_SetupNewUserDialog_GetSelectedBackend(const GWEN_DIALOG *dlg);
int AB_SetupNewUserDialog_GetSelectedType(const GWEN_DIALOG *dlg);



#ifdef __cplusplus
}
#endif


/*@}*/


#endif

