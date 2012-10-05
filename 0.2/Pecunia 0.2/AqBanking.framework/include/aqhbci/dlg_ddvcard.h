/***************************************************************************
 begin       : Tue Apr 20 2010
 copyright   : (C) 2010 by Martin Preuss
 email       : martin@aqbanking.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQHBCI_DLG_DDVCARD_H
#define AQHBCI_DLG_DDVCARD_H


#include <aqhbci/aqhbci.h>
#include <aqbanking/banking.h>

#include <gwenhywfar/dialog.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/ct.h>


#ifdef __cplusplus
extern "C" {
#endif



AQHBCI_API GWEN_DIALOG *AH_DdvCardDialog_new(AB_BANKING *ab, GWEN_CRYPT_TOKEN *ct);

AQHBCI_API GWEN_CRYPT_TOKEN *AH_DdvCardDialog_GetCryptToken(const GWEN_DIALOG *dlg);

AQHBCI_API const char *AH_DdvCardDialog_GetPeerId(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetPeerId(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_DdvCardDialog_GetBankCode(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetBankCode(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_DdvCardDialog_GetBankName(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetBankName(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_DdvCardDialog_GetUserName(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetUserName(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_DdvCardDialog_GetUserId(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetUserId(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_DdvCardDialog_GetCustomerId(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetCustomerId(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API const char *AH_DdvCardDialog_GetUrl(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetUrl(GWEN_DIALOG *dlg, const char *s);

AQHBCI_API int AH_DdvCardDialog_GetHbciVersion(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetHbciVersion(GWEN_DIALOG *dlg, int i);

AQHBCI_API uint32_t AH_DdvCardDialog_GetFlags(const GWEN_DIALOG *dlg);
AQHBCI_API void AH_DdvCardDialog_SetFlags(GWEN_DIALOG *dlg, uint32_t fl);
AQHBCI_API void AH_DdvCardDialog_AddFlags(GWEN_DIALOG *dlg, uint32_t fl);
AQHBCI_API void AH_DdvCardDialog_SubFlags(GWEN_DIALOG *dlg, uint32_t fl);

AQHBCI_API AB_USER *AH_DdvCardDialog_GetUser(const GWEN_DIALOG *dlg);


#ifdef __cplusplus
}
#endif



#endif

