/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/

/** @file 
 * @short The main interface of the aqbanking library
 */

#ifndef AQBANKING_BANKING_H
#define AQBANKING_BANKING_H


/** @addtogroup G_AB_BANKING Main Interface
 */
/*@{*/

/**
 * Object to be operated on by functions in this group (@ref AB_BANKING).
 */
typedef struct AB_BANKING AB_BANKING;
/*@}*/



#include <gwenhywfar/inherit.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/stringlist.h>
#include <gwenhywfar/plugindescr.h>
#include <gwenhywfar/dialog.h>

#include <aqbanking/error.h> /* for AQBANKING_API */
#include <aqbanking/version.h>

/* outsourced */
#include <aqbanking/banking_virt.h>
#include <aqbanking/banking_imex.h>
#include <aqbanking/banking_info.h>
#include <aqbanking/banking_ob.h>
#include <aqbanking/banking_simple.h>
#include <aqbanking/banking_cfg.h>

#include <aqbanking/provider.h>

#define AB_PM_LIBNAME    "aqbanking"
#define AB_PM_SYSCONFDIR "sysconfdir"
#define AB_PM_DATADIR    "datadir"
#define AB_PM_WIZARDDIR  "wizarddir"
#define AB_PM_LOCALEDIR  "localedir"



#ifdef __cplusplus
extern "C" {
#endif



/** @addtogroup G_AB_BANKING Main Interface
 *
 * @short This group contains the main API function group.
 *
 * <p>
 * A program should first call @ref AB_Banking_Init to allow AqBanking
 * to load its configuration files and initialize itself.
 * </p>
 * After that you may call any other function of this group (most likely
 * the program will request a list of managed account via
 * @ref AB_Banking_GetAccounts).
 * </p>
 * <p>
 * When the program has finished its work it should call @ref AB_Banking_Fini
 * as the last function of AqBanking (just before calling
 * @ref AB_Banking_free).
 * </p>
 */
/*@{*/

/** @name Extensions supported by the application
 *
 */
/*@{*/
#define AB_BANKING_EXTENSION_NONE             0x00000000
/*@}*/


/**
 * This object is prepared to be inherited (using @ref GWEN_INHERIT_SETDATA).
 */
GWEN_INHERIT_FUNCTION_LIB_DEFS(AB_BANKING, AQBANKING_API)



/** @name Constructor, Destructor, Init, Fini
 *
 */
/*@{*/

/**
 * <p>
 * Creates an instance of AqBanking. Though AqBanking is quite object
 * oriented (and thus allows multiple instances of AB_BANKING to co-exist)
 * you should avoid having multiple AB_BANKING objects in parallel.
 * </p>
 * <p>
 * This is just because the backends are loaded dynamically and might not like
 * to be used with multiple instances of AB_BANKING in parallel.
 * </p>
 * <p>
 * You should later free this object using @ref AB_Banking_free.
 * </p>
 * <p>
 * This function does not actually load the configuration file or setup
 * AqBanking, that is performed by @ref AB_Banking_Init and
 * @ref AB_Banking_OnlineInit, respectively.
 * </p>
 *
 * @return new instance of AB_BANKING
 *
 * @param appName name of the application which wants to use AqBanking.
 * This allows AqBanking to separate settings and data for multiple
 * applications.
 *
 * @param dname Path for the directory containing the user data of
 * AqBanking. You should in most cases present a NULL for this
 * parameter, which means AqBanking will choose the default user
 * data folder which is "$HOME/.aqbanking".
 * The configuration itself is handled using GWEN's GWEN_ConfigMgr
 * module (see @ref GWEN_ConfigMgr_Factory). That module stores the
 * configuration in AqBanking's subfolder "settings" (i.e. the
 * full path to the user/account configuration is "$HOME/.aqbanking/settings").
 *
 * @param extensions use 0 for now.
 */
AQBANKING_API
AB_BANKING *AB_Banking_new(const char *appName,
			   const char *dname,
			   uint32_t extensions);


/**
 * Destroys the given instance of AqBanking. Please note that if
 * @ref AB_Banking_Init has been called on this object then
 * @ref  AB_Banking_Fini should be called before this function.
 */
AQBANKING_API 
void AB_Banking_free(AB_BANKING *ab);


AQBANKING_API 
void AB_Banking_GetVersion(int *major,
			   int *minor,
			   int *patchlevel,
			   int *build);


/**
 * Initializes AqBanking.
 * This sets up the plugins, plugin managers and path managers.
 * If you want to use online banking tasks you must also call
 * @ref AB_Banking_OnlineInit afterwards.
 *
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 *
 * @param ab banking interface
 */
AQBANKING_API 
int AB_Banking_Init(AB_BANKING *ab);

/**
 * Deinitializes AqBanking thus allowing it to save its data and to unload
 * backends.
 * Please remember to call @ref AB_Banking_OnlineFini before this function
 * if you have used online banking functions.
 *
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 *
 * @param ab banking interface
 */
AQBANKING_API 
int AB_Banking_Fini(AB_BANKING *ab);


/**
 * Setup the online banking part of AqBanking. This function actually loads
 * the users and accounts.
 *
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 *
 * @param ab banking interface
 */
AQBANKING_API 
int AB_Banking_OnlineInit(AB_BANKING *ab);


/**
 * Uninitialize the online banking part of AqBanking.
 *
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 *
 * @param ab banking interface
 */
AQBANKING_API 
int AB_Banking_OnlineFini(AB_BANKING *ab);


/*@}*/



/** @name Working With Backends
 *
 */
/*@{*/

/**
 * Returns a list of the names of currently active providers.
 */
AQBANKING_API
const GWEN_STRINGLIST *AB_Banking_GetActiveProviders(const AB_BANKING *ab);

AQBANKING_API
GWEN_PLUGIN_DESCRIPTION_LIST2 *AB_Banking_GetProviderDescrs(AB_BANKING *ab);

/**
 * Create a dialog which allows to create a new user.
 *
 * @return dialog
 *
 * @param ab pointer to the AqBanking object
 *
 * @param backend name of the backend for which a user is to be created
 *   (e.g. "aqhbci", "aqebics" etc)
 *
 * @param mode additional parameter depending on the backend. it can be used
 *   to specify the user type to be created (e.g. for HBCI those values
 *   specify whether PIN/TAN, keyfile or chipcard users are to be created,
 *   see @ref AqHBCI_NewUserDialog_CodeGeneric and following).
 *   Use value 0 for the generic dialog.
 */
AQBANKING_API 
GWEN_DIALOG *AB_Banking_GetNewUserDialog(AB_BANKING *ab,
					 const char *backend,
					 int mode);

/*@}*/



/** @name Working With Backends (Deprecated)
 *
 * <p>
 *   These functions are now deprecated and will be removed prior to the release
 *   of AqBanking5.
 * </p>
 * <p>
 *   Since AqBanking5 configuration dialogs
 *   and assistents are implemented using GWEN's Dialog Framework. This framework
 *   allows for platform-independent dialogs (see @ref AB_ImporterDialog_new).
 * </p>
 */
/*@{*/


/**
 * This function is deprecated and will be removed for the final release
 * of AqBanking5.
 * You can use @ref AB_SetupDialog_new to create the new setup dialog within your
 * application and run it via @ref GWEN_Dialog_Exec().
 */
AQBANKING_API AQBANKING_DEPRECATED
int AB_Banking_FindWizard(AB_BANKING *ab,
                          const char *backend,
                          const char *frontends,
                          GWEN_BUFFER *pbuf);

AQBANKING_API AQBANKING_DEPRECATED
int AB_Banking_FindDebugger(AB_BANKING *ab,
			    const char *backend,
			    const char *frontends,
                            GWEN_BUFFER *pbuf);


/*@}*/



/** @name Application Data
 *
 * Applications may let AqBanking store global application specific data.
 */
/*@{*/
/**
 * Returns the application name as given to @ref AB_Banking_new.
 * @param ab pointer to the AB_BANKING object
 */
AQBANKING_API 
const char *AB_Banking_GetAppName(const AB_BANKING *ab);

/**
 * Returns the escaped version of the application name. This name can
 * safely be used to create file paths since all special characters (like
 * '/', '.' etc) are escaped.
 * @param ab pointer to the AB_BANKING object
 */
AQBANKING_API 
const char *AB_Banking_GetEscapedAppName(const AB_BANKING *ab);

/**
 * Returns the name of the user folder for AqBanking's data.
 * Normally this is something like "/home/me/.aqbanking".
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 * @param ab pointer to the AB_BANKING object
 * @param buf GWEN_BUFFER to append the path name to
 */
AQBANKING_API 
int AB_Banking_GetUserDataDir(const AB_BANKING *ab, GWEN_BUFFER *buf);

/**
 * Returns the name of the user folder for application data.
 * Normally this is something like "/home/me/.aqbanking/apps".
 * Your application may choose to create folders below this one to store
 * user data. If you only add AqBanking to an existing program to add
 * home banking support you will most likely use your own folders and thus
 * won't need this function.
 * @return 0 if ok, error code otherwise (see @ref AB_ERROR)
 * @param ab pointer to the AB_BANKING object
 * @param buf GWEN_BUFFER to append the path name to
 */
AQBANKING_API 
int AB_Banking_GetAppUserDataDir(const AB_BANKING *ab, GWEN_BUFFER *buf);

/**
 * Returns the path to a folder to which shared data can be stored.
 * This might be used by multiple applications if they wish to share some
 * of their data, e.g. QBankManager and AqMoney3 share their transaction
 * storage so that both may work with it.
 * Please note that this folder does not necessarily exist, but you are free
 * to create it.
 */
AQBANKING_API 
int AB_Banking_GetSharedDataDir(const AB_BANKING *ab,
                                const char *name,
                                GWEN_BUFFER *buf);

/** Returns the void pointer that was stored by
 * AB_Banking_SetUserData(). This might be useful for passing data to
 * the callback functions.
 *
 * On the other hand, we strongly encourage using the GWEN_INHERIT
 * macros to store non-trivial data structures in this object. 
 *
 * @param ab Pointer to the AB_BANKING object
 */
AQBANKING_API
void *AB_Banking_GetUserData(AB_BANKING *ab);

/** Save the void pointer that can be retrieved by
 * AB_Banking_GetUserData(). This might be useful for passing data to
 * the callback functions.
 *
 * On the other hand, we strongly encourage using the GWEN_INHERIT
 * macros to store non-trivial data structures in this object. 
 *
 * @param ab Pointer to the AB_BANKING object
 * @param user_data Arbitrary pointer to be stored in the AB_BANKING
 */
AQBANKING_API
void AB_Banking_SetUserData(AB_BANKING *ab, void *user_data);

/*@}*/






/** @name Plugin Handling
 *
 * These functions are also obsolete and will be removed for AqBanking5.
 */
/*@{*/


AQBANKING_API AQBANKING_DEPRECATED
GWEN_PLUGIN_DESCRIPTION_LIST2 *AB_Banking_GetWizardDescrs(AB_BANKING *ab);


AQBANKING_API AQBANKING_DEPRECATED
GWEN_PLUGIN_DESCRIPTION_LIST2 *AB_Banking_GetDebuggerDescrs(AB_BANKING *ab,
                                                            const char *pn);
/*@}*/



/*@}*/ /* addtogroup */


#ifdef __cplusplus
}
#endif



#endif



