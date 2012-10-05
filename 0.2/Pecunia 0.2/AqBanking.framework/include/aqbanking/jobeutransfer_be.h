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


#ifndef AQBANKING_JOBEUTRANSFER_BE_H
#define AQBANKING_JOBEUTRANSFER_BE_H


#include <aqbanking/job.h>
#include <aqbanking/jobeutransfer.h>


/** @addtogroup G_AB_JOBS_XFER_EU
 *
 */
/*@{*/

/** @name Backend Functions
 *
 * Functions in this group are only to be called by banking backends.
 */
/*@{*/

/**
 * Set the country info list (containing information about valid destination
 * countries and transfer limits per country).
 * This function takes over the given list and all its members.
 */
AQBANKING_API 
void AB_JobEuTransfer_SetCountryInfoList(AB_JOB *j,
                                         AB_EUTRANSFER_INFO_LIST *l);

/**
 * Tell AqBanking whether it is allowed to specify the IBAN for the
 * destination account.
 */
AQBANKING_API 
void AB_JobEuTransfer_SetIbanAllowed(AB_JOB *j, int b);
/*@}*/ 


/*@}*/ /* addtogroup */


#endif

