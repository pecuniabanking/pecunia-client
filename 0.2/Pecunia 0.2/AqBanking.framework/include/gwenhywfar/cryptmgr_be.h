/***************************************************************************
    begin       : Mon Dec 01 2008
    copyright   : (C) 2008 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPTMGR_CRYPTMGR_BE_H
#define GWEN_CRYPTMGR_CRYPTMGR_BE_H

#include <gwenhywfar/cryptmgr.h>
#include <gwenhywfar/inherit.h>

#ifdef __cplusplus
extern "C" {
#endif


GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_CRYPTMGR, GWENHYWFAR_API)


typedef GWENHYWFAR_CB int (*GWEN_CRYPTMGR_SIGNDATA_FN)(GWEN_CRYPTMGR *cm,
						       const uint8_t *pData, uint32_t lData,
						       GWEN_BUFFER *dbuf);
typedef GWENHYWFAR_CB int (*GWEN_CRYPTMGR_ENCRYPTKEY_FN)(GWEN_CRYPTMGR *cm,
							 const uint8_t *pData, uint32_t lData,
							 GWEN_BUFFER *dbuf);

typedef GWENHYWFAR_CB int (*GWEN_CRYPTMGR_VERIFYDATA_FN)(GWEN_CRYPTMGR *cm,
							 const uint8_t *pData, uint32_t lData,
							 const uint8_t *pSignature, uint32_t lSignature);
typedef GWENHYWFAR_CB int (*GWEN_CRYPTMGR_DECRYPTKEY_FN)(GWEN_CRYPTMGR *cm,
							 const uint8_t *pData, uint32_t lData,
							 GWEN_BUFFER *dbuf);



GWENHYWFAR_API
GWEN_CRYPTMGR *GWEN_CryptMgr_new();

GWENHYWFAR_API
void GWEN_CryptMgr_SetLocalKeyName(GWEN_CRYPTMGR *cm, const char *s);

GWENHYWFAR_API
void GWEN_CryptMgr_SetLocalKeyNumber(GWEN_CRYPTMGR *cm, int i);

GWENHYWFAR_API
void GWEN_CryptMgr_SetLocalKeyVersion(GWEN_CRYPTMGR *cm, int i);

GWENHYWFAR_API
void GWEN_CryptMgr_SetPeerKeyName(GWEN_CRYPTMGR *cm, const char *s);

GWENHYWFAR_API
void GWEN_CryptMgr_SetPeerKeyNumber(GWEN_CRYPTMGR *cm, int i);

GWENHYWFAR_API
void GWEN_CryptMgr_SetPeerKeyVersion(GWEN_CRYPTMGR *cm, int i);


GWENHYWFAR_API
int GWEN_CryptMgr_SignData(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);

GWENHYWFAR_API
int GWEN_CryptMgr_EncryptKey(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);

GWENHYWFAR_API
int GWEN_CryptMgr_VerifyData(GWEN_CRYPTMGR *cm,
			     const uint8_t *pData, uint32_t lData,
			     const uint8_t *pSignature, uint32_t lSignature);

GWENHYWFAR_API
int GWEN_CryptMgr_DecryptKey(GWEN_CRYPTMGR *cm, const uint8_t *pData, uint32_t lData, GWEN_BUFFER *dbuf);


GWENHYWFAR_API
GWEN_CRYPTMGR_SIGNDATA_FN GWEN_CryptMgr_SetSignDataFn(GWEN_CRYPTMGR *cm,
						      GWEN_CRYPTMGR_SIGNDATA_FN f);

GWENHYWFAR_API
GWEN_CRYPTMGR_VERIFYDATA_FN GWEN_CryptMgr_SetVerifyDataFn(GWEN_CRYPTMGR *cm,
							  GWEN_CRYPTMGR_VERIFYDATA_FN f);

GWENHYWFAR_API
GWEN_CRYPTMGR_ENCRYPTKEY_FN
  GWEN_CryptMgr_SetEncryptKeyFn(GWEN_CRYPTMGR *cm,
				GWEN_CRYPTMGR_ENCRYPTKEY_FN f);

GWENHYWFAR_API
GWEN_CRYPTMGR_DECRYPTKEY_FN GWEN_CryptMgr_SetDecryptKeyFn(GWEN_CRYPTMGR *cm,
							  GWEN_CRYPTMGR_DECRYPTKEY_FN f);


#ifdef __cplusplus
}
#endif


#endif


