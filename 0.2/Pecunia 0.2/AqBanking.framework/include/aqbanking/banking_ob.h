/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_BANKING_OB_H
#define AQBANKING_BANKING_OB_H

#include <aqbanking/provider.h>
#include <aqbanking/user.h>
#include <aqbanking/job.h>

#include <gwenhywfar/ct.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @addtogroup G_AB_ONLINE_BANKING
 *
 */
/*@{*/

/** @name User Management Functions
 *
 * AqBanking controls a list of users. You can ask it for the full list
 * (@ref AB_Banking_GetUsers) or directly request a specific user
 * (@ref AB_Banking_GetUser).
 * AB_USERs contain all information needed to identify a user to the bank's
 * server.
 */
/*@{*/

/**
 * Returns a list of currently known users, or NULL if there are no
 * users. The returned list is owned by the caller, so he is
 * responsible for freeing it (using @ref AB_User_List2_free).
 *
 * Please note that even while the list is owned by the caller the users
 * in that list are not! So you may not free any of those users in the
 * list (e.g. by calling @ref AB_User_List2_FreeAll).
 *
 * @return The list of users, or NULL if there are none.
 * @param ab pointer to the AB_BANKING object
 */
AQBANKING_API
AB_USER_LIST2 *AB_Banking_GetUsers(const AB_BANKING *ab);

/**
 * Returns the user with the given unique id.
 */
AQBANKING_API
AB_USER *AB_Banking_GetUser(const AB_BANKING *ab, uint32_t uniqueId);


/**
 * This function returns the first user which matches the given parameters.
 * For all parameters wildcards ("*") and joker ("?") are allowed.
 */
AQBANKING_API
AB_USER *AB_Banking_FindUser(const AB_BANKING *ab,
                             const char *backendName,
                             const char *country,
                             const char *bankId,
                             const char *userId,
                             const char *customerId);

/**
 * This function returns a list of users which match the given parameters.
 * For all parameters wildcards ("*") and joker ("?") are allowed.
 * If no user matches (or there simply are no users) then NULL is returned.
 * The caller is responsible for freeing the list returned (if any) by calling
 * @ref AB_User_List2_free.
 * AqBanking still remains the owner of every user reported via this
 * function, so you MUST NOT call @ref AB_User_List2_freeAll.
 */
AQBANKING_API
AB_USER_LIST2 *AB_Banking_FindUsers(const AB_BANKING *ab,
				    const char *backendName,
                                    const char *country,
                                    const char *bankId,
				    const char *userId,
				    const char *customerId);

/**
 * Creates a user and presents it to the backend (which might want to extend
 * the newly created user in order to associate some data with it).
 * This function does not add the user to AqBanking, please use
 * @ref AB_Banking_AddUser for that purpose.
 */
AQBANKING_API
AB_USER *AB_Banking_CreateUser(AB_BANKING *ab, const char *backendName);

/**
 * Enqueues the given user with AqBanking.
 */
AQBANKING_API
int AB_Banking_AddUser(AB_BANKING *ab, AB_USER *u);

/**
 * Searches all accounts for one that contains the given user. Returns
 * the first of these accounts, or NULL if this user does not belong
 * to any account.
 *
 * It is a prerequisite of AB_Banking_DeleteUser() that the user must
 * not belong to any account anymore. Use this function to check
 * whether this is the case (i.e. this function returns NULL), or if
 * it is not the case, you know at least one account that this user
 * still belongs to.
 *
 * @return The first account that this user belongs to, or NULL if
 * this user does not belong to any account.
 *
 * New in aqbanking-2.2.9.
 */
AQBANKING_API
AB_ACCOUNT *AB_Banking_FindFirstAccountOfUser(AB_BANKING *ab, AB_USER *u);

/**
 * Removes the given user from all internal lists and deletes the
 * object. The caller must not use the AB_USER pointer anymore after
 * calling this function.
 *
 * Watch out: Before this can succeed, this user *must* be removed
 * from all AB_Accounts that it was added to. Otherwise this operation
 * will fail. So before you call this operation, make sure you either
 * removed the user from its accounts, or delete the accounts in
 * question.
 *
 * @returns Zero on success, nonzero on error. In particular, if the
 * user still belongs to any account, "-10" is returned and no
 * operation is done.
 *
 * New in aqbanking-2.2.9.
 */
AQBANKING_API
int AB_Banking_DeleteUser(AB_BANKING *ab, AB_USER *u);
/*@}*/



/** @name Account Management Functions
 *
 * AqBanking controls a list of accounts. You can ask it for the full list
 * (@ref AB_Banking_GetAccounts) or directly request a specific account
 * (@ref AB_Banking_GetAccount).
 */
/*@{*/
/**
 * Returns a list of currently known accounts, or NULL if there are no
 * accounts. The returned list is owned by the caller, so he is
 * responsible for freeing it (using @ref AB_Account_List2_free).
 *
 * Please note that even while the list is owned by the caller the accounts
 * in that list are not! Sou you may not free any of those accounts in the
 * list (e.g. by calling @ref AB_Account_List2_FreeAll).
 *
 * @return The list of accounts, or NULL if there are none.
 * @param ab pointer to the AB_BANKING object
 */
AQBANKING_API 
AB_ACCOUNT_LIST2 *AB_Banking_GetAccounts(const AB_BANKING *ab);

