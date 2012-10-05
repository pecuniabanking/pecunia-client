/***************************************************************************
 $RCSfile: user.h,v $
                             -------------------
    cvs         : $Id: user.h,v 1.3 2006/01/13 13:59:59 cstim Exp $
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef EBC_CLIENT_USER_H
#define EBC_CLIENT_USER_H

#include <aqebics/aqebics.h>

#include <aqbanking/user.h>

#include <gwenhywfar/db.h>
#include <gwenhywfar/misc.h>
#include <gwenhywfar/url.h>



#ifdef __cplusplus
extern "C" {
#endif

#define EBC_USER_FLAGS_BANK_DOESNT_SIGN         0x00000001
#define EBC_USER_FLAGS_FORCE_SSLV3              0x00000002
#define EBC_USER_FLAGS_INI                      0x00000004
#define EBC_USER_FLAGS_HIA                      0x00000008
#define EBC_USER_FLAGS_CLIENT_DATA_DOWNLOAD_SPP 0x00000010
#define EBC_USER_FLAGS_PREVALIDATION_SPP        0x00000020
#define EBC_USER_FLAGS_RECOVERY_SPP             0x00000040
#define EBC_USER_FLAGS_STA_SPP                  0x00000080
#define EBC_USER_FLAGS_IZV_SPP                  0x00000100
#define EBC_USER_FLAGS_USE_IZL                  0x00010000
#define EBC_USER_FLAGS_TIMESTAMP_FIX1           0x00020000
#define EBC_USER_FLAGS_NO_EU                    0x00040000


void EBC_User_Flags_toDb(GWEN_DB_NODE *db, const char *name,
                         uint32_t flags);

uint32_t EBC_User_Flags_fromDb(GWEN_DB_NODE *db, const char *name);


typedef enum {
  EBC_UserStatus_New=0,
  EBC_UserStatus_Init1,
  EBC_UserStatus_Init2,
  EBC_UserStatus_Enabled,
  EBC_UserStatus_Disabled,
  EBC_UserStatus_Unknown=999
} EBC_USER_STATUS;

const char *EBC_User_Status_toString(EBC_USER_STATUS st);
EBC_USER_STATUS EBC_User_Status_fromString(const char *s);

EBC_USER_STATUS EBC_User_GetStatus(const AB_USER *u);
void EBC_User_SetStatus(AB_USER *u, EBC_USER_STATUS i);

const GWEN_URL *EBC_User_GetServerUrl(const AB_USER *u);
void EBC_User_SetServerUrl(AB_USER *u, const GWEN_URL *url);

const char *EBC_User_GetPeerId(const AB_USER *u);
void EBC_User_SetPeerId(AB_USER *u, const char *s);

const char *EBC_User_GetSystemId(const AB_USER *u);
void EBC_User_SetSystemId(AB_USER *u, const char *s);

const char *EBC_User_GetProtoVersion(const AB_USER *u);
void EBC_User_SetProtoVersion(AB_USER *u, const char *s);

const char *EBC_User_GetSignVersion(const AB_USER *u);
void EBC_User_SetSignVersion(AB_USER *u, const char *s);

const char *EBC_User_GetCryptVersion(const AB_USER *u);
void EBC_User_SetCryptVersion(AB_USER *u, const char *s);

const char *EBC_User_GetAuthVersion(const AB_USER *u);
void EBC_User_SetAuthVersion(AB_USER *u, const char *s);



/**
 * Returns 0 if the bank doesn't sign messages, 1 otherwise.
 * This can be used in case the bank sends a sign key upon request but
 * never signs it's messages.
 */

uint32_t EBC_User_GetFlags(const AB_USER *u);
void EBC_User_SetFlags(AB_USER *u, uint32_t flags);
void EBC_User_AddFlags(AB_USER *u, uint32_t flags);
void EBC_User_SubFlags(AB_USER *u, uint32_t flags);


/**
 * Returns the major HTTP version to be used in PIN/TAN mode (defaults to 1).
 */

int EBC_User_GetHttpVMajor(const AB_USER *u);
void EBC_User_SetHttpVMajor(AB_USER *u, int i);

/**
 * Returns the minor HTTP version to be used in PIN/TAN mode (defaults to 1).
 */

int EBC_User_GetHttpVMinor(const AB_USER *u);
void EBC_User_SetHttpVMinor(AB_USER *u, int i);

const char *EBC_User_GetHttpUserAgent(const AB_USER *u);
void EBC_User_SetHttpUserAgent(AB_USER *u, const char *s);

const char *EBC_User_GetHttpContentType(const AB_USER *u);
void EBC_User_SetHttpContentType(AB_USER *u, const char *s);



const char *EBC_User_GetTokenType(const AB_USER *u);
void EBC_User_SetTokenType(AB_USER *u, const char *s);
const char *EBC_User_GetTokenName(const AB_USER *u);
void EBC_User_SetTokenName(AB_USER *u, const char *s);
uint32_t EBC_User_GetTokenContextId(const AB_USER *u);
void EBC_User_SetTokenContextId(AB_USER *u, uint32_t id);

int EBC_User_MkPasswdName(const AB_USER *u, GWEN_BUFFER *buf);

#ifdef __cplusplus
}
#endif

#endif /* EBC_USER_H */






