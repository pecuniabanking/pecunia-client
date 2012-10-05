/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_BANKING_SIMPLE_H
#define AQBANKING_BANKING_SIMPLE_H


#ifdef __cplusplus
extern "C" {
#endif


/** @name Mapping Application Accounts to Online Accounts
 *
 * Functions in this group provide an optional service for account mapping.
 * Most applications assign unique ids to their own accounts. This unique
 * id can be mapped to an account of AqBanking.
 */
/*@{*/
/**
 * <p>
 * Sets an alias for the given AqBanking account. You can later use
 * @ref AB_Banking_GetAccountByAlias to refer to an online account by using
 * the unique id of your application's account.
 * </p>
 * <p>
 * AqBanking separates the aliases for each application.
 * </p>
 * @param ab AqBanking main object
 * @param a online account of AqBanking you wish to map your account to
 * @param alias unique id of your application's own account structure
 */
AQBANKING_API 
void AB_Banking_SetAccountAlias(AB_BANKING *ab, AB_ACCOUNT *a, const char *alias);

/**
 * This function returns the AqBanking account to which the given
 * alias (=unique id of your application's own account data) has been
 * mapped.
 *
 * AqBanking remains the owner of the object returned (if any), so you must
 * not free it.
 *
 * Please also note that the object returned is only valid until
 * AB_Banking_Fini() has been called (or until the corresponding backend for
 * this particular account has been deactivated).
 *
 * @return corresponding AqBanking (or 0 if none)
 * @param ab AqBanking main object
 * @param alias unique id of your application's own account structure
 */
AQBANKING_API 
AB_ACCOUNT *AB_Banking_GetAccountByAlias(AB_BANKING *ab, const char *alias);


/*@}*/


#ifdef __cplusplus
}
#endif


#endif

