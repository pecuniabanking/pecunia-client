/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

/** @file banking_be.h
 * @short This file is used by provider backends.
 */


#ifndef AQBANKING_BANKING_BE_H
#define AQBANKING_BANKING_BE_H

#include <aqbanking/banking.h>


#define AB_CFG_GROUP_BACKENDS   "backends"
#define AB_CFG_GROUP_BANKINFO   "bankinfo"
#define AB_CFG_GROUP_IMEXPORTER "imexporter"



/** @addtogroup G_AB_BE_BANKING
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif


/** @name Functions Used by Backends And Wizards
 *
 */
/*@{*/

/**
 * Loads a backend with the given name. You can use
 * @ref AB_Banking_GetProviderDescrs to retrieve a list of available
 * backends.
 */
AQBANKING_API 
AB_PROVIDER *AB_Banking_GetProvider(AB_BANKING *ab, const char *name);


/**
 * Returns the list of global data folders. In most cases this is something
 * like $PREFIX/share/. Plugins are required to use the folders
 * returned here + "aqbanking" when searching for their specific data instead
 * of using the compile time fixed values. This way it is easier under
 * windows to find data.
 */
AQBANKING_API
GWEN_STRINGLIST *AB_Banking_GetGlobalDataDirs();


AQBANKING_API
GWEN_STRINGLIST *AB_Banking_GetGlobalSysconfDirs();

/*@}*/



/** @name Administration of Crypt Token List
 *
 */
/*@{*/
AQBANKING_API
int AB_Banking_GetCryptToken(AB_BANKING *ab,
			     const char *tname,
			     const char *cname,
			     GWEN_CRYPT_TOKEN **pCt);

AQBANKING_API 
void AB_Banking_ClearCryptTokenList(AB_BANKING *ab);

AQBANKING_API 
int AB_Banking_CheckCryptToken(AB_BANKING *ab,
			       GWEN_CRYPT_TOKEN_DEVICE devt,
			       GWEN_BUFFER *typeName,
			       GWEN_BUFFER *tokenName);

/*@}*/


/** @name Configuration Data Handling for Plugins
 *
 */
/*@{*/

AQBANKING_API 
int AB_Banking_LoadPluginConfig(AB_BANKING *ab,
				const char *pluginName,
				const char *name,
				GWEN_DB_NODE **pDb);

AQBANKING_API 
int AB_Banking_SavePluginConfig(AB_BANKING *ab,
				const char *pluginName,
				const char *name,
				GWEN_DB_NODE *db);

AQBANKING_API 
int AB_Banking_LockPluginConfig(AB_BANKING *ab,
				const char *pluginName,
				const char *name);

AQBANKING_API 
int AB_Banking_UnlockPluginConfig(AB_BANKING *ab,
				  const char *pluginName,
				  const char *name);

AQBANKING_API 
int AB_Banking_SaveAccountConfig(AB_BANKING *ab, AB_ACCOUNT *a, int doLock);

AQBANKING_API 
int AB_Banking_SaveUserConfig(AB_BANKING *ab, AB_USER *u, int doLock);


/*@}*/






AQBANKING_API
int AB_Banking_ExecutionProgress(AB_BANKING *ab);

AQBANKING_API
int AB_Banking_GetUniqueId(AB_BANKING *ab);


/**
 * This copies the name of the folder for AqBanking's backend data into
 * the given GWEN_Buffer (not including the provider's name).
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 * @param ab pointer to the AB_BANKING object
 * @param buf buffer to append the path name to
 */
AQBANKING_API
int AB_Banking_GetProviderUserDataDir(const AB_BANKING *ab,
                                      const char *name,
                                      GWEN_BUFFER *buf);

#ifdef __cplusplus
}
#endif

/*@}*/


#endif /* AQBANKING_BANKING_BE_H */






