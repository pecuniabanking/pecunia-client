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


#ifndef GWEN_CRYPT_KEY_RSA_H
#define GWEN_CRYPT_KEY_RSA_H

#include "cryptkey.h"


/**
 * When signing always directly use the signature, do not determine whether
 * (sig-n) is smaller
 */
#define GWEN_CRYPT_KEYRSA_FLAGS_DIRECTSIGN 0x00000001


#ifdef __cplusplus
extern "C" {
#endif


/**
 * Creates a key pair and returns a pointer to it.
 * @return NULL on error, otherwise a pointer to two keys: public and private
 * @param nbytes number of bytes
 * @param use65537e !=0: use the value 65537 for the public exponent, otherwise let the
 *  library choose the exponent by its own
 */
GWENHYWFAR_API int GWEN_Crypt_KeyRsa_GeneratePair(unsigned int nbytes,
						  int use65537e,
						  GWEN_CRYPT_KEY **pPubKey,
						  GWEN_CRYPT_KEY **pSecretKey);


/**
 * Creates a key pair and returns a pointer to it.
 * This function allows for more precise control over the size of the created key because it
 * lets you specify the size in bits rather than in bytes.
 * @return NULL on error, otherwise a pointer to two keys: public and private
 * @param nbits number of bits
 * @param use65537e !=0: use the value 65537 for the public exponent, otherwise let the
 *  library choose the exponent by its own
 */
GWENHYWFAR_API int GWEN_Crypt_KeyRsa_GeneratePair2(unsigned int nbits, int use65537e,
						   GWEN_CRYPT_KEY **pPubKey,
						   GWEN_CRYPT_KEY **pSecretKey);

GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_KeyRsa_dup(const GWEN_CRYPT_KEY *k);

GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_KeyRsa_fromDb(GWEN_DB_NODE *db);
GWENHYWFAR_API int GWEN_Crypt_KeyRsa_toDb(const GWEN_CRYPT_KEY *k, GWEN_DB_NODE *db, int pub);

GWENHYWFAR_API int GWEN_Crypt_KeyRsa_GetModulus(const GWEN_CRYPT_KEY *k, uint8_t *buffer, uint32_t *pBufLen);
GWENHYWFAR_API int GWEN_Crypt_KeyRsa_GetExponent(const GWEN_CRYPT_KEY *k, uint8_t *buffer, uint32_t *pBufLen);
GWENHYWFAR_API int GWEN_Crypt_KeyRsa_GetSecretExponent(const GWEN_CRYPT_KEY *k, uint8_t *buffer, uint32_t *pBufLen);

GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_KeyRsa_fromModExp(unsigned int nbytes,
							    const uint8_t *pModulus,
							    uint32_t lModulus,
							    const uint8_t *pExponent,
							    uint32_t lExponent);

GWENHYWFAR_API GWEN_CRYPT_KEY *GWEN_Crypt_KeyRsa_fromModPrivExp(unsigned int nbytes,
								const uint8_t *pModulus,
								uint32_t lModulus,
								const uint8_t *pExponent,
								uint32_t lExponent,
								const uint8_t *pPrivExponent,
								uint32_t lPrivExponent);

GWENHYWFAR_API uint32_t GWEN_Crypt_KeyRsa_GetFlags(const GWEN_CRYPT_KEY *k);
GWENHYWFAR_API void GWEN_Crypt_KeyRsa_SetFlags(GWEN_CRYPT_KEY *k,
                                               uint32_t fl);
GWENHYWFAR_API void GWEN_Crypt_KeyRsa_AddFlags(GWEN_CRYPT_KEY *k,
                                               uint32_t fl);
GWENHYWFAR_API void GWEN_Crypt_KeyRsa_SubFlags(GWEN_CRYPT_KEY *k,
					       uint32_t fl);

#ifdef __cplusplus
}
#endif

#endif

