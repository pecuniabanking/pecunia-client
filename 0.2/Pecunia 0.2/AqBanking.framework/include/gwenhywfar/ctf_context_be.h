/***************************************************************************
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CTF_CONTEXT_BE_H
#define GWEN_CTF_CONTEXT_BE_H


#include <gwenhywfar/ct_context.h>
#include <gwenhywfar/ct_keyinfo.h>
#include <gwenhywfar/cryptkey.h>


#define GWEN_CRYPT_TOKEN_CONTEXT_KEYS 7

#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API
GWEN_CRYPT_TOKEN_CONTEXT *GWEN_CTF_Context_new();

GWENHYWFAR_API
int GWEN_CTF_Context_IsOfThisType(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetLocalSignKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetLocalSignKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetLocalSignKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetLocalSignKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetLocalCryptKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetLocalCryptKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetLocalCryptKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetLocalCryptKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetRemoteSignKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetRemoteSignKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetRemoteSignKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetRemoteSignKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetRemoteCryptKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetRemoteCryptKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetRemoteCryptKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetRemoteCryptKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetLocalAuthKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetLocalAuthKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetLocalAuthKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetLocalAuthKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);

GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetRemoteAuthKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetRemoteAuthKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetRemoteAuthKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetRemoteAuthKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);


GWENHYWFAR_API
GWEN_CRYPT_KEY *GWEN_CTF_Context_GetTempLocalSignKey(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetTempLocalSignKey(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_KEY *k);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_KEYINFO *GWEN_CTF_Context_GetTempLocalSignKeyInfo(const GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API
void GWEN_CTF_Context_SetTempLocalSignKeyInfo(GWEN_CRYPT_TOKEN_CONTEXT *ctx, GWEN_CRYPT_TOKEN_KEYINFO *ki);


#ifdef __cplusplus
}
#endif


#endif



