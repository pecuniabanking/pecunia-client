/***************************************************************************
    begin       : Mon Dec 01 2008
    copyright   : (C) 2008 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPTMGR_CRYPTMGR_KEYS_H
#define GWEN_CRYPTMGR_CRYPTMGR_KEYS_H


#include <gwenhywfar/cryptmgr.h>
#include <gwenhywfar/cryptkey.h>

#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API
GWEN_CRYPTMGR *GWEN_CryptMgrKeys_new(const char *localName,
				     GWEN_CRYPT_KEY *localKey,
				     const char *peerName,
				     GWEN_CRYPT_KEY *peerKey,
				     int ownKeys);

GWENHYWFAR_API
void GWEN_CryptMgrKeys_SetPeerKey(GWEN_CRYPTMGR *mgr,
				  GWEN_CRYPT_KEY *peerKey,
				  int ownKey);


#ifdef __cplusplus
}
#endif

#endif


