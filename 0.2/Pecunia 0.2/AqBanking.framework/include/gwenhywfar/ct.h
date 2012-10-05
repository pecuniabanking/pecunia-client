/***************************************************************************
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPT_CRYPTTOKEN_H
#define GWEN_CRYPT_CRYPTTOKEN_H

#include <gwenhywfar/list1.h>
#include <gwenhywfar/list2.h>



typedef struct GWEN_CRYPT_TOKEN GWEN_CRYPT_TOKEN;

#ifdef __cplusplus
extern "C" {
#endif


GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_CRYPT_TOKEN, GWEN_Crypt_Token, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_CRYPT_TOKEN, GWEN_Crypt_Token, GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif



typedef enum {
  GWEN_Crypt_Token_Device_Unknown=-1,
  GWEN_Crypt_Token_Device_None=0,
  GWEN_Crypt_Token_Device_File,
  GWEN_Crypt_Token_Device_Card,
  GWEN_Crypt_Token_Device_Any=999
} GWEN_CRYPT_TOKEN_DEVICE;


#ifdef __cplusplus
extern "C" {
#endif

/** @name Converting Device Types to and from Strings
 *
 */
/*@{*/
GWENHYWFAR_API GWEN_CRYPT_TOKEN_DEVICE GWEN_Crypt_Token_Device_fromString(const char *s);
GWENHYWFAR_API const char *GWEN_Crypt_Token_Device_toString(GWEN_CRYPT_TOKEN_DEVICE d);
/*@}*/



#define GWEN_CRYPT_TOKEN_MODE_SECURE_PIN_ENTRY   0x00000001
#define GWEN_CRYPT_TOKEN_MODE_FORCE_PIN_ENTRY    0x00000002
/** this flag allows updating of old CryptToken files to newer versions */
#define GWEN_CRYPT_TOKEN_MODE_ALLOW_UPDATE       0x00000004
#define GWEN_CRYPT_TOKEN_MODE_EXP_65537          0x00000008
#define GWEN_CRYPT_TOKEN_MODE_DIRECT_SIGN        0x00000010



#define GWEN_CRYPT_TOKEN_FLAGS_MANAGES_SIGNSEQ   0x00000001



#include <gwenhywfar/ct_keyinfo.h>
#include <gwenhywfar/ct_context.h>
#include <gwenhywfar/paddalgo.h>
#include <gwenhywfar/hashalgo.h>
#include <gwenhywfar/cryptalgo.h>
#include <gwenhywfar/cryptdefs.h>


/** @name Basic Informations about a CryptToken
 *
 */
/*@{*/
GWENHYWFAR_API void GWEN_Crypt_Token_free(GWEN_CRYPT_TOKEN *ct);
/*@}*/



/** @name Basic Informations about a CryptToken
 *
 */
/*@{*/
GWENHYWFAR_API uint32_t GWEN_Crypt_Token_GetFlags(const GWEN_CRYPT_TOKEN *ct);

GWENHYWFAR_API uint32_t GWEN_Crypt_Token_GetModes(const GWEN_CRYPT_TOKEN *ct);

GWENHYWFAR_API void GWEN_Crypt_Token_SetModes(GWEN_CRYPT_TOKEN *ct, uint32_t f);

GWENHYWFAR_API void GWEN_Crypt_Token_AddModes(GWEN_CRYPT_TOKEN *ct, uint32_t f);

