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


#ifndef GWEN_CRYPT_TOKEN_PLUGIN_BE_H
#define GWEN_CRYPT_TOKEN_PLUGIN_BE_H


#include <gwenhywfar/ctplugin.h>




typedef GWEN_CRYPT_TOKEN* GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_PLUGIN_CREATETOKEN_FN)(GWEN_PLUGIN *pl,
					    const char *name);

typedef int GWENHYWFAR_CB
  (*GWEN_CRYPT_TOKEN_PLUGIN_CHECKTOKEN_FN)(GWEN_PLUGIN *pl,
					   GWEN_BUFFER *name);


#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API
GWEN_PLUGIN *GWEN_Crypt_Token_Plugin_new(GWEN_PLUGIN_MANAGER *mgr,
					 GWEN_CRYPT_TOKEN_DEVICE devType,
					 const char *typeName,
					 const char *fileName);


GWENHYWFAR_API
GWEN_CRYPT_TOKEN_PLUGIN_CREATETOKEN_FN GWEN_Crypt_Token_Plugin_SetCreateTokenFn(GWEN_PLUGIN *pl,
										GWEN_CRYPT_TOKEN_PLUGIN_CREATETOKEN_FN fn);

GWENHYWFAR_API
GWEN_CRYPT_TOKEN_PLUGIN_CHECKTOKEN_FN GWEN_Crypt_Token_Plugin_SetCheckTokenFn(GWEN_PLUGIN *pl,
									      GWEN_CRYPT_TOKEN_PLUGIN_CHECKTOKEN_FN fn);

#ifdef __cplusplus
}
#endif




#endif

