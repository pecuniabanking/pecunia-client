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


/** @file job_be.h
 * @short This file is used by provider backends.
 */


#ifndef AQBANKING_JOB_BE_H
#define AQBANKING_JOB_BE_H

#include <aqbanking/job.h>

/** @defgroup G_AB_BE_JOB Online Banking Tasks
 * @ingroup G_AB_BE_INTERFACE
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif

/** @name Functions To Be Used by Backends
 *
 */
/*@{*/
/**
 * This id can be used by a AB_PROVIDER to map AB_Jobs to whatever the
 * provider uses. This id is not used by AB_Banking itself.
 */
AQBANKING_API
uint32_t AB_Job_GetIdForProvider(const AB_JOB *j);

AQBANKING_API
void AB_Job_SetIdForProvider(AB_JOB *j, uint32_t i);

/**
 * Store backend specific data with a job. This data is not specific
 * to an application, it will rather be used with every application (since
 * it doesn't depend on the application but on the backend).
 * @param j pointer to the AB_JOB object
 * @param pro pointer to the backend for which the data is to be returned
 */
AQBANKING_API
GWEN_DB_NODE *AB_Job_GetProviderData(AB_JOB *j, AB_PROVIDER *pro);

AQBANKING_API
void AB_Job_SetResultText(AB_JOB *j, const char *s);

AQBANKING_API
void AB_Job_SetUsedTan(AB_JOB *j, const char *s);

/**
 * This function should only be used when copying logs from a backend-private
 * job object (e.g. AqHBCI internally uses its own job types) to an
 * AqBanking job.
 * @param j job to operate on
 * @param txt the text to log (it is expected to have the same format as
 * logs created via @ref AB_Job_Log).
 */
AQBANKING_API
void AB_Job_LogRaw(AB_JOB *j, const char *txt);

/*@}*/


#ifdef __cplusplus
}
#endif

/*@}*/ /* defgroup */


#endif /* AQBANKING_JOB_BE_H */




