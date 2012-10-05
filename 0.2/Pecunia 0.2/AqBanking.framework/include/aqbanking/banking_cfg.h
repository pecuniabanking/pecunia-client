/***************************************************************************
 begin       : Sat Sep 27 2008
 copyright   : (C) 2008-2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

#ifndef AQBANKING_BANKING_CFG_H
#define AQBANKING_BANKING_CFG_H

#include <aqbanking/provider.h>


#ifdef __cplusplus
extern "C" {
#endif



AQBANKING_API
int AB_Banking_LoadAppConfig(AB_BANKING *ab, GWEN_DB_NODE **pDb);

AQBANKING_API
int AB_Banking_SaveAppConfig(AB_BANKING *ab, GWEN_DB_NODE *db);


AQBANKING_API
int AB_Banking_LockAppConfig(AB_BANKING *ab);

AQBANKING_API
int AB_Banking_UnlockAppConfig(AB_BANKING *ab);




AQBANKING_API
int AB_Banking_LoadSharedConfig(AB_BANKING *ab,
				const char *name,
				GWEN_DB_NODE **pDb);

AQBANKING_API
int AB_Banking_SaveSharedConfig(AB_BANKING *ab,
				const char *name,
				GWEN_DB_NODE *db);


AQBANKING_API
int AB_Banking_LockSharedConfig(AB_BANKING *ab, const char *name);

AQBANKING_API
int AB_Banking_UnlockSharedConfig(AB_BANKING *ab, const char *name);



/**
 * Before making any permanent changes to an account this function must be called.
 * It reloads the current configuration and locks the given account. While this
 * lock is in place no other application can make any changes to the account.
 */
AQBANKING_API
int AB_Banking_BeginExclUseAccount(AB_BANKING *ab, AB_ACCOUNT *a);

/**
 * This function writes the configuration of the given account to the database and
 * releases the given account so that other applications can access it.
 */
AQBANKING_API
int AB_Banking_EndExclUseAccount(AB_BANKING *ab, AB_ACCOUNT *a, int abandon);



/**
 * Before making any permanent changes to an user this function must be called.
 * It reloads the current configuration and locks the given user. While this
 * lock is in place no other application can make any changes to the user.
 */
AQBANKING_API
int AB_Banking_BeginExclUseUser(AB_BANKING *ab, AB_USER *u);


/**
 * This function writes the configuration of the given user to the database and
 * releases the given user so that other applications can access it.
 * @param ab pointer to the AqBanking object
 * @param u user
 * @param abandon if 0 then the changes are written to the database, otherwise they are not
 */
AQBANKING_API
int AB_Banking_EndExclUseUser(AB_BANKING *ab, AB_USER *u, int abandon);



/** @name Checking Configuration for AqBanking4
 *
 */
/*@{*/
AQBANKING_API
int AB_Banking_HasConf4(AB_BANKING *ab);
/*@}*/


/** @name Importing Configuration from AqBanking3
 *
 */
/*@{*/

AQBANKING_API
int AB_Banking_HasConf3(AB_BANKING *ab);

/**
 * This function imports the configuration of AqBanking3.
 */
AQBANKING_API
int AB_Banking_ImportConf3(AB_BANKING *ab);
/*@}*/


/** @name Importing Configuration from AqBanking2
 *
 */
/*@{*/

AQBANKING_API
int AB_Banking_HasConf2(AB_BANKING *ab);

/**
 * This function imports the configuration of AqBanking2.
 */
AQBANKING_API
int AB_Banking_ImportConf2(AB_BANKING *ab);

/*@}*/


#ifdef __cplusplus
}
#endif


#endif
