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


#ifndef AQBANKING_JOBGETBALANCE_H
#define AQBANKING_JOBGETBALANCE_H


#include <aqbanking/job.h>
#include <aqbanking/accstatus.h>

/** @addtogroup G_AB_JOBS_GETBALANCE
 *
 */
/*@{*/

#ifdef __cplusplus
extern "C" {
#endif

/** @name Constructor */
/*@{*/
AQBANKING_API
AB_JOB *AB_JobGetBalance_new(AB_ACCOUNT *a);
/*@}*/


/** @deprecated */
AQBANKING_API AQBANKING_DEPRECATED
const AB_ACCOUNT_STATUS *AB_JobGetBalance_GetAccountStatus(AB_JOB *j);

#ifdef __cplusplus
}
#endif

/*@}*/ /* addtogroup */


#endif /* AQBANKING_JOBGETBALANCE_H */

