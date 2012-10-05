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


#ifndef AQBANKING_ACCOUNT_BE_H
#define AQBANKING_ACCOUNT_BE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <aqbanking/account.h>


GWEN_LIST_FUNCTION_DEFS(AB_ACCOUNT, AB_Account)


/**
 * Frees a List2 of accounts and all its members.
 * This MUST NOT be used on account lists returned by AqBanking, but only
 * on account lists created by backends.
 * Therefore this function is only defined here.
 */
AQBANKING_API 
void AB_Account_List2_FreeAll(AB_ACCOUNT_LIST2 *al);


#ifdef __cplusplus
}
#endif


#endif

