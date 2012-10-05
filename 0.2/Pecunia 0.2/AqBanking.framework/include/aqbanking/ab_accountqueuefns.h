/***************************************************************************
    begin       : Mon May 10 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef AQBANKING_ACCOUNTQUEUEFNS_H
#define AQBANKING_ACCOUNTQUEUEFNS_H



AQBANKING_API AB_JOBQUEUE *AB_AccountQueue_FindJobQueue(const AB_ACCOUNTQUEUE *aq, AB_JOB_TYPE jt);
AQBANKING_API void AB_AccountQueue_AddJob(AB_ACCOUNTQUEUE *aq, AB_JOB *j);





#endif




