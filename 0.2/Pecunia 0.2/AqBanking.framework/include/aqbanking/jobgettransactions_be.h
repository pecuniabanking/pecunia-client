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


#ifndef AQBANKING_JOBGETTRANSACTIONS_BE_H
#define AQBANKING_JOBGETTRANSACTIONS_BE_H


#include <aqbanking/job.h>
#include <aqbanking/jobgettransactions.h>


#ifdef __cplusplus
extern "C" {
#endif


AQBANKING_API 
void AB_JobGetTransactions_SetMaxStoreDays(AB_JOB *j, int i);



#ifdef __cplusplus
}
#endif


#endif /* AQBANKING_JOBGETTRANSACTIONS_BE_H */

