/***************************************************************************
 begin       : Mon Apr 12 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQHBCI_DLG_PINTAN_H
#define AQHBCI_DLG_PINTAN_H


#include <aqhbci/aqhbci.h>
#include <aqbanking/banking.h>

#include <gwenhywfar/dialog.h>
#include <gwenhywfar/db.h>


#ifdef __cplusplus
extern "C" {
#endif



AQHBCI_API GWEN_DIALOG *AH_PinTanDialog_new(AB_BANKING *ab);

AQHBCI_API const char *AH_PinTanDialog_GetBankCode(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetBankCode(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_PinTanDialog_GetBankName(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetBankName(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_PinTanDialog_GetUserName(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetUserName(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_PinTanDialog_GetUserId(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetUserId(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_PinTanDialog_GetCustomerId(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetCustomerId(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_PinTanDialog_GetUrl(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetUrl(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API int AH_PinTanDialog_GetHttpVMajor(const GWEN_DIALOG *dlg);
AQHBCI_API int AH_PinTanDialog_GetHttpVMinor(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetHttpVersion(GWEN_DIALOG *dlg, int vmajor, int vminor);

AQHBCI_API int AH_PinTanDialog_GetHbciVersion(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetHbciVersion(GWEN_DIALOG *dlg, int i);

AQHBCI_API uint32_t AH_PinTanDialog_GetFlags(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_PinTanDialog_SetFlags(GWEN_DIALOG *dlg, uint32_t fl);
AQHBCI_API void AH_PinTanDialog_AddFlags(GWEN_DIALOG *dlg, uint32_t fl);
AQHBCI_API void AH_PinTanDialog_SubFlags(GWEN_DIALOG *dlg, uint32_t fl);

AQHBCI_API AB_USER *AH_PinTanDialog_GetUser(const GWEN_DIALOG *dlg);


#ifdef __cplusplus
}
#endif



#endif

