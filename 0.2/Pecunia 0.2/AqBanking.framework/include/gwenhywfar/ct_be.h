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


#ifndef GWEN_CRYPT_CRYPTTOKEN_BE_H
#define GWEN_CRYPT_CRYPTTOKEN_BE_H


#include <gwenhywfar/ct.h>
#include <gwenhywfar/inherit.h>
#include <gwenhywfar/buffer.h>
#include <gwenhywfar/hashalgo.h>



GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_CRYPT_TOKEN, GWENHYWFAR_API)




/** @name Prototypes for Virtual Functions
 *
 */
/*@{*/
typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_OPEN_FN)(GWEN_CRYPT_TOKEN *ct, int admin, uint32_t gid);
typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_CREATE_FN)(GWEN_CRYPT_TOKEN *ct, uint32_t gid);
typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_CLOSE_FN)(GWEN_CRYPT_TOKEN *ct, int abandon, uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_GETKEYIDLIST_FN)(GWEN_CRYPT_TOKEN *ct,
				      uint32_t *pIdList,
				      uint32_t *pCount,
				      uint32_t gid);
typedef const GWEN_CRYPT_TOKEN_KEYINFO* GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_GETKEYINFO_FN)(GWEN_CRYPT_TOKEN *ct,
				    uint32_t id,
				    uint32_t flags,
				    uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_SETKEYINFO_FN)(GWEN_CRYPT_TOKEN *ct,
				    uint32_t id,
				    const GWEN_CRYPT_TOKEN_KEYINFO *ki,
				    uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_GETCONTEXTIDLIST_FN)(GWEN_CRYPT_TOKEN *ct,
					  uint32_t *pIdList,
					  uint32_t *pCount,
					  uint32_t gid);
typedef const GWEN_CRYPT_TOKEN_CONTEXT* GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_GETCONTEXT_FN)(GWEN_CRYPT_TOKEN *ct,
				    uint32_t id,
				    uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_SETCONTEXT_FN)(GWEN_CRYPT_TOKEN *ct,
				    uint32_t id,
				    const GWEN_CRYPT_TOKEN_CONTEXT *ctx,
				    uint32_t gid);


typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_SIGN_FN)(GWEN_CRYPT_TOKEN *ct,
			      uint32_t keyId,
			      GWEN_CRYPT_PADDALGO *a,
			      const uint8_t *pInData,
			      uint32_t inLen,
			      uint8_t *pSignatureData,
			      uint32_t *pSignatureLen,
			      uint32_t *pSeqCounter,
			      uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_VERIFY_FN)(GWEN_CRYPT_TOKEN *ct,
				uint32_t keyId,
				GWEN_CRYPT_PADDALGO *a,
				const uint8_t *pInData,
				uint32_t inLen,
				const uint8_t *pSignatureData,
				uint32_t signatureLen,
				uint32_t seqCounter,
				uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_ENCIPHER_FN)(GWEN_CRYPT_TOKEN *ct,
				  uint32_t keyId,
				  GWEN_CRYPT_PADDALGO *a,
				  const uint8_t *pInData,
				  uint32_t inLen,
				  uint8_t *pOutData,
				  uint32_t *pOutLen,
				  uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_DECIPHER_FN)(GWEN_CRYPT_TOKEN *ct,
				  uint32_t keyId,
				  GWEN_CRYPT_PADDALGO *a,
				  const uint8_t *pInData,
				  uint32_t inLen,
				  uint8_t *pOutData,
				  uint32_t *pOutLen,
				  uint32_t gid);


typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_GENERATEKEY_FN)(GWEN_CRYPT_TOKEN *ct,
				     uint32_t keyId,
				     const GWEN_CRYPT_CRYPTALGO *a,
				     uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_CHANGEPIN_FN)(GWEN_CRYPT_TOKEN *ct, int admin, uint32_t gid);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_ACTIVATEKEY_FN)(GWEN_CRYPT_TOKEN *ct, uint32_t id, uint32_t gid);

/*@}*/




/** @name Contructor
 *
 */
/*@{*/
GWENHYWFAR_API GWEN_CRYPT_TOKEN *GWEN_Crypt_Token_new(GWEN_CRYPT_TOKEN_DEVICE dev,
						      const char *typeName,
						      const char *tokenName);
/*@}*/



/** @name Setting CryptToken Information
 *
 */
/*@{*/
GWENHYWFAR_API void GWEN_Crypt_Token_SetTokenName(GWEN_CRYPT_TOKEN *ct, const char *s);

GWENHYWFAR_API void GWEN_Crypt_Token_SetFlags(GWEN_CRYPT_TOKEN *ct, uint32_t f);
GWENHYWFAR_API void GWEN_Crypt_Token_AddFlags(GWEN_CRYPT_TOKEN *ct, uint32_t f);
GWENHYWFAR_API void GWEN_Crypt_Token_SubFlags(GWEN_CRYPT_TOKEN *ct, uint32_t f);
/*@}*/



/** @name Interactive Helper Functions
 *
 */
