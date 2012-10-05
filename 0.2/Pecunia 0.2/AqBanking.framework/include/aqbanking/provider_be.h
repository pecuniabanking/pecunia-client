/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004-2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

/** @file provider_be.h
 * @short This file is used by provider backends.
 */


#ifndef AQBANKING_PROVIDER_BE_H
#define AQBANKING_PROVIDER_BE_H

#include <aqbanking/provider.h>
#include <aqbanking/user.h>

#include <gwenhywfar/plugin.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/dialog.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @addtogroup G_AB_PROVIDER
 *
 */
/*@{*/


#define AB_PROVIDER_FLAGS_HAS_NEWUSER_DIALOG     0x00000001
#define AB_PROVIDER_FLAGS_HAS_EDITUSER_DIALOG    0x00000002
#define AB_PROVIDER_FLAGS_HAS_NEWACCOUNT_DIALOG  0x00000004
#define AB_PROVIDER_FLAGS_HAS_EDITACCOUNT_DIALOG 0x00000008
#define AB_PROVIDER_FLAGS_HAS_USERTYPE_DIALOG    0x00000010


/**
 * This type is used with @ref AB_Provider_ExtendAccount and
 * @ref AB_Provider_ExtendUser.
 */
typedef enum {
  /** Object to be extended has just been created. For some backends this
   * means that some settings are allowed to be missing at this point.*/
  AB_ProviderExtendMode_Create=0,
  /** Object to be extended has been read from the configuration file */
  AB_ProviderExtendMode_Extend,
  /** Object to be extended has just been added to internal lists.
   * For the backend this might mean that the object should be completely
   * setup at this point. */
  AB_ProviderExtendMode_Add,
  /** Object to be extended is just about to be removed from the internal
   * list. */
  AB_ProviderExtendMode_Remove,
  /** This extend mode just lets the backend store data which has not yet
   * been stored into the users/accounts DB.
   * Please note that in this mode the backend might no longer be
   * initialized, so you should not call any other provider function (or call
   * @ref AB_Provider_IsInit to see whether the backend still is initialized).
   */
  AB_ProviderExtendMode_Save,

  /** This mode tells the backend to reload its configuration from the given
   * DB.
   */
  AB_ProviderExtendMode_Reload
} AB_PROVIDER_EXTEND_MODE;


/** @name Prototypes For Virtual Functions
 *
 */
/*@{*/
/**
 * See @ref AB_Provider_Init.
 */
typedef int (*AB_PROVIDER_INIT_FN)(AB_PROVIDER *pro, GWEN_DB_NODE *dbData);

/**
 * See @ref AB_Provider_Fini.
 */
typedef int (*AB_PROVIDER_FINI_FN)(AB_PROVIDER *pro, GWEN_DB_NODE *dbData);

/**
 * See @ref AB_Provider_UpdateJob
 */
typedef int (*AB_PROVIDER_UPDATEJOB_FN)(AB_PROVIDER *pro, AB_JOB *j);

/**
 * See @ref AB_Provider_AddJob.
 */
typedef int (*AB_PROVIDER_ADDJOB_FN)(AB_PROVIDER *pro, AB_JOB *j);

/**
 * See @ref AB_Provider_Execute
 */
typedef int (*AB_PROVIDER_EXECUTE_FN)(AB_PROVIDER *pro,
				      AB_IMEXPORTER_CONTEXT *ctx);


/**
 * See @ref AB_Provider_ResetQueue.
 */
typedef int (*AB_PROVIDER_RESETQUEUE_FN)(AB_PROVIDER *pro);


/**
 * See @ref AB_Provider_ExtendUser.
 */
typedef int (*AB_PROVIDER_EXTEND_USER_FN)(AB_PROVIDER *pro, AB_USER *u,
					  AB_PROVIDER_EXTEND_MODE um,
					  GWEN_DB_NODE *db);


/**
 * See @ref AB_Provider_ExtendAccount.
 */
typedef int (*AB_PROVIDER_EXTEND_ACCOUNT_FN)(AB_PROVIDER *pro,
                                             AB_ACCOUNT *a,
					     AB_PROVIDER_EXTEND_MODE um,
					     GWEN_DB_NODE *db);

typedef int (*AB_PROVIDER_UPDATE_FN)(AB_PROVIDER *pro,
                                     uint32_t lastVersion,
                                     uint32_t currentVersion);


typedef GWEN_DIALOG* (*AB_PROVIDER_GET_NEWUSER_DIALOG_FN)(AB_PROVIDER *pro, int i);

typedef GWEN_DIALOG* (*AB_PROVIDER_GET_EDITUSER_DIALOG_FN)(AB_PROVIDER *pro, AB_USER *u);

