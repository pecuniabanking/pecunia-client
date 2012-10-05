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

/** @file aqbanking/provider.h
 * @short This file is used by AqBanking and provider backends.
 */


#ifndef AQBANKING_PROVIDER_H
#define AQBANKING_PROVIDER_H


#include <gwenhywfar/misc.h>
#include <gwenhywfar/list2.h>
#include <gwenhywfar/inherit.h>
#include <gwenhywfar/xml.h>
#include <aqbanking/error.h> /* for AQBANKING_API */


#define AB_PROVIDER_FLAGS_COMPLETE_DAY_REPORTS 0x00000001


#ifdef __cplusplus
extern "C" {
#endif

typedef struct AB_PROVIDER AB_PROVIDER;
GWEN_INHERIT_FUNCTION_LIB_DEFS(AB_PROVIDER, AQBANKING_API)

typedef struct AB_PROVIDER_DESCRIPTION AB_PROVIDER_DESCRIPTION;
GWEN_INHERIT_FUNCTION_LIB_DEFS(AB_PROVIDER_DESCRIPTION, AQBANKING_API)
GWEN_LIST_FUNCTION_LIB_DEFS(AB_PROVIDER_DESCRIPTION, AB_ProviderDescription,
                            AQBANKING_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(AB_PROVIDER_DESCRIPTION, AB_ProviderDescription,
                             AQBANKING_API)

#ifdef __cplusplus
}
#endif


#include <aqbanking/banking.h>
#include <aqbanking/error.h>
#include <aqbanking/job.h>
#include <aqbanking/account.h>
#include <aqbanking/transaction.h>


#ifdef __cplusplus
extern "C" {
#endif

/** @addtogroup G_AB_PROVIDER
 *
 * @brief This group represents backends. (Don't use in applications)
 *
 * <p>
 * (<i>Provider</i> is simply another word for <i>backend</i>.)
 * </p>
 *
 * <p>
 * Functions in this group <b>MUST NEVER</b> be used by applications or
 * depending libraries ! They may only be called by AqBanking or a provider
 * on its own.
 * </p>
 *
 * <p>
 * Writing an online banking provider for AqBanking is easy. There are only
 * a few callback functions which must be set by the provider (marked as
 * <i>Virtual Functions</i> below).
 * </p>
 *
 * <p>
 * The work of a provider is based on jobs (see @ref AB_JOB).
 * AqBanking also works based on jobs. If the application wants to create
 * a job AqBanking calls the function @ref AB_Provider_UpdateJob. This
 * function lets the provider prepare some parameters for the job given (e.g.
 * the maximum number of purpose lines for transfer jobs etc). These limits
 * are used by applications when preparing a job.
 * </p>
 * <p>
 * If the application is finished preparing the job it calls
 * @ref AB_Banking_EnqueueJob. After the application has enqueued all jobs
 * it calls @ref AB_Banking_ExecuteQueue. This function now sends all jobs
 * to their respective providers using @ref AB_Provider_AddJob. When all
 * jobs for a given provider are added AqBanking calls
 * @ref AB_Provider_Execute on this provider. This functions really sends the
 * jobs to the bank server or creates DTAUS discs or whatever the provider is
 * supposed to do.
 * After that AqBanking calls @ref AB_Provider_ResetQueue to make sure no job
 * is left in the providers queue after execution.
 * </p>
 * <p>
 * Another base class used between AqBanking and providers is @ref AB_ACCOUNT.
 * An account stores a reference to its associated provider.
 * When executing @ref AB_Banking_Init AqBanking calls the provider function
 * @ref AB_Provider_ExtendAccount on every account to let the backend
 * initialize the account.
 * </p>
 * <p>
 * It is the same with @ref AB_USER.
 * </p>
 */
/*@{*/

/**
 * Returns the name of the backend (e.g. "aqhbci").
 */
AQBANKING_API
const char *AB_Provider_GetName(const AB_PROVIDER *pro);

/**
 * Returns the escaped name of the backend. This is needed when using the
 * name of the backend to form a file path.
 */
AQBANKING_API
const char *AB_Provider_GetEscapedName(const AB_PROVIDER *pro);
/** 
 * Returns the Banking object that this Provider belongs to. 
 */
AQBANKING_API
AB_BANKING *AB_Provider_GetBanking(const AB_PROVIDER *pro);


AQBANKING_API
uint32_t AB_Provider_GetFlags(const AB_PROVIDER *pro);

/**
 * This copies the name of the folder for AqBanking's backend data into
 * the given GWEN_Buffer. This folder is reserved for this backend.
 * Please note that this folder does not necessarily exist, but the backend
 * is free to create it.
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 * @param pro pointer to the provider object
 * @param buf buffer to append the path name to
 */
AQBANKING_API
int AB_Provider_GetUserDataDir(const AB_PROVIDER *pro, GWEN_BUFFER *buf);


/*@}*/ /* defgroup */

#ifdef __cplusplus
}
#endif




#endif /* AQBANKING_PROVIDER_H */









