/***************************************************************************
 begin       : Mon Aug 11 2008
 copyright   : (C) 2008 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *                                                                         *
 *   This library is free software; you can redistribute it and/or         *
 *   modify it under the terms of the GNU Lesser General Public            *
 *   License as published by the Free Software Foundation; either          *
 *   version 2.1 of the License, or (at your option) any later version.    *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston,                 *
 *   MA  02111-1307  USA                                                   *
 *                                                                         *
 ***************************************************************************/


#ifndef GWENHYWFAR_CONFIGMGR_BE_H
#define GWENHYWFAR_CONFIGMGR_BE_H


#include <gwenhywfar/configmgr.h>
#include <gwenhywfar/plugin.h>



GWENHYWFAR_API
GWEN_CONFIGMGR *GWEN_ConfigMgr_new(const char *url);


typedef int (*GWEN_CONFIGMGR_GETGROUP_FN)(GWEN_CONFIGMGR *mgr,
					  const char *groupName,
					  const char *subGroupName,
					  GWEN_DB_NODE **pDb);

typedef int (*GWEN_CONFIGMGR_SETGROUP_FN)(GWEN_CONFIGMGR *mgr,
					  const char *groupName,
					  const char *subGroupName,
					  GWEN_DB_NODE *db);

typedef int (*GWEN_CONFIGMGR_LOCKGROUP_FN)(GWEN_CONFIGMGR *mgr,
					   const char *groupName,
					   const char *subGroupName);

typedef int (*GWEN_CONFIGMGR_UNLOCKGROUP_FN)(GWEN_CONFIGMGR *mgr,
					     const char *groupName,
					     const char *subGroupName);

typedef int (*GWEN_CONFIGMGR_GETUNIQUEID_FN)(GWEN_CONFIGMGR *mgr,
					     const char *groupName,
					     char *buffer,
					     uint32_t bufferLen);

typedef int (*GWEN_CONFIGMGR_DELETEGROUP_FN)(GWEN_CONFIGMGR *mgr,
					     const char *groupName,
					     const char *subGroupName);

typedef int (*GWEN_CONFIGMGR_LISTGROUPS_FN)(GWEN_CONFIGMGR *mgr,
					    GWEN_STRINGLIST *sl);

typedef int (*GWEN_CONFIGMGR_LISTSUBGROUPS_FN)(GWEN_CONFIGMGR *mgr,
					       const char *groupName,
					       GWEN_STRINGLIST *sl);



GWENHYWFAR_API
GWEN_CONFIGMGR_GETGROUP_FN GWEN_ConfigMgr_SetGetGroupFn(GWEN_CONFIGMGR *mgr,
							GWEN_CONFIGMGR_GETGROUP_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_SETGROUP_FN GWEN_ConfigMgr_SetSetGroupFn(GWEN_CONFIGMGR *mgr,
							GWEN_CONFIGMGR_SETGROUP_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_LOCKGROUP_FN GWEN_ConfigMgr_SetLockGroupFn(GWEN_CONFIGMGR *mgr,
							  GWEN_CONFIGMGR_LOCKGROUP_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_UNLOCKGROUP_FN GWEN_ConfigMgr_SetUnlockGroupFn(GWEN_CONFIGMGR *mgr,
                                                              GWEN_CONFIGMGR_UNLOCKGROUP_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_GETUNIQUEID_FN GWEN_ConfigMgr_SetGetUniqueIdFn(GWEN_CONFIGMGR *mgr,
							      GWEN_CONFIGMGR_GETUNIQUEID_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_DELETEGROUP_FN GWEN_ConfigMgr_SetDeleteGroupFn(GWEN_CONFIGMGR *mgr,
                                                              GWEN_CONFIGMGR_DELETEGROUP_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_LISTGROUPS_FN GWEN_ConfigMgr_SetListGroupsFn(GWEN_CONFIGMGR *mgr,
							    GWEN_CONFIGMGR_LISTGROUPS_FN f);

GWENHYWFAR_API
GWEN_CONFIGMGR_LISTSUBGROUPS_FN GWEN_ConfigMgr_SetListSubGroupsFn(GWEN_CONFIGMGR *mgr,
								  GWEN_CONFIGMGR_LISTSUBGROUPS_FN f);





typedef GWEN_CONFIGMGR* (*GWEN_CONFIGMGR_PLUGIN_FACTORYFN)(GWEN_PLUGIN *pl,
							   const char *url);

GWENHYWFAR_API
GWEN_PLUGIN *GWEN_ConfigMgr_Plugin_new(GWEN_PLUGIN_MANAGER *pm,
				       const char *name,
				       const char *fileName);

GWENHYWFAR_API
void GWEN_ConfigMgr_Plugin_SetFactoryFn(GWEN_PLUGIN *pl,
					GWEN_CONFIGMGR_PLUGIN_FACTORYFN f);



#endif