typedef GWEN_DIALOG* (*AB_PROVIDER_GET_NEWACCOUNT_DIALOG_FN)(AB_PROVIDER *pro);

typedef GWEN_DIALOG* (*AB_PROVIDER_GET_EDITACCOUNT_DIALOG_FN)(AB_PROVIDER *pro, AB_ACCOUNT *a);

typedef GWEN_DIALOG* (*AB_PROVIDER_GET_USERTYPE_DIALOG_FN)(AB_PROVIDER *pro);


/*@}*/





AQBANKING_API
AB_PROVIDER *AB_Provider_new(AB_BANKING *ab,
                             const char *name);

/**
 * @return 0 if the backend is not initialized, !=0 if it is
 */
AQBANKING_API
int AB_Provider_IsInit(const AB_PROVIDER *pro);


AQBANKING_API
void AB_Provider_AddFlags(AB_PROVIDER *pro, uint32_t fl);


/** @name Virtual Functions
 *
 */
/*@{*/

/**
 * Allow the backend to initialize itself.
 * @param pro backend object
 */
AQBANKING_API
int AB_Provider_Init(AB_PROVIDER *pro);

/**
 * Allow the backend to deinitialize itself.
 * @param pro backend object
 */
AQBANKING_API
int AB_Provider_Fini(AB_PROVIDER *pro);

/**
 * This function should check for the availability of the given job and
 * prepare it for the next call to @ref AB_PROVIDER_ADDJOB_FN.
 * If the job is available with this backend it should also set the job
 * parameters (such as the maximum number of purpose lines for transfer jobs
 * etc).
 * This function is called from the constructor AB_Job_new() in AqBanking.
 * The value returned here is stored within the job in question and becomes
 * available via @ref AB_Job_CheckAvailability.
 * @param pro backend object
 * @param j job to update
 */
AQBANKING_API
int AB_Provider_UpdateJob(AB_PROVIDER *pro, AB_JOB *j);

/**
 * <p>
 * Add the given job to the backend's internal queue. This is an immediate
 * queue, it is not persistent. The queue is flushed by
 * @ref AB_PROVIDER_EXECUTE_FN. The added job is removed in any case
 * after @ref AB_PROVIDER_EXECUTE_FN has been called.
 * </p>
 * <p>
 * This function should first check the job arguments (sanity checks etc).
 * If this function returns an error the job MUST NOT be enqueued in the
 * providers own queue. In this case the job will be marked "errornous".
 * </p>
 * <p>
 * However, if the backend prepares the job well enough (via
 * @ref AB_PROVIDER_UPDATEJOB_FN) then the application should have made sure
 * that the job complies to the rules laid out by the backend. So rejecting
 * a job here should be a rare case with well-designed applications and
 * backends.
 * </p>
 * @param pro backend object
 */
AQBANKING_API
int AB_Provider_AddJob(AB_PROVIDER *pro, AB_JOB *j);

/**
 * Executes all jobs in the queue which have just been added via
 * @ref AB_PROVIDER_ADDJOB_FN. After calling this function @b all jobs are
 * removed from the backend's queue in any case.
 * @param pro backend object
 * @param ctx im-/exporter context to receive responses
 */
AQBANKING_API
int AB_Provider_Execute(AB_PROVIDER *pro, AB_IMEXPORTER_CONTEXT *ctx);

/**
 * Resets the queue of the backend.
 * After calling this function @b all jobs are removed from the
 * backend's queue in any case.
 * @param pro backend object
 */
AQBANKING_API
int AB_Provider_ResetQueue(AB_PROVIDER *pro);


/**
 * Allows the backend to extend the given user (e.g. load backend-specific
 * data for the given user).
 */
AQBANKING_API
int AB_Provider_ExtendUser(AB_PROVIDER *pro, AB_USER *u,
			   AB_PROVIDER_EXTEND_MODE em,
			   GWEN_DB_NODE *db);


/**
 * Allows the backend to extend the given account (e.g. load backend-specific
 * data for the given account).
 */
AQBANKING_API
int AB_Provider_ExtendAccount(AB_PROVIDER *pro, AB_ACCOUNT *a,
			      AB_PROVIDER_EXTEND_MODE em,
			      GWEN_DB_NODE *db);


/**
 * Allows the backend to update AqBanking data.
 * This function is called for each active provider after all backends, users
 * and accounts have been loaded and initialised but before loading the
 * outbox jobs.
 */
AQBANKING_API
int AB_Provider_Update(AB_PROVIDER *pro,
                       uint32_t lastVersion,
                       uint32_t currentVersion);


