/***************************************************************************
 begin       : Sun Sep 21 2008
 copyright   : (C) 2008 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AQBANKING_JOBSEPADEBITNOTE_H
#define AQBANKING_JOBSEPADEBITNOTE_H


#include <aqbanking/job.h>
#include <aqbanking/transaction.h>
#include <aqbanking/transactionlimits.h>

/** @addtogroup G_AB_JOBS_XFER_SEPA_DEBITNOTE
 *
 * This is a SEPA debitnote.
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif


AQBANKING_API 
AB_JOB *AB_JobSepaDebitNote_new(AB_ACCOUNT *a);


/** @name Arguments
 *
 *
 */
/*@{*/
/**
 * This function sets the debitnote to be performed.
 * Please note that the backend might later replace the transaction given
 * here with a validated version (upon execution of the job).
 * So if you want to be sure that you have the recent version of the
 * transaction you should call @ref AB_JobSepaDebitNote_GetTransaction.
 */
AQBANKING_API 
int AB_JobSepaDebitNote_SetTransaction(AB_JOB *j, const AB_TRANSACTION *t);

/**
 * Returns the currently stored transaction for this job. After the job has
 * been executed by the backend the transaction returned will very likely
 * be a pointer to the validated replacement for the initially given
 * transaction.
 */
AQBANKING_API 
const AB_TRANSACTION *AB_JobSepaDebitNote_GetTransaction(const AB_JOB *j);
/*@}*/


/** @name Parameters
 *
 * The functions in this group are only available after the function
 * @ref AB_Job_CheckAvailability has been called and only if that call flagged
 * success (i.e. that the job is available).
 */
/*@{*/

/**
 * Returns the transaction field limits for this job.
 */
AQBANKING_API 
const AB_TRANSACTION_LIMITS *AB_JobSepaDebitNote_GetFieldLimits(AB_JOB *j);
/*@}*/


#ifdef __cplusplus
}
#endif

/*@}*/ /* defgroup */

#endif

