/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/



#ifndef AQBANKING_USERFNS_H
#define AQBANKING_USERFNS_H

#include <aqbanking/user.h>


#ifdef __cplusplus
extern "C" {
#endif


AQBANKING_API
AB_PROVIDER *AB_User_GetProvider(const AB_USER *u);


#ifdef __cplusplus
} /* __cplusplus */
#endif


#endif /* AQBANKING_USERFNS_H */
