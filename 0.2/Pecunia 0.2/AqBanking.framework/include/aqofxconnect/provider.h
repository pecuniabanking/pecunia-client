/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/

#ifndef AO_PROVIDER_H
#define AO_PROVIDER_H

#include <aqofxconnect/aqofxconnect.h>
#include <aqbanking/banking_be.h>
#include <aqbanking/provider_be.h>

#define AQOFXCONNECT_BACKENDNAME "aqofxconnect"

#define AQOFXCONNECT_LOGDOMAIN "aqofxconnect"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AO_PROVIDER AO_PROVIDER;


AQOFXCONNECT_API AB_PROVIDER *AO_Provider_new(AB_BANKING *ab);

AQOFXCONNECT_API int AO_Provider_RequestAccounts(AB_PROVIDER *pro,
						 AB_USER *u,
						 uint32_t guiid);

#ifdef __cplusplus
}
#endif


#endif

