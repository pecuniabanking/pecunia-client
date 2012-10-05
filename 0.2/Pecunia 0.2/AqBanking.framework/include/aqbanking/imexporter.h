/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004-2010 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_IMEXPORTER_H
#define AQBANKING_IMEXPORTER_H

#include <gwenhywfar/inherit.h>
#include <gwenhywfar/syncio.h>
#include <gwenhywfar/db.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/dialog.h>

#include <aqbanking/error.h>
#include <aqbanking/accstatus.h>


/** @addtogroup G_AB_IMEXPORTER Generic Im- and Exporter
 *
 * @short Generic Financial Data Importer/Exporter
 * <p>
 * This group contains a generic importer/exporter.
 * </p>
 * <h2>Importing</h2>
 * <p>
 * When importing this group reads transactions and accounts from a
 * given stream (in most cases a file) and stores them in a given
 * importer context.
 * </p>
 * <p>
 * The application can later browse through all transactions stored within the
 * given context and import them into its own database as needed.
 * </p>
 */
/*@{*/



/** @name Flags returned by @ref AB_ImExporter_GetFlags
 *
 */
/*@{*/

/** This module supports the function @ref AB_ImExporter_GetEditProfileDialog */
#define AB_IMEXPORTER_FLAGS_GETPROFILEEDITOR_SUPPORTED 0x00000001


/*@}*/



#ifdef __cplusplus
extern "C" {
#endif

typedef struct AB_IMEXPORTER AB_IMEXPORTER;
GWEN_INHERIT_FUNCTION_LIB_DEFS(AB_IMEXPORTER, AQBANKING_API)

typedef struct AB_IMEXPORTER_CONTEXT AB_IMEXPORTER_CONTEXT;
typedef struct AB_IMEXPORTER_ACCOUNTINFO AB_IMEXPORTER_ACCOUNTINFO;
#ifdef __cplusplus
}
#endif


#include <aqbanking/banking.h>
#include <aqbanking/account.h>
#include <aqbanking/transaction.h>
#include <aqbanking/security.h>
#include <aqbanking/message.h>