/**
 * This function does an account lookup based on the given unique id.
 * This id is assigned by AqBanking when an account is added to AqBanking
 * via @ref AB_Banking_AddAccount.
 *
 * AqBanking remains the owner of the object returned (if any), so you must
 * not free it.
 *
 * Please also note that the object returned is only valid until
 * @ref AB_Banking_Fini() has been called (or until the corresponding backend
 * for this particular account has been deactivated).
 *
 * @return The account, or NULL if it is not found.
 * @param ab pointer to the AB_BANKING object
 * @param uniqueId unique id of the account assigned by AqBanking
 */
AQBANKING_API 
AB_ACCOUNT *AB_Banking_GetAccount(const AB_BANKING *ab,
                                  uint32_t uniqueId);

/**
 * This function does an account lookup based on the given bank code and
 * account number. No wildards or jokers allowed.
 *
 * AqBanking remains the owner of the object returned (if any), so you must
 * not free it.
 *
 * Please also note that the object returned is only valid until
 * @ref AB_Banking_Fini() has been called (or until the corresponding backend
 * for this particular account has been deactivated).
 *
 * @return The account, or NULL if it is not found.
 * @param ab pointer to the AB_BANKING object
 * @param bankCode bank code (use 0 if your country does not use bank codes)
 * @param accountId account number
 */
AQBANKING_API 
AB_ACCOUNT *AB_Banking_GetAccountByCodeAndNumber(const AB_BANKING *ab,
                                                 const char *bankCode,
                                                 const char *accountId);

/**
 * This function does an account lookup based on the given IBAN.
 * No wildards or jokers allowed.
 *
 * AqBanking remains the owner of the object returned (if any), so you must
 * not free it.
 *
 * Please also note that the object returned is only valid until
 * @ref AB_Banking_Fini() has been called (or until the corresponding backend
 * for this particular account has been deactivated).
 *
 * @return The account, or NULL if it is not found.
 * @param ab pointer to the AB_BANKING object
 * @param bankCode bank code (use 0 if your country does not use bank codes)
 * @param accountId account number
 */
AQBANKING_API 
AB_ACCOUNT *AB_Banking_GetAccountByIban(const AB_BANKING *ab,
					const char *iban);


/**
 * This function returns the first account which matches the given parameters.
 * For all parameters wildcards ("*") and joker ("?") are allowed.
 */
AQBANKING_API
AB_ACCOUNT *AB_Banking_FindAccount(const AB_BANKING *ab,
                                   const char *backendName,
                                   const char *country,
                                   const char *bankId,
                                   const char *accountId);

/**
 * This function returns a list of accounts which match the given
 * parameters.
 * For all parameters wildcards ("*") and joker ("?") are allowed.
 * If no account matches (or there simply are no accounts) then NULL is
 * returned.
 * The caller is responsible for freeing the list returned (ifany) by calling
 * @ref AB_Account_List2_free.
 * AqBanking still remains the owner of every account reported via this
 * function, so you MUST NOT call @ref AB_Account_List2_FreeAll.
 */
AQBANKING_API
AB_ACCOUNT_LIST2 *AB_Banking_FindAccounts(const AB_BANKING *ab,
                                          const char *backendName,
                                          const char *country,
                                          const char *bankId,
                                          const char *accountId);

/**
 * Creates an account and shows it to the backend (which might want to extend
 * the newly created account in order to associate some data with it).
 * The newly created account does not have a unique id yet. This id is
 * assigned upon @ref AB_Banking_AddAccount. The caller becomes the owner
 * of the object returned, so you must either call @ref AB_Banking_AddAccount
 * or @ref AB_Account_free on it.
 * This function does @b not add the user to AqBankings internal list.
 */
AQBANKING_API 
AB_ACCOUNT *AB_Banking_CreateAccount(AB_BANKING *ab, const char *backendName);

/**
 * Adds the given account to the internal list of accounts. Only now it gets a
 * unique id assigned to it.
 * AqBanking takes over the ownership of the given account, so you MUST NOT
 * call @ref AB_Account_free on it!
 */
AQBANKING_API 
int AB_Banking_AddAccount(AB_BANKING *ab, AB_ACCOUNT *a);

/**
 * Removes the given account from all internal lists and deletes the
 * object. The caller must not use the AB_ACCOUNT pointer anymore
 * after calling this function.
 *
 * @returns Zero on success, nonzero on error. 
 *
 * New in aqbanking-2.2.9.
 */
AQBANKING_API
int AB_Banking_DeleteAccount(AB_BANKING *ab, AB_ACCOUNT *a);
/*@}*/




/** @name Executing Jobs
 *
 */
/*@{*/
/**
 * <p>
 * This function sends all obs from the given list to their
 * respective backend. The results will be stored in the given im-/exporter
 * context.
 * </p>
 * <p>
 * This function does @b not take over or free the jobs.
 * </p>
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 * @param ab pointer to the AB_BANKING object
 * @param jl2 list of enqueued jobs to execute
 */
AQBANKING_API 
int AB_Banking_ExecuteJobs(AB_BANKING *ab, AB_JOB_LIST2 *jl2,
			   AB_IMEXPORTER_CONTEXT *ctx);
/*@}*/



/*@}*/ /* addtogroup */

#ifdef __cplusplus
}
#endif

#endif

