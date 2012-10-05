/***************************************************************************
 begin       : Tue Apr 13 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQBANKING_DLG_SELECTBANKINFO_H
#define AQBANKING_DLG_SELECTBANKINFO_H


#include <gwenhywfar/dialog.h>
#include <gwenhywfar/db.h>

#include <aqbanking/banking.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup G_AB_DIALOGS_SELECT_BANKINFO Bank Finder Dialog
 * @ingroup G_AB_DIALOGS
 *
 */
/*@{*/


AQBANKING_API 
GWEN_DIALOG *AB_SelectBankInfoDialog_new(AB_BANKING *ab,
					 const char *country,
					 const char *bankCode);

AQBANKING_API 
const AB_BANKINFO *AB_SelectBankInfoDialog_GetSelectedBankInfo(GWEN_DIALOG *dlg);



/*@}*/




#ifdef __cplusplus
}
#endif



#endif



