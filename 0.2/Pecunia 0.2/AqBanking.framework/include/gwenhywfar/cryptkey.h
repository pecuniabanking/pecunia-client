/*************************************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id: crypttoken.h 1113 2007-01-10 09:14:16Z martin $
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005 by Martin Preuss
    email       : martin@libchipcard.de

 *************************************************************************************************
 *                       Please see toplevel file COPYING for license details                    *
 *************************************************************************************************/


#ifndef GWEN_CRYPT_KEY_H
#define GWEN_CRYPT_KEY_H


#include <gwenhywfar/inherit.h>
#include <gwenhywfar/list1.h>
#include <gwenhywfar/list2.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/cryptalgo.h>
#include <gwenhywfar/hashalgo.h>
#include <gwenhywfar/paddalgo.h>




typedef struct GWEN_CRYPT_KEY GWEN_CRYPT_KEY;

#ifdef __cplusplus
extern "C" {
#endif

GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_CRYPT_KEY, GWENHYWFAR_API)
GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_CRYPT_KEY, GWEN_Crypt_Key, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_CRYPT_KEY, GWEN_Crypt_Key, GWENHYWFAR_API)


GWENHYWFAR_API void GWEN_Crypt_Key_free(GWEN_CRYPT_KEY *k);

GWENHYWFAR_API GWEN_CRYPT_CRYPTALGOID GWEN_Crypt_Key_GetCryptAlgoId(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API int GWEN_Crypt_Key_GetKeySize(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API int GWEN_Crypt_Key_GetKeyNumber(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API void GWEN_Crypt_Key_SetKeyNumber(GWEN_CRYPT_KEY *k, int i);

GWENHYWFAR_API int GWEN_Crypt_Key_GetKeyVersion(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API void GWEN_Crypt_Key_SetKeyVersion(GWEN_CRYPT_KEY *k, int i);

GWENHYWFAR_API int GWEN_Crypt_Key_Sign(GWEN_CRYPT_KEY *k,
				       const uint8_t *pInData,
				       uint32_t inLen,
				       uint8_t *pSignatureData,
				       uint32_t *pSignatureLen);

GWENHYWFAR_API int GWEN_Crypt_Key_Verify(GWEN_CRYPT_KEY *k,
					 const uint8_t *pInData,
					 uint32_t inLen,
					 const uint8_t *pSignatureData,
					 uint32_t signatureLen);

GWENHYWFAR_API int GWEN_Crypt_Key_Encipher(GWEN_CRYPT_KEY *k,
					   const uint8_t *pInData,
					   uint32_t inLen,
					   uint8_t *pOutData,
					   uint32_t *pOutLen);

GWENHYWFAR_API int GWEN_Crypt_Key_Decipher(GWEN_CRYPT_KEY *k,
					   const uint8_t *pInData,
					   uint32_t inLen,
					   uint8_t *pOutData,
					   uint32_t *pOutLen);


#ifdef __cplusplus
}
#endif


#endif
