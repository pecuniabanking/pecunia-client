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


#ifndef AQBANKING_JOBGETTRANSACTIONS_H
#define AQBANKING_JOBGETTRANSACTIONS_H


#include <aqbanking/job.h>
#include <aqbanking/transaction.h>
#include <aqbanking/accstatus.h>


/** @addtogroup G_AB_JOBS_GETTRANSACTIONS
 *
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif


/**
 * Creates a job which retrieves transaction reports for the given timespan
 * (if any).
 * @param a account for which you want the reports
 */
AQBANKING_API
AB_JOB *AB_JobGetTransactions_new(AB_ACCOUNT *a);

/** @deprecated */
AQBANKING_API AQBANKING_DEPRECATED
AB_TRANSACTION_LIST2*
  AB_JobGetTransactions_GetTransactions(const AB_JOB *j);


/** @deprecated */
AQBANKING_API AQBANKING_DEPRECATED
AB_ACCOUNT_STATUS_LIST2*
  AB_JobGetTransactions_GetAccountStatusList(const AB_JOB *j);


/** @name Arguments
 *
 * Possibly arguments for this job are the first date
 * (@ref AB_JobGetTransactions_SetFromTime) and the last date
 * (@ref AB_JobGetTransactions_SetToTime). This is only a hint for the
 * backend. Some backends ignore this date range because their underlying
 * protocol does not specify a way to communicate this date range.
 */
/*@{*/
/**
 * Sets the first date for which you want the reports (the time doesn't
 * matter, only the date component of the given GWEN_TIME is used).
 * If NULL then the first day for which the bank has reports is assumed.
 * @param j job
 * @param t "from" date
 */
AQBANKING_API 
  void AB_JobGetTransactions_SetFromTime(AB_JOB *j, const GWEN_TIME *t);

/**
 * Sets the last date for which you want the reports (the time doesn't
 * matter, only the date component of the given GWEN_TIME is used).
 * If NULL then the last day for which the bank has reports is assumed.
 * @param j job
 * @param t "to" date
 */
AQBANKING_API 
void AB_JobGetTransactions_SetToTime(AB_JOB *j, const GWEN_TIME *t);

AQBANKING_API 
const GWEN_TIME *AB_JobGetTransactions_GetFromTime(const AB_JOB *j);

AQBANKING_API
const GWEN_TIME *AB_JobGetTransactions_GetToTime(const AB_JOB *j);
/*@}*/


/** @name Parameters
 *
 * The functions in this group are only available after the function
 * @ref AB_Job_CheckAvailability has been called and only if that call flagged
 * success (i.e. that the job is available).
 */
/*@{*/
/**
 * Returns the maximum number of days the bank stores your transaction
 * data for the account associated with the given job.
 * @return 0 if unknown, number of days otherwise
 * @param j job
 */
AQBANKING_API 
int AB_JobGetTransactions_GetMaxStoreDays(const AB_JOB *j);
/*@}*/


#ifdef __cplusplus
}
#endif


/*@}*/ /* addtogroup */


#endif /* AQBANKING_JOBGETTRANSACTIONS_H */

