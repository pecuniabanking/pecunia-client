/***************************************************************************
    begin       : Wed May 07 2008
    copyright   : (C) 2008 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef EBC_CLIENT_ACCOUNT_H
#define EBC_CLIENT_ACCOUNT_H

#include <aqebics/aqebics.h>

#include <aqbanking/account.h>

#include <gwenhywfar/db.h>
#include <gwenhywfar/misc.h>



#ifdef __cplusplus
extern "C" {
#endif

#define EBC_ACCOUNT_FLAGS_STA_SPP                  0x00000001
#define EBC_ACCOUNT_FLAGS_IZV_SPP                  0x00000002


void EBC_Account_Flags_toDb(GWEN_DB_NODE *db, const char *name,
			    uint32_t flags);
uint32_t EBC_Account_Flags_fromDb(GWEN_DB_NODE *db, const char *name);


const char *EBC_Account_GetEbicsId(const AB_ACCOUNT *a);
void EBC_Account_SetEbicsId(AB_ACCOUNT *a, const char *s);


/**
 * Returns 0 if the bank doesn't sign messages, 1 otherwise.
 * This can be used in case the bank sends a sign key upon request but
 * never signs it's messages.
 */

uint32_t EBC_Account_GetFlags(const AB_ACCOUNT *a);
void EBC_Account_SetFlags(AB_ACCOUNT *a, uint32_t flags);
void EBC_Account_AddFlags(AB_ACCOUNT *a, uint32_t flags);
void EBC_Account_SubFlags(AB_ACCOUNT *a, uint32_t flags);


#ifdef __cplusplus
}
#endif

#endif /* EBC_USER_H */






