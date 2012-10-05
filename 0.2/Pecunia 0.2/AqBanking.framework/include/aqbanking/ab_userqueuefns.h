/***************************************************************************
    begin       : Mon May 10 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef AQBANKING_USERQUEUEFNS_H
#define AQBANKING_USERQUEUEFNS_H



AQBANKING_API AB_ACCOUNTQUEUE *AB_UserQueue_FindAccountQueue(const AB_USERQUEUE *uq, AB_ACCOUNT *acc);
AQBANKING_API void AB_UserQueue_AddJob(AB_USERQUEUE *uq, AB_JOB *j);





#endif