/**
 * Create a dialog which allows to create a new user.
 * The dialog returned (if any) must be derived via @ref AB_NewUserDialog_new().
 * @param pro pointer to the backend for which a new user is to be created
 * @param i additional parameter depending on the backend. it can be used
 *   to specify the user type to be created (e.g. for HBCI those values
 *   specify whether PIN/TAN, keyfile or chipcard users are to be created).
 *   Use value 0 for the generic dialog.
 */
AQBANKING_API
GWEN_DIALOG *AB_Provider_GetNewUserDialog(AB_PROVIDER *pro, int i);

AQBANKING_API
GWEN_DIALOG *AB_Provider_GetEditUserDialog(AB_PROVIDER *pro, AB_USER *u);

/**
 * Create a dialog which allows to create a new account.
 * The dialog returned (if any) must be derived via @ref AB_NewAccountDialog_new().
 */
AQBANKING_API
GWEN_DIALOG *AB_Provider_GetNewAccountDialog(AB_PROVIDER *pro);

AQBANKING_API
GWEN_DIALOG *AB_Provider_GetEditAccountDialog(AB_PROVIDER *pro, AB_ACCOUNT *a);


AQBANKING_API
GWEN_DIALOG *AB_ProviderGetUserTypeDialog(AB_PROVIDER *pro);


/*@}*/



/** @name Setters For Virtual Functions
 *
 */
/*@{*/
AQBANKING_API
void AB_Provider_SetInitFn(AB_PROVIDER *pro, AB_PROVIDER_INIT_FN f);
AQBANKING_API
void AB_Provider_SetFiniFn(AB_PROVIDER *pro, AB_PROVIDER_FINI_FN f);

AQBANKING_API
void AB_Provider_SetUpdateJobFn(AB_PROVIDER *pro, AB_PROVIDER_UPDATEJOB_FN f);
AQBANKING_API
void AB_Provider_SetAddJobFn(AB_PROVIDER *pro, AB_PROVIDER_ADDJOB_FN f);
AQBANKING_API
void AB_Provider_SetExecuteFn(AB_PROVIDER *pro, AB_PROVIDER_EXECUTE_FN f);
AQBANKING_API
void AB_Provider_SetResetQueueFn(AB_PROVIDER *pro, AB_PROVIDER_RESETQUEUE_FN f);

AQBANKING_API
void AB_Provider_SetExtendUserFn(AB_PROVIDER *pro,
                                 AB_PROVIDER_EXTEND_USER_FN f);

AQBANKING_API
void AB_Provider_SetExtendAccountFn(AB_PROVIDER *pro,
                                    AB_PROVIDER_EXTEND_ACCOUNT_FN f);

AQBANKING_API
void AB_Provider_SetUpdateFn(AB_PROVIDER *pro, AB_PROVIDER_UPDATE_FN f);

AQBANKING_API
void AB_Provider_SetGetNewUserDialogFn(AB_PROVIDER *pro, AB_PROVIDER_GET_NEWUSER_DIALOG_FN f);

AQBANKING_API
void AB_Provider_SetGetEditUserDialogFn(AB_PROVIDER *pro, AB_PROVIDER_GET_EDITUSER_DIALOG_FN f);

AQBANKING_API
void AB_Provider_SetGetNewAccountDialogFn(AB_PROVIDER *pro, AB_PROVIDER_GET_NEWACCOUNT_DIALOG_FN f);

AQBANKING_API
void AB_Provider_SetGetEditAccountDialogFn(AB_PROVIDER *pro, AB_PROVIDER_GET_EDITACCOUNT_DIALOG_FN f);

AQBANKING_API
void AB_Provider_SetGetUserTypeDialogFn(AB_PROVIDER *pro, AB_PROVIDER_GET_USERTYPE_DIALOG_FN f);

/*@}*/




typedef AB_PROVIDER* (*AB_PLUGIN_PROVIDER_FACTORY_FN)(GWEN_PLUGIN *pl,
						      AB_BANKING *ab);


AQBANKING_API
GWEN_PLUGIN *AB_Plugin_Provider_new(GWEN_PLUGIN_MANAGER *pm,
				    const char *name,
				    const char *fileName);


AQBANKING_API
AB_PROVIDER *AB_Plugin_Provider_Factory(GWEN_PLUGIN *pl, AB_BANKING *ab);

AQBANKING_API
void AB_Plugin_Provider_SetFactoryFn(GWEN_PLUGIN *pl,
				     AB_PLUGIN_PROVIDER_FACTORY_FN fn);




/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif




#endif /* AQBANKING_PROVIDER_BE_H */









