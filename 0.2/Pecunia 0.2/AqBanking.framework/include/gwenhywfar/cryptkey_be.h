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


#ifndef GWEN_CRYPT_KEY_BE_H
#define GWEN_CRYPT_KEY_BE_H

#include <gwenhywfar/cryptkey.h>



typedef int (*GWEN_CRYPT_KEY_SIGN_FN)(GWEN_CRYPT_KEY *k,
				      const uint8_t *pInData,
				      uint32_t inLen,
				      uint8_t *pSignatureData,
				      uint32_t *pSignatureLen);
typedef int (*GWEN_CRYPT_KEY_VERIFY_FN)(GWEN_CRYPT_KEY *k,
					const uint8_t *pInData,
					uint32_t inLen,
					const uint8_t *pSignatureData,
					uint32_t signatureLen);
typedef int (*GWEN_CRYPT_KEY_ENCIPHER_FN)(GWEN_CRYPT_KEY *k,
					  const uint8_t *pInData,
					  uint32_t inLen,
					  uint8_t *pOutData,
					  uint32_t *pOutLen);
typedef int (*GWEN_CRYPT_KEY_DECIPHER_FN)(GWEN_CRYPT_KEY *k,
					  const uint8_t *pInData,
					  uint32_t inLen,
					  uint8_t *pOutData,
					  uint32_t *pOutLen);


#ifdef __cplusplus
extern "C" {
#endif

GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_Key_new(GWEN_CRYPT_CRYPTALGOID cryptAlgoId, int keySize);

GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_Key_fromDb(GWEN_DB_NODE *db);
GWENHYWFAR_API int GWEN_Crypt_Key_toDb(const GWEN_CRYPT_KEY *k, GWEN_DB_NODE *db);
GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_Key_dup(const GWEN_CRYPT_KEY *k);


GWENHYWFAR_API GWEN_CRYPT_KEY_SIGN_FN GWEN_Crypt_Key_SetSignFn(GWEN_CRYPT_KEY *k,
							       GWEN_CRYPT_KEY_SIGN_FN f);
GWENHYWFAR_API GWEN_CRYPT_KEY_VERIFY_FN GWEN_Crypt_Key_SetVerifyFn(GWEN_CRYPT_KEY *k,
								   GWEN_CRYPT_KEY_VERIFY_FN f);

GWENHYWFAR_API GWEN_CRYPT_KEY_ENCIPHER_FN
  GWEN_Crypt_Key_SetEncipherFn(GWEN_CRYPT_KEY *k,
			       GWEN_CRYPT_KEY_ENCIPHER_FN f);
GWENHYWFAR_API GWEN_CRYPT_KEY_DECIPHER_FN
  GWEN_Crypt_Key_SetDecipherFn(GWEN_CRYPT_KEY *k,
			       GWEN_CRYPT_KEY_DECIPHER_FN f);


#ifdef __cplusplus
}
#endif


#endif
