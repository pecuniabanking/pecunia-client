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


#ifndef AQBANKING_JOBMODIFYSTO_BE_H
#define AQBANKING_JOBMODIFYSTO_BE_H


#include <aqbanking/jobmodifysto.h>


/** @addtogroup G_AB_JOBS_STO_MOD
 *
 */
/*@{*/

/** @name Backend Functions
 *
 * Functions in this group are only to be called by banking backends.
 */
/*@{*/

/**
 * This function lets the backend specify the limits for some of the fields
 * of a @ref AB_TRANSACTION.
 */
AQBANKING_API
void AB_JobModifyStandingOrder_SetFieldLimits(AB_JOB *j,
                                              AB_TRANSACTION_LIMITS *limits);
/*@}*/ 


/*@}*/ /* addtogroup */


#endif