/*@{*/
GWENHYWFAR_API int GWEN_Crypt_Token_GetPin(GWEN_CRYPT_TOKEN *ct,
					   GWEN_CRYPT_PINTYPE pt,
					   GWEN_CRYPT_PINENCODING pe,
					   uint32_t flags,
					   unsigned char *pwbuffer,
					   unsigned int minLength,
					   unsigned int maxLength,
					   unsigned int *pinLength,
					   uint32_t gid);


GWENHYWFAR_API int GWEN_Crypt_Token_SetPinStatus(GWEN_CRYPT_TOKEN *ct,
						 GWEN_CRYPT_PINTYPE pt,
						 GWEN_CRYPT_PINENCODING pe,
						 uint32_t flags,
						 const unsigned char *buffer,
						 unsigned int pinLength,
						 int isOk,
						 uint32_t gid);

GWENHYWFAR_API uint32_t GWEN_Crypt_Token_BeginEnterPin(GWEN_CRYPT_TOKEN *ct,
						       GWEN_CRYPT_PINTYPE pt,
						       uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_EndEnterPin(GWEN_CRYPT_TOKEN *ct,
						GWEN_CRYPT_PINTYPE pt,
						int ok,
						uint32_t id);

GWENHYWFAR_API int GWEN_Crypt_Token_InsertToken(GWEN_CRYPT_TOKEN *ct, uint32_t gid);

GWENHYWFAR_API int GWEN_Crypt_Token_InsertCorrectToken(GWEN_CRYPT_TOKEN *ct, uint32_t gid);
/*@}*/




/** @name Setter for Virtual Functions
 *
 */
/*@{*/
GWENHYWFAR_API GWEN_CRYPT_TOKEN_OPEN_FN GWEN_Crypt_Token_SetOpenFn(GWEN_CRYPT_TOKEN *ct,
								   GWEN_CRYPT_TOKEN_OPEN_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_CREATE_FN GWEN_Crypt_Token_SetCreateFn(GWEN_CRYPT_TOKEN *ct,
								       GWEN_CRYPT_TOKEN_CREATE_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_CLOSE_FN GWEN_Crypt_Token_SetCloseFn(GWEN_CRYPT_TOKEN *ct,
								     GWEN_CRYPT_TOKEN_CLOSE_FN f);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_GETKEYIDLIST_FN GWEN_Crypt_Token_SetGetKeyIdListFn(GWEN_CRYPT_TOKEN *ct,
								    GWEN_CRYPT_TOKEN_GETKEYIDLIST_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_GETKEYINFO_FN GWEN_Crypt_Token_SetGetKeyInfoFn(GWEN_CRYPT_TOKEN *ct,
									       GWEN_CRYPT_TOKEN_GETKEYINFO_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_SETKEYINFO_FN GWEN_Crypt_Token_SetSetKeyInfoFn(GWEN_CRYPT_TOKEN *ct,
									       GWEN_CRYPT_TOKEN_SETKEYINFO_FN f);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_GETCONTEXTIDLIST_FN GWEN_Crypt_Token_SetGetContextIdListFn(GWEN_CRYPT_TOKEN *ct,
									    GWEN_CRYPT_TOKEN_GETCONTEXTIDLIST_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_GETCONTEXT_FN GWEN_Crypt_Token_SetGetContextFn(GWEN_CRYPT_TOKEN *ct,
									       GWEN_CRYPT_TOKEN_GETCONTEXT_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_SETCONTEXT_FN GWEN_Crypt_Token_SetSetContextFn(GWEN_CRYPT_TOKEN *ct,
									       GWEN_CRYPT_TOKEN_SETCONTEXT_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_SIGN_FN GWEN_Crypt_Token_SetSignFn(GWEN_CRYPT_TOKEN *ct,
								   GWEN_CRYPT_TOKEN_SIGN_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_VERIFY_FN GWEN_Crypt_Token_SetVerifyFn(GWEN_CRYPT_TOKEN *ct,
								       GWEN_CRYPT_TOKEN_VERIFY_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_ENCIPHER_FN GWEN_Crypt_Token_SetEncipherFn(GWEN_CRYPT_TOKEN *ct,
									   GWEN_CRYPT_TOKEN_ENCIPHER_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_DECIPHER_FN GWEN_Crypt_Token_SetDecipherFn(GWEN_CRYPT_TOKEN *ct,
									   GWEN_CRYPT_TOKEN_DECIPHER_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_GENERATEKEY_FN GWEN_Crypt_Token_SetGenerateKeyFn(GWEN_CRYPT_TOKEN *ct,
										 GWEN_CRYPT_TOKEN_GENERATEKEY_FN f);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_CHANGEPIN_FN GWEN_Crypt_Token_SetChangePinFn(GWEN_CRYPT_TOKEN *ct,
									     GWEN_CRYPT_TOKEN_CHANGEPIN_FN f);

GWEN_CRYPT_TOKEN_ACTIVATEKEY_FN GWEN_Crypt_Token_SetActivateKeyFn(GWEN_CRYPT_TOKEN *ct,
								  GWEN_CRYPT_TOKEN_ACTIVATEKEY_FN f);

/*@}*/




#endif


