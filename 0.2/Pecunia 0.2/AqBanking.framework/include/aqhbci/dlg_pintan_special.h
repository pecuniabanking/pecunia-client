/***************************************************************************
 begin       : Mon Apr 12 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQHBCI_DLG_PINTAN_SPECIAL_H
#define AQHBCI_DLG_PINTAN_SPECIAL_H


#include <aqhbci/aqhbci.h>
#include <aqbanking/banking.h>

#include <gwenhywfar/dialog.h>
#include <gwenhywfar/db.h>


#ifdef __cplusplus
extern "C" {
#endif



AQHBCI_API GWEN_DIALOG *AH_PinTanSpecialDialog_new(AB_BANKING *ab);

AQHBCI_API int AH_PinTanSpecialDialog_GetHttpVMajor(const GWEN_DIALOG *dlg);
AQHBCI_API int AH_PinTanSpecialDialog_GetHttpVMinor(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanSpecialDialog_SetHttpVersion(GWEN_DIALOG *dlg, int vmajor, int vminor);

AQHBCI_API int AH_PinTanSpecialDialog_GetHbciVersion(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanSpecialDialog_SetHbciVersion(GWEN_DIALOG *dlg, int i);

AQHBCI_API uint32_t AH_PinTanSpecialDialog_GetFlags(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanSpecialDialog_SetFlags(GWEN_DIALOG *dlg, uint32_t fl);
AQHBCI_API void AH_PinTanSpecialDialog_AddFlags(GWEN_DIALOG *dlg, uint32_t fl);
AQHBCI_API void AH_PinTanSpecialDialog_SubFlags(GWEN_DIALOG *dlg, uint32_t fl);



#ifdef __cplusplus
}
#endif



#endif

