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


#ifndef AQBANKING_JOBGETSTANDINGORDERS_H
#define AQBANKING_JOBGETSTANDINGORDERS_H


#include <aqbanking/job.h>
#include <aqbanking/transaction.h>

/** @addtogroup G_AB_JOBS_STO_GET
 *
 */
/*@{*/

#ifdef __cplusplus
extern "C" {
#endif


/**
 * Creates a job which retrieves a list of currently active standing orders
 * for the given account.
 * @param a account for which you want the standing orders
 */
AQBANKING_API
AB_JOB *AB_JobGetStandingOrders_new(AB_ACCOUNT *a);

/** @deprecated */
AQBANKING_API AQBANKING_DEPRECATED
AB_TRANSACTION_LIST2*
  AB_JobGetStandingOrders_GetStandingOrders(const AB_JOB *j);



#ifdef __cplusplus
}
#endif

/*@}*/

#endif /* AQBANKING_JOBGETSTANDINGORDERS_H */

