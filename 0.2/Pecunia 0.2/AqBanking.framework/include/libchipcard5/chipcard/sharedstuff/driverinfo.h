/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/



#ifndef CHIPCARD_COMMON_DRIVERINFO_H
#define CHIPCARD_COMMON_DRIVERINFO_H

#include <chipcard/chipcard.h>

#include <gwenhywfar/db.h>

CHIPCARD_API 
int LC_DriverInfo_ReadDrivers(const char *dataDir,
                              GWEN_DB_NODE *dbDrivers,
			      int availOnly,
			      int dontSearchDrivers);


#endif
