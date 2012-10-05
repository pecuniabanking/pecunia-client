/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id: crypttoken.h 1113 2007-01-10 09:14:16Z martin $
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPT_KEY_SYM_H
#define GWEN_CRYPT_KEY_SYM_H

#include "cryptkey.h"


#ifdef __cplusplus
extern "C" {
#endif

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_Crypt_KeyDes3K_Generate(GWEN_CRYPT_CRYPTMODE mode,
					     int keySize,
					     int quality);

GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyDes3K_fromData(GWEN_CRYPT_CRYPTMODE mode, int keySize,
					     const uint8_t *kd, uint32_t kl);

GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyDes3K_fromDb(GWEN_CRYPT_CRYPTMODE mode,
					   GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeyDes3K_toDb(const GWEN_CRYPT_KEY *k, GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeyDes3K_SetKeyData(GWEN_CRYPT_KEY *k, const uint8_t *kd, uint32_t kl);

GWENHYWFAR_API 
uint8_t *GWEN_Crypt_KeyDes3K_GetKeyDataPtr(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API 
uint32_t GWEN_Crypt_KeyDes3K_GetKeyDataLen(const GWEN_CRYPT_KEY *k);


GWENHYWFAR_API 
int GWEN_Crypt_KeyDes3K_SetIV(GWEN_CRYPT_KEY *k,
			      const uint8_t *kd,
			      uint32_t kl);



GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyBlowFish_Generate(GWEN_CRYPT_CRYPTMODE mode,
						int keySize,
						int quality);

GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyBlowFish_fromData(GWEN_CRYPT_CRYPTMODE mode, int keySize,
						const uint8_t *kd, uint32_t kl);

GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyBlowFish_fromDb(GWEN_CRYPT_CRYPTMODE mode,
					      GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeyBlowFish_toDb(const GWEN_CRYPT_KEY *k, GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeyBlowFish_SetKeyData(GWEN_CRYPT_KEY *k, const uint8_t *kd, uint32_t kl);

GWENHYWFAR_API 
uint8_t *GWEN_Crypt_KeyBlowFish_GetKeyDataPtr(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API 
uint32_t GWEN_Crypt_KeyBlowFish_GetKeyDataLen(const GWEN_CRYPT_KEY *k);



GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyAes128_Generate(GWEN_CRYPT_CRYPTMODE mode,
					      int keySize,
					      int quality);

GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyAes128_fromData(GWEN_CRYPT_CRYPTMODE mode, int keySize,
					      const uint8_t *kd, uint32_t kl);

GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeyAes128_fromDb(GWEN_CRYPT_CRYPTMODE mode,
					    GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeyAes128_toDb(const GWEN_CRYPT_KEY *k, GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeyAes128_SetKeyData(GWEN_CRYPT_KEY *k, const uint8_t *kd, uint32_t kl);

GWENHYWFAR_API 
uint8_t *GWEN_Crypt_KeyAes128_GetKeyDataPtr(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API 
uint32_t GWEN_Crypt_KeyAes128_GetKeyDataLen(const GWEN_CRYPT_KEY *k);


GWENHYWFAR_API 
int GWEN_Crypt_KeyAes128_SetIV(GWEN_CRYPT_KEY *k,
			       const uint8_t *kd,
			       uint32_t kl);



/**
 * This functions creates a copy of the given key. The given key must
 * have been created by one of the functions in this group (e.g.
 * @ref GWEN_Crypt_KeyBlowFish_fromDb(), @ref GWEN_Crypt_KeyDes3K_Generate()
 * etc. For other kinds of keys other functions must be used (like
 * @ref GWEN_Crypt_KeyRsa_dup() for RSA keys).
 */
GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeySym_dup(const GWEN_CRYPT_KEY *k);


GWENHYWFAR_API 
GWEN_CRYPT_KEY *GWEN_Crypt_KeySym_fromDb(GWEN_CRYPT_CRYPTMODE mode, GWEN_DB_NODE *db);

GWENHYWFAR_API 
int GWEN_Crypt_KeySym_toDb(const GWEN_CRYPT_KEY *k, GWEN_DB_NODE *db);


#ifdef __cplusplus
}
#endif


#endif

