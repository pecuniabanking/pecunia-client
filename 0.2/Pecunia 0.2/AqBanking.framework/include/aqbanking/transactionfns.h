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



#ifndef AQBANKING_TRANSACTIONFNS_H
#define AQBANKING_TRANSACTIONFNS_H

#include <aqbanking/transaction.h>
#include <aqbanking/account.h>

#ifdef __cplusplus
extern "C" {
#endif


/**
 * @return 0 if both transactions are equal, 1 otherwise (and -1 on error)
 */
AQBANKING_API 
int AB_Transaction_Compare(const AB_TRANSACTION *t1,
                           const AB_TRANSACTION *t0);

/**
 * Fills "local account" parts of the given transaction with the data
 * from the given account. In particular, the following fields are set
 * through this function: SetLocalCountry, SetRemoteCountry,
 * SetLocalBankCode, SetLocalAccountNumber, and SetLocalName.
 */
AQBANKING_API
void AB_Transaction_FillLocalFromAccount(AB_TRANSACTION *t, const AB_ACCOUNT *a);


#ifdef __cplusplus
} /* __cplusplus */
#endif


#endif /* AQBANKING_TRANSACTIONFNS_H */
