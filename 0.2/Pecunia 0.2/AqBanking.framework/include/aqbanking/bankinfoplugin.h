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


#ifndef AQBANKING_BANKINFOPLUGIN_H
#define AQBANKING_BANKINFOPLUGIN_H

#include <aqbanking/bankinfo.h>


typedef enum {
  AB_BankInfoCheckResult_Ok=0,
  AB_BankInfoCheckResult_NotOk,
  AB_BankInfoCheckResult_UnknownBank,
  AB_BankInfoCheckResult_UnknownResult
} AB_BANKINFO_CHECKRESULT;




#endif /* AQBANKING_BANKINFOPLUGIN_H */