GWENHYWFAR_API void GWEN_Crypt_Token_SubModes(GWEN_CRYPT_TOKEN *ct, uint32_t f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_DEVICE GWEN_Crypt_Token_GetDevice(const GWEN_CRYPT_TOKEN *ct);

GWENHYWFAR_API const char *GWEN_Crypt_Token_GetTokenName(const GWEN_CRYPT_TOKEN *ct);

GWENHYWFAR_API const char *GWEN_Crypt_Token_GetTypeName(const GWEN_CRYPT_TOKEN *ct);

GWENHYWFAR_API const char *GWEN_Crypt_Token_GetFriendlyName(const GWEN_CRYPT_TOKEN *ct);

GWENHYWFAR_API void GWEN_Crypt_Token_SetFriendlyName(GWEN_CRYPT_TOKEN *ct, const char *s);
/*@}*/



/** @name Open, Create and Close
 *
 */
/*@{*/
GWENHYWFAR_API int GWEN_Crypt_Token_Open(GWEN_CRYPT_TOKEN *ct, int admin, uint32_t gid);


GWENHYWFAR_API int GWEN_Crypt_Token_Create(GWEN_CRYPT_TOKEN *ct, uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_Close(GWEN_CRYPT_TOKEN *ct, int abandon, uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_IsOpen(const GWEN_CRYPT_TOKEN *ct);

/*@}*/



/** @name Cryptographic Objects
 *
 */
/*@{*/
GWENHYWFAR_API int GWEN_Crypt_Token_GetKeyIdList(GWEN_CRYPT_TOKEN *ct,
						 uint32_t *pIdList,
						 uint32_t *pCount,
						 uint32_t gid);

GWENHYWFAR_API const GWEN_CRYPT_TOKEN_KEYINFO* GWEN_Crypt_Token_GetKeyInfo(GWEN_CRYPT_TOKEN *ct,
									   uint32_t id,
									   uint32_t flags,
									   uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_SetKeyInfo(GWEN_CRYPT_TOKEN *ct,
					       uint32_t id,
					       const GWEN_CRYPT_TOKEN_KEYINFO *ki,
					       uint32_t gid);


GWENHYWFAR_API int GWEN_Crypt_Token_GetContextIdList(GWEN_CRYPT_TOKEN *ct,
						     uint32_t *pIdList,
						     uint32_t *pCount,
						     uint32_t gid);

GWENHYWFAR_API const GWEN_CRYPT_TOKEN_CONTEXT* GWEN_Crypt_Token_GetContext(GWEN_CRYPT_TOKEN *ct,
									   uint32_t id,
									   uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_SetContext(GWEN_CRYPT_TOKEN *ct,
					       uint32_t id,
					       const GWEN_CRYPT_TOKEN_CONTEXT *ctx,
					       uint32_t gid);
/*@}*/



/** @name Cryptographic Operations
 *
 */
/*@{*/
GWENHYWFAR_API int GWEN_Crypt_Token_Sign(GWEN_CRYPT_TOKEN *ct,
					 uint32_t keyId,
					 GWEN_CRYPT_PADDALGO *a,
					 const uint8_t *pInData,
					 uint32_t inLen,
					 uint8_t *pSignatureData,
					 uint32_t *pSignatureLen,
					 uint32_t *pSeqCounter,
					 uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_Verify(GWEN_CRYPT_TOKEN *ct,
					   uint32_t keyId,
					   GWEN_CRYPT_PADDALGO *a,
					   const uint8_t *pInData,
					   uint32_t inLen,
					   const uint8_t *pSignatureData,
					   uint32_t signatureLen,
					   uint32_t seqCounter,
					   uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_Encipher(GWEN_CRYPT_TOKEN *ct,
					     uint32_t keyId,
					     GWEN_CRYPT_PADDALGO *a,
					     const uint8_t *pInData,
					     uint32_t inLen,
					     uint8_t *pOutData,
					     uint32_t *pOutLen,
					     uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_Decipher(GWEN_CRYPT_TOKEN *ct,
					     uint32_t keyId,
					     GWEN_CRYPT_PADDALGO *a,
					     const uint8_t *pInData,
					     uint32_t inLen,
					     uint8_t *pOutData,
					     uint32_t *pOutLen,
					     uint32_t gid);
/*@}*/



/** @name Administrative Operations
 *
 */
/*@{*/
GWENHYWFAR_API int GWEN_Crypt_Token_GenerateKey(GWEN_CRYPT_TOKEN *ct,
						uint32_t keyId,
						const GWEN_CRYPT_CRYPTALGO *a,
						uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_ChangePin(GWEN_CRYPT_TOKEN *ct, int admin, uint32_t gid);

GWENHYWFAR_API int  GWEN_Crypt_Token_ActivateKey(GWEN_CRYPT_TOKEN *ct, uint32_t id, uint32_t gid);

/*@}*/


#ifdef __cplusplus
}
#endif



#endif


