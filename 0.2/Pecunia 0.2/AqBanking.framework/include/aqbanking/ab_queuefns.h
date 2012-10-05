/***************************************************************************
    begin       : Mon May 10 2010
    copyright   : (C) 2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef AQBANKING_QUEUEFNS_H
#define AQBANKING_QUEUEFNS_H



AQBANKING_API AB_USERQUEUE *AB_Queue_FindUserQueue(const AB_QUEUE *q, AB_USER *u);
AQBANKING_API void AB_Queue_AddJob(AB_QUEUE *q, AB_USER *u, AB_JOB *j);
AQBANKING_API AB_JOB *AB_Queue_FindFirstJobLikeThis(AB_QUEUE *q, AB_USER *u, AB_JOB *bj);





#endif




