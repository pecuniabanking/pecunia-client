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


#ifndef AQBANKING_JOBINTERNALTRANSFER_H
#define AQBANKING_JOBINTERNALTRANSFER_H


#include <aqbanking/job.h>
#include <aqbanking/transaction.h>
#include <aqbanking/transactionlimits.h>


/** @addtogroup G_AB_JOBS_XFER_INTERNAL
 *
 * An internal transfer is a transfer between two accounts of the same
 * customer at the same bank. Some banks only allow to use this job for
 * this kind of transfer while others only allow normal transfers (as
 * described in @ref G_AB_JOBS_XFER_TRANSFER).
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif


AQBANKING_API
AB_JOB *AB_JobInternalTransfer_new(AB_ACCOUNT *a);


/** @name Arguments
 *
 *
 */
/*@{*/
/**
 * This function sets the transfer to be performed.
 * Please note that the backend might later replace the transaction given
 * here with a validated version (upon execution of the job).
 * So if you want to be sure that you have the recent version of the
 * transaction you should call @ref AB_JobInternalTransfer_GetTransaction.
 * This transaction MUST NOT contain splits.
 */
AQBANKING_API 
int AB_JobInternalTransfer_SetTransaction(AB_JOB *j, const AB_TRANSACTION *t);

/**
 * Returns the currently stored transaction for this job. After the job has
 * been executed by the backend the transaction returned will very likely
 * be a pointer to the validated replacement for the initially given
 * transaction.
 */
AQBANKING_API 
const AB_TRANSACTION *AB_JobInternalTransfer_GetTransaction(const AB_JOB *j);
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
const AB_TRANSACTION_LIMITS *AB_JobInternalTransfer_GetFieldLimits(AB_JOB *j);

/*@}*/


#ifdef __cplusplus
}
#endif

/*@}*/ /* defgroup */


#endif

