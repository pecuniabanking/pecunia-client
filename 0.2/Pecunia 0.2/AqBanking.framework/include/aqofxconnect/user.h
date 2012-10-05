/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef AO_USER_H
#define AO_USER_H

#include <aqofxconnect/aqofxconnect.h>
#include <aqbanking/provider_be.h>

#include <gwenhywfar/misc.h>
#include <gwenhywfar/db.h>


#define AO_USER_FLAGS_ACCOUNT_LIST     0x00000001
#define AO_USER_FLAGS_STATEMENTS       0x00000002
#define AO_USER_FLAGS_INVESTMENT       0x00000004
#define AO_USER_FLAGS_BILLPAY          0x00000008
#define AO_USER_FLAGS_EMPTY_BANKID     0x00000010
#define AO_USER_FLAGS_EMPTY_FID        0x00000020
#define AO_USER_FLAGS_FORCE_SSL3       0x00000040
#define AO_USER_FLAGS_SEND_SHORT_DATE  0x00000080



#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  AO_User_ServerTypeUnknown=0,
  AO_User_ServerTypeHTTP,
  AO_User_ServerTypeHTTPS
} AO_USER_SERVERTYPE;


AQOFXCONNECT_API
AO_USER_SERVERTYPE AO_User_ServerType_fromString(const char *s);

AQOFXCONNECT_API
const char *AO_User_ServerType_toString(AO_USER_SERVERTYPE t);


AQOFXCONNECT_API
uint32_t AO_User_Flags_fromDb(GWEN_DB_NODE *db, const char *name);

AQOFXCONNECT_API
void AO_User_Flags_toDb(GWEN_DB_NODE *db, const char *name,
                        uint32_t fl);


AQOFXCONNECT_API
void AO_User_Extend(AB_USER *u, AB_PROVIDER *pro,
		    AB_PROVIDER_EXTEND_MODE em,
		    GWEN_DB_NODE *dbBackend);

AQOFXCONNECT_API
const char *AO_User_GetBrokerId(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetBrokerId(AB_USER *u, const char *s);

AQOFXCONNECT_API
const char *AO_User_GetOrg(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetOrg(AB_USER *u, const char *s);

AQOFXCONNECT_API
const char *AO_User_GetFid(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetFid(AB_USER *u, const char *s);

AQOFXCONNECT_API
AO_USER_SERVERTYPE AO_User_GetServerType(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetServerType(AB_USER *u, AO_USER_SERVERTYPE t);

AQOFXCONNECT_API
const char *AO_User_GetServerAddr(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetServerAddr(AB_USER *u, const char *s);

AQOFXCONNECT_API
int AO_User_GetServerPort(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetServerPort(AB_USER *u, int i);

AQOFXCONNECT_API
uint32_t AO_User_GetFlags(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetFlags(AB_USER *u, uint32_t f);

AQOFXCONNECT_API
void AO_User_AddFlags(AB_USER *u, uint32_t f);

AQOFXCONNECT_API
void AO_User_SubFlags(AB_USER *u, uint32_t f);



AQOFXCONNECT_API
const char *AO_User_GetAppId(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetAppId(AB_USER *u, const char *s);

AQOFXCONNECT_API
const char *AO_User_GetAppVer(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetAppVer(AB_USER *u, const char *s);

AQOFXCONNECT_API
const char *AO_User_GetHeaderVer(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetHeaderVer(AB_USER *u, const char *s);

AQOFXCONNECT_API
const char *AO_User_GetClientUid(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetClientUid(AB_USER *u, const char *s);



AQOFXCONNECT_API
int AO_User_GetHttpVMajor(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetHttpVMajor(AB_USER *u, int i);

AQOFXCONNECT_API
int AO_User_GetHttpVMinor(const AB_USER *u);

AQOFXCONNECT_API
void AO_User_SetHttpVMinor(AB_USER *u, int i);


#ifdef __cplusplus
}
#endif


#endif
