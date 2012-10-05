/***************************************************************************
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPT_TOKEN_FILE_BE_H
#define GWEN_CRYPT_TOKEN_FILE_BE_H


#include <gwenhywfar/ct_be.h>




typedef int GWENHYWFAR_CB 
  (*GWEN_CRYPT_TOKEN_FILE_READ_FN)(GWEN_CRYPT_TOKEN *ct, int fd, uint32_t gid);

typedef int GWENHYWFAR_CB 
  (*GWEN_CRYPT_TOKEN_FILE_WRITE_FN)(GWEN_CRYPT_TOKEN *ct, int fd, int cre, uint32_t gid);



/**
 * Key ids: The left 16 bits contain the context index, the right 16 bits contain the
 * key number:
 * <ul>
 *  <li>xx01=localSignKey</li>
 *  <li>xx02=localCryptKey</li>
 *  <li>xx03=remoteSignKey</li>
 *  <li>xx04=remoteCryptKey</li>
 *  <li>xx05=localAuthKey</li>
 *  <li>xx06=remoteAuthKey</li>
 *  <li>xx07=tempLocalSignKey</li>
 * </ul>
 */

#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API
GWEN_CRYPT_TOKEN *GWEN_Crypt_TokenFile_new(const char *typeName,
					   const char *tokenName);

GWENHYWFAR_API 
GWEN_CRYPT_TOKEN_FILE_READ_FN GWEN_Crypt_TokenFile_SetReadFn(GWEN_CRYPT_TOKEN *ct,
							     GWEN_CRYPT_TOKEN_FILE_READ_FN f);
GWENHYWFAR_API 
GWEN_CRYPT_TOKEN_FILE_WRITE_FN GWEN_Crypt_TokenFile_SetWriteFn(GWEN_CRYPT_TOKEN *ct,
							       GWEN_CRYPT_TOKEN_FILE_WRITE_FN f);

GWENHYWFAR_API 
void GWEN_Crypt_TokenFile_AddContext(GWEN_CRYPT_TOKEN *ct, GWEN_CRYPT_TOKEN_CONTEXT *ctx);

GWENHYWFAR_API 
GWEN_CRYPT_TOKEN_CONTEXT *GWEN_Crypt_TokenFile_GetContext(GWEN_CRYPT_TOKEN *ct, int idx);


#ifdef __cplusplus
}
#endif


#endif
