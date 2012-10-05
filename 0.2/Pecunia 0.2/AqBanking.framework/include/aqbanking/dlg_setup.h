/***************************************************************************
 begin       : Wed Apr 14 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AB_DLG_SETUP_H
#define AB_DLG_SETUP_H


#include <aqbanking/banking.h>

#include <gwenhywfar/dialog.h>
#include <gwenhywfar/db.h>



/** @defgroup G_AB_DIALOGS_SETUP Online Banking Setup Dialog
 * @ingroup G_AB_DIALOGS
 *
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif



AQBANKING_API GWEN_DIALOG *AB_SetupDialog_new(AB_BANKING *ab);



#ifdef __cplusplus
}
#endif



/*@}*/



#endif