#ifdef __cplusplus
extern "C" {
#endif


/** @name Virtual Functions for Backends
 *
 */
/*@{*/

/**
 * Reads the given stream and imports all data from it. This imported
 * data is stored within the given context.
 * @param ie pointer to the importer/exporter
 * @param ctx import context
 * @param bio stream to read from (usually a file, see
 *   @ref GWEN_BufferedIO_File_new)
 * @param dbProfile configuration data for the importer. You can get this
 *   using @ref AB_Banking_GetImExporterProfiles.
 */
AQBANKING_API 
int AB_ImExporter_Import(AB_IMEXPORTER *ie,
                         AB_IMEXPORTER_CONTEXT *ctx,
			 GWEN_SYNCIO *sio,
			 GWEN_DB_NODE *dbProfile);

/**
 * Writes all data to the given stream.
 * @param ie pointer to the importer/exporter
 * @param ctx export context
 * @param bio stream to write to (usually a file, see
 *   @ref GWEN_BufferedIO_File_new)
 * @param dbProfile configuration data for the exporter. You can get this
 *   using @ref AB_Banking_GetImExporterProfiles.
 */
AQBANKING_API 
int AB_ImExporter_Export(AB_IMEXPORTER *ie,
                         AB_IMEXPORTER_CONTEXT *ctx,
			 GWEN_SYNCIO *sio,
			 GWEN_DB_NODE *dbProfile);

/**
 * This function should return a dialog (see @ref GWEN_DIALOG) which
 * allows editing of the given profile.
 * You can use @ref AB_ImExporter_GetFlags to determine beforehand whether
 * this function is supported (look for
 * @ref AB_IMEXPORTER_FLAGS_GETPROFILEEDITOR_SUPPORTED).
 * (introduced in AqBanking 4.3.0)
 *
 * @param ie pointer to the importer/exporter
 *
 * @param dbProfile configuration data for the exporter. You can get this
 *   using @ref AB_Banking_GetImExporterProfiles.
 *
 * @param pDlg pointer to a dialog pointer (receives the created dialog if any)
 *
 * @return 0 on success, error code otherwise
 */
AQBANKING_API
int AB_ImExporter_GetEditProfileDialog(AB_IMEXPORTER *ie,
				       GWEN_DB_NODE *dbProfile,
				       const char *testFileName,
				       GWEN_DIALOG **pDlg);


/**
 * This is just a convenience function for @ref AB_ImExporter_Import.
 */
AQBANKING_API
int AB_ImExporter_ImportFile(AB_IMEXPORTER *ie,
                             AB_IMEXPORTER_CONTEXT *ctx,
                             const char *fname,
			     GWEN_DB_NODE *dbProfile);

AQBANKING_API
int AB_ImExporter_ImportBuffer(AB_IMEXPORTER *ie,
			       AB_IMEXPORTER_CONTEXT *ctx,
                               GWEN_BUFFER *buf,
			       GWEN_DB_NODE *dbProfile);

AQBANKING_API
int AB_ImExporter_ExportToBuffer(AB_IMEXPORTER *ie,
				 AB_IMEXPORTER_CONTEXT *ctx,
				 GWEN_BUFFER *buf,
				 GWEN_DB_NODE *dbProfile);

AQBANKING_API
int AB_ImExporter_ExportToFile(AB_IMEXPORTER *ie,
			       AB_IMEXPORTER_CONTEXT *ctx,
			       const char *fname,
			       GWEN_DB_NODE *dbProfile);

/**
 * This function checks whether the given importer supports the given file.
 */
AQBANKING_API
int AB_ImExporter_CheckFile(AB_IMEXPORTER *ie,
			    const char *fname);

/*@}*/


/**
 * Returns the AB_BANKING object to which the im/exporter belongs.
 */
AQBANKING_API 
AB_BANKING *AB_ImExporter_GetBanking(const AB_IMEXPORTER *ie);

/**
 * Returns the name of the im/exporter.
 */
AQBANKING_API
const char *AB_ImExporter_GetName(const AB_IMEXPORTER *ie);


/**
 * Returns the flags if this im/exporter which specify the supported
 * features.
 */
AQBANKING_API
uint32_t AB_ImExporter_GetFlags(const AB_IMEXPORTER *ie);


/*@}*/ /* defgroup */



/** @defgroup AB_IMEXPORTER_CONTEXT Im- and Exporter Context
 * @ingroup G_AB_IMEXPORTER
 *
 * A context contains the list of accounts for which data has been imported
 * or which are to be exported.
 * These accounts each contain a list of imported/to be exported
 * transactions.
 */
/*@{*/
AQBANKING_API 
AB_IMEXPORTER_CONTEXT *AB_ImExporterContext_new();

AQBANKING_API
void AB_ImExporterContext_free(AB_IMEXPORTER_CONTEXT *iec);

/**
 * This function clears the context (e.g. removes all transactions etc).
 * (introduced in AqBanking 4.3.0)
 */
AQBANKING_API
void AB_ImExporterContext_Clear(AB_IMEXPORTER_CONTEXT *iec);

/** Stores a complete import/export context to a GWEN_DB.
 *
 */
AQBANKING_API 
int AB_ImExporterContext_toDb(const AB_IMEXPORTER_CONTEXT *iec,
                              GWEN_DB_NODE *db);

/** Restores a complete import/export context from a GWEN_DB.
 *
 */
AQBANKING_API 
AB_IMEXPORTER_CONTEXT *AB_ImExporterContext_fromDb(GWEN_DB_NODE *db);


AQBANKING_API 
int AB_ImExporterContext_ReadDb(AB_IMEXPORTER_CONTEXT *iec,
                                GWEN_DB_NODE *db);


/**
 * Adds the content of the second context to the first one.
 * Frees the second context.
 */
AQBANKING_API 
void AB_ImExporterContext_AddContext(AB_IMEXPORTER_CONTEXT *iec,
                                     AB_IMEXPORTER_CONTEXT *toAdd);

/**
 * Takes over ownership of the given account info.
 */
AQBANKING_API 
void AB_ImExporterContext_AddAccountInfo(AB_IMEXPORTER_CONTEXT *iec,
                                         AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * Returns the first imported account (if any).
 * The context remains the owner of the object returned.
 */
AQBANKING_API 
AB_IMEXPORTER_ACCOUNTINFO*
AB_ImExporterContext_GetFirstAccountInfo(AB_IMEXPORTER_CONTEXT *iec);

/**
 * Returns the next account data has been imported for.
 * The context remains the owner of the object returned.
 */
AQBANKING_API 
AB_IMEXPORTER_ACCOUNTINFO*
AB_ImExporterContext_GetNextAccountInfo(AB_IMEXPORTER_CONTEXT *iec);

/** Callback function type for
 * AB_ImExporterContext_AccountInfoForEach()
 *
 * (As soon as a ACCOUNTINFO_LIST2 is declared in this header,
 * this declaration can be removed.)  */
typedef AB_IMEXPORTER_ACCOUNTINFO *
(AB_IMEXPORTER_ACCOUNTINFO_LIST2_FOREACH)(AB_IMEXPORTER_ACCOUNTINFO *element,
					  void *user_data);

/** Traverses the list of account infos in this context, calling
 * the callback function 'func' on each list element.  Traversal
 * will stop when 'func' returns a non-NULL value, and the routine
 * will return with that value. Otherwise the routine will return
 * NULL.
 *
 * Note: Every list element is still owned by the
 * IMEXPORTER_CONTEXT object, so it must neither be free'd nor
 * stored anywhere outside the lifecyle of this
 * AB_IMEXPORTER_CONTEXT.
 *
 * Available since aqbanking-1.9.7.
 *
 * @param iec The importer context.
 * @param func The function to be called with each list element.
 * @param user_data A pointer passed on to the function 'func'.
 * @return The non-NULL pointer returned by 'func' as soon as it
 * returns one. Otherwise (i.e. 'func' always returns NULL)
 * returns NULL.
 */
AQBANKING_API
AB_IMEXPORTER_ACCOUNTINFO *
AB_ImExporterContext_AccountInfoForEach(AB_IMEXPORTER_CONTEXT *iec,
					AB_IMEXPORTER_ACCOUNTINFO_LIST2_FOREACH func,
					void* user_data);

/**
 * Looks for account info for the given account. If it is not found 0 is
 * returned.
 * The context remains the owner of the returned object.
 */
AQBANKING_API 
AB_IMEXPORTER_ACCOUNTINFO*
AB_ImExporterContext_FindAccountInfo(AB_IMEXPORTER_CONTEXT *iec,
				     const char *bankCode,
				     const char *accountNumber);

/**
 * Looks for account info for the given account. If there is none it will
 * be created and added to the context.
 * The context remains the owner of the returned object.
 */
AQBANKING_API
AB_IMEXPORTER_ACCOUNTINFO*
AB_ImExporterContext_GetAccountInfo(AB_IMEXPORTER_CONTEXT *iec,
                                    const char *bankCode,
                                    const char *accountNumber);

AQBANKING_API
int AB_ImExporterContext_GetAccountInfoCount(const AB_IMEXPORTER_CONTEXT *iec);

/**
 * This is just a convenience function. It takes the bank code and
 * account number from the account, and then calls
 * @ref AB_ImExporterContext_GetAccountInfo and
 * @ref AB_ImExporterAccountInfo_AddTransaction.
 * If you want to add many transactions which are sorted by account
 * it is much faster to avoid this function and to select the appropriate
 * account info object once before importing all transactions for this
 * particular account. This would save you the additional lookup before
 * every transaction.
 */
AQBANKING_API
void AB_ImExporterContext_AddTransaction(AB_IMEXPORTER_CONTEXT *iec,
                                         AB_TRANSACTION *t);


/**
 * This is just a convenience function. It takes the bank code and
 * account number from the account, and then calls
 * @ref AB_ImExporterContext_GetAccountInfo and
 * @ref AB_ImExporterAccountInfo_AddTransfer.
 * If you want to add many transfers which are sorted by account
 * it is much faster to avoid this function and to select the appropriate
 * account info object once before importing all transactions for this
 * particular account. This would save you the additional lookup before
 * every transaction.
 */
AQBANKING_API
void AB_ImExporterContext_AddTransfer(AB_IMEXPORTER_CONTEXT *iec,
				      AB_TRANSACTION *t);


AQBANKING_API
void AB_ImExporterContext_AddStandingOrder(AB_IMEXPORTER_CONTEXT *iec,
					   AB_TRANSACTION *t);


AQBANKING_API
void AB_ImExporterContext_AddDatedTransfer(AB_IMEXPORTER_CONTEXT *iec,
					   AB_TRANSACTION *t);



/** @defgroup AB_IMEXPORTER_CONTEXT_SECURITY Securities
 *
 * These functions handle stocks, mutual funds etc.
 */
/**@{*/
AQBANKING_API 
void AB_ImExporterContext_AddSecurity(AB_IMEXPORTER_CONTEXT *iec,
				      AB_SECURITY *sec);

AQBANKING_API 
AB_SECURITY*
AB_ImExporterContext_GetFirstSecurity(AB_IMEXPORTER_CONTEXT *iec);

AQBANKING_API 
AB_SECURITY*
AB_ImExporterContext_GetNextSecurity(AB_IMEXPORTER_CONTEXT *iec);

AQBANKING_API 
AB_SECURITY*
AB_ImExporterContext_FindSecurity(AB_IMEXPORTER_CONTEXT *iec,
				  const char *nameSpace,
				  const char *id);

/**@}*/



/** @defgroup AB_IMEXPORTER_CONTEXT_MESSAGE Messages
 *
 * These functions handle messages received from a bank.
 */
/**@{*/
AQBANKING_API 
void AB_ImExporterContext_AddMessage(AB_IMEXPORTER_CONTEXT *iec,
				     AB_MESSAGE *msg);

AQBANKING_API 
AB_MESSAGE*
AB_ImExporterContext_GetFirstMessage(AB_IMEXPORTER_CONTEXT *iec);

AQBANKING_API 
AB_MESSAGE*
AB_ImExporterContext_GetNextMessage(AB_IMEXPORTER_CONTEXT *iec);

/**@}*/

/** @defgroup AB_IMEXPORTER_CONTEXT_LOGS Logs
 *
 * These functions handle logs written by the backends.
 * Such logs are meant to be read and interpreted by a human user.
 */
/**@{*/

AQBANKING_API
void AB_ImExporterContext_AddLog(AB_IMEXPORTER_CONTEXT *iec,
				 const char *s);

AQBANKING_API
const char *AB_ImExporterContext_GetLog(const AB_IMEXPORTER_CONTEXT *iec);

AQBANKING_API
void AB_ImExporterContext_ClearLog(AB_IMEXPORTER_CONTEXT *iec);

/**@}*/

/*@}*/ /* defgroup */




/** @defgroup AB_IMEXPORTER_ACCOUNTINFO Im- and Exporter Account Info
 * @ingroup G_AB_IMEXPORTER
 *
 * Such a structure contains the list of imported/to be exported transactions
 * for a given account.
 */
/*@{*/

/** @name Constructor, Destructor, Copy
 *
 */
/*@{*/
AQBANKING_API
AB_IMEXPORTER_ACCOUNTINFO *AB_ImExporterAccountInfo_new();
AQBANKING_API 
void AB_ImExporterAccountInfo_free(AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
void AB_ImExporterAccountInfo_FillFromAccount(AB_IMEXPORTER_ACCOUNTINFO *iea,
					      const AB_ACCOUNT *a);

/**
 * Returns a copy of the given account info. Please note that only the data
 * is copied, internal pointers for
 * @ref AB_ImExporterAccountInfo_GetNextTransaction et al are reset in the
 * copy.
 */
AQBANKING_API 
  AB_IMEXPORTER_ACCOUNTINFO*
  AB_ImExporterAccountInfo_dup(const AB_IMEXPORTER_ACCOUNTINFO *oldiea);
/*@}*/


/** @name Informational Functions
 *
 */
/*@{*/
/**
 * Bank code of the institute the account is at.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetBankCode(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetBankCode(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                          const char *s);

/**
 * Bank name of the institute the account is at.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetBankName(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetBankName(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                          const char *s);

/**
 * Account number.
 * Used when importing data, not used when exporting.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetAccountNumber(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetAccountNumber(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                               const char *s);

/**
 * Account name.
 * Used when importing data, not used when exporting.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetAccountName(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetAccountName(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                             const char *s);

/**
 * IBAN.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetIban(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetIban(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                      const char *s);


/**
 * BIC.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetBic(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetBic(AB_IMEXPORTER_ACCOUNTINFO *iea,
				     const char *s);

/**
 * Account currency
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetCurrency(const AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
void AB_ImExporterAccountInfo_SetCurrency(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                          const char *s);


/**
 * Name of the account' owner.
 * Used when importing data, not used when exporting.
 */
AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetOwner(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetOwner(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                       const char *s);

AQBANKING_API 
AB_ACCOUNT_TYPE
  AB_ImExporterAccountInfo_GetType(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetType(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                      AB_ACCOUNT_TYPE t);

AQBANKING_API 
const char*
AB_ImExporterAccountInfo_GetDescription(const AB_IMEXPORTER_ACCOUNTINFO *iea);
AQBANKING_API 
void AB_ImExporterAccountInfo_SetDescription(AB_IMEXPORTER_ACCOUNTINFO *iea,
					     const char *s);

/**
 * This field is not used by AqBanking but might be used by applications.
 */
AQBANKING_API 
uint32_t AB_ImExporterAccountInfo_GetAccountId(const AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
void AB_ImExporterAccountInfo_SetAccountId(AB_IMEXPORTER_ACCOUNTINFO *iea, uint32_t id);

/*@}*/



/** @name Transactions
 *
 */
/*@{*/
/**
 * Takes over ownership of the given transaction.
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_AddTransaction(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                             AB_TRANSACTION *t);
/**
 * Returns the first transaction stored within the context.
 * The context remains the owner of the object returned.
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetFirstTransaction(AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * Returns the next transaction stored within the context.
 * The context remains the owner of the object returned.
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetNextTransaction(AB_IMEXPORTER_ACCOUNTINFO *iea);

/** Callback function type for
 * AB_ImExporterAccountInfo_TransactionsForEach()
 *
 * (As soon as transaction.h declares this type itself, this
 * declaration can be removed. Currently transaction.h only
 * declares the LIST2 but not the CONSTLIST2, so we add this
 * declaration here. If transaction.h declares the CONSTLIST2 as
 * well, it wouldn't harm because this typedef is exactly
 * identical to the one from the GWEN_CONSTLIST2_FUNCTION_LIB_DEFS
 * macro.)  */
typedef const AB_TRANSACTION *
(AB_TRANSACTION_CONSTLIST2_FOREACH)(const AB_TRANSACTION *element,
				    void *user_data);

/** Traverses the list of Transactions in this AccountInfo,
 * calling the callback function 'func' on each list element.
 * Traversal will stop when 'func' returns a non-NULL value, and
 * the routine will return with that value. Otherwise the routine
 * will return NULL.
 *
 * Note: It is not totally clear to me whether this function might
 * interfere with AB_ImExporterAccountInfo_GetFirstTransaction() /
 * AB_ImExporterAccountInfo_GetNextTransaction() . To be on the
 * safe side, you should probably traverse the transaction list
 * only *either* by those mentioned two functions *or* by this
 * ForEach function, but you should probably not mix the access
 * through this two methods. (This doubt be changed in future
 * versions.)
 *
 * Available since aqbanking-1.9.7.
 *
 * @param list The list to traverse.
 * @param func The function to be called with each list element.
 * @param user_data A pointer passed on to the function 'func'.
 * @return The non-NULL pointer returned by 'func' as soon as it
 * returns one. Otherwise (i.e. 'func' always returns NULL)
 * returns NULL.
 */
AQBANKING_API
const AB_TRANSACTION*
AB_ImExporterAccountInfo_TransactionsForEach(AB_IMEXPORTER_ACCOUNTINFO *iea,
					     AB_TRANSACTION_CONSTLIST2_FOREACH func,
					     void* user_data);

AQBANKING_API
int AB_ImExporterAccountInfo_GetTransactionCount(const AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * Clear all transactions stored in the given account info.
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_ClearTransactions(AB_IMEXPORTER_ACCOUNTINFO *iea);

/*@}*/


/** @name Account Status
 *
 */
/*@{*/
/**
 * Takes over ownership of the given account status.
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_AddAccountStatus(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                               AB_ACCOUNT_STATUS *st);

/**
 * Returns the first account status stored within the context and removes
 * it.
 * The context remains the owner of the object returned.
 */
AQBANKING_API 
AB_ACCOUNT_STATUS*
AB_ImExporterAccountInfo_GetFirstAccountStatus(AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * Returns the next account status stored within the context and removes it
 * The context remains the owner of the object returned.
 */
AQBANKING_API 
AB_ACCOUNT_STATUS*
AB_ImExporterAccountInfo_GetNextAccountStatus(AB_IMEXPORTER_ACCOUNTINFO *iea);
/*@}*/


/** @name Standing Orders
 *
 */
/*@{*/

/**
 * <p>
 * Takes over ownership of the given standing order.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_AddStandingOrder(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                               AB_TRANSACTION *t);
/**
 * <p>
 * Returns the first standing order stored within the context.
 * The context remains the owner of the object returned.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetFirstStandingOrder(AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * <p>
 * Returns the next standing order stored within the context.
 * The context remains the owner of the object returned.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetNextStandingOrder(AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
int AB_ImExporterAccountInfo_GetStandingOrderCount(const AB_IMEXPORTER_ACCOUNTINFO *iea);

/*@}*/


/** @name Transfers
 *
 */
/*@{*/
/**
 * <p>
 * Takes over ownership of the given transfer.
 * </p>
 * <p>
 * The transfer can be any kind of transfer (like single transfer,
 * debit note, EU transfer etc).
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_AddTransfer(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                          AB_TRANSACTION *t);
/**
 * <p>
 * Returns the first transfer stored within the context.
 * The context remains the owner of the object returned.
 * The transfer can be any kind of transfer (like single transfer,
 * debit note, EU transfer etc).
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetFirstTransfer(AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * <p>
 * Returns the next transfer stored within the context.
 * The context remains the owner of the object returned.
 * The transfer can be any kind of transfer (like single transfer,
 * debit note, EU transfer etc).
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetNextTransfer(AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
int AB_ImExporterAccountInfo_GetTransferCount(const AB_IMEXPORTER_ACCOUNTINFO *iea);

/*@}*/



/** @name Dated Transfers
 *
 */
/*@{*/
/**
 * <p>
 * Takes over ownership of the given dated transfer.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_AddDatedTransfer(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                               AB_TRANSACTION *t);
/**
 * <p>
 * Returns the first dated transfer stored within the context.
 * The context remains the owner of the object returned.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetFirstDatedTransfer(AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * <p>
 * Returns the next dated transfer stored within the context.
 * The context remains the owner of the object returned.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetNextDatedTransfer(AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
int AB_ImExporterAccountInfo_GetDatedTransferCount(const AB_IMEXPORTER_ACCOUNTINFO *iea);

/*@}*/


/** @name Noted Transactions
 *
 */
/*@{*/
/**
 * <p>
 * Takes over ownership of the given noted transfer.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
void AB_ImExporterAccountInfo_AddNotedTransaction(AB_IMEXPORTER_ACCOUNTINFO *iea,
                                                  AB_TRANSACTION *t);
/**
 * <p>
 * Returns the first noted transfer stored within the context.
 * The context remains the owner of the object returned.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetFirstNotedTransaction(AB_IMEXPORTER_ACCOUNTINFO *iea);

/**
 * <p>
 * Returns the next noted transfer stored within the context.
 * The context remains the owner of the object returned.
 * </p>
 * <p>
 * This function is only used in the context of the function
 * @ref AB_Banking_GatherResponses. It is especially not used when
 * importing or exporting normal transactions via
 * @ref AB_ImExporter_Import or @ref AB_ImExporter_Export unless explicitly
 * stated otherwise (see documentation of the importer/exporter in question).
 * </p>
 */
AQBANKING_API 
AB_TRANSACTION*
AB_ImExporterAccountInfo_GetNextNotedTransaction(AB_IMEXPORTER_ACCOUNTINFO *iea);

AQBANKING_API 
int AB_ImExporterAccountInfo_GetNotedTransactionCount(const AB_IMEXPORTER_ACCOUNTINFO *iea);

/*@}*/



/*@}*/ /* defgroup */


/** @name Helper Functions
 *
 * These functions are most likely used by implementations of im/exporters.
 */
/*@{*/
/**
 * Transforms an UTF-8 string to a DTA string. Untranslateable characters
 * are replaced by a space (chr 32).
 */
AQBANKING_API
void AB_ImExporter_Utf8ToDta(const char *p, int size, GWEN_BUFFER *buf);

/**
 * Transforms a DTA string to an UTF-8 string.
 */
AQBANKING_API 
void AB_ImExporter_DtaToUtf8(const char *p, int size, GWEN_BUFFER *buf);

AQBANKING_API 
void AB_ImExporter_Iso8859_1ToUtf8(const char *p,
                                   int size,
                                   GWEN_BUFFER *buf);

AQBANKING_DEPRECATED AQBANKING_API
int AH_ImExporter_DbFromIso8859_1ToUtf8(GWEN_DB_NODE *db);

/**
 * This function call @ref AB_ImExporter_Iso8859_1ToUtf8 on all char
 * values in the given db.
 */
AQBANKING_API 
int AB_ImExporter_DbFromIso8859_1ToUtf8(GWEN_DB_NODE *db);

AQBANKING_API 
GWEN_TIME *AB_ImExporter_DateFromString(const char *p,
                                        const char *tmpl,
                                        int inUtc);


/*@}*/



#ifdef __cplusplus
}
#endif




#endif /* AQBANKING_IMEXPORTER_H */


