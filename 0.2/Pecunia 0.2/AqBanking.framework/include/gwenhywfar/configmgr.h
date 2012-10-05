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


#ifndef GWENHYWFAR_CONFIGMGR_H
#define GWENHYWFAR_CONFIGMGR_H

#include <gwenhywfar/inherit.h>

#ifdef __cplusplus
extern "C" {
#endif


typedef struct GWEN_CONFIGMGR GWEN_CONFIGMGR;
GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_CONFIGMGR, GWENHYWFAR_API)

#define GWEN_CONFIGMGR_PLUGIN_NAME "configmgr"
#define GWEN_CONFIGMGR_FOLDER      "configmgr"


#include <gwenhywfar/db.h>
#include <gwenhywfar/stringlist.h>



/**
 * Creates a GWEN_CONFIGMGR object. The given URL is inspected for the protocol part
 * which is used to lookup the plugin responsible.
 * A generic file based configuration manager might have the URL
 * "dir://home/martin/testconfig" which means that all files of the configuration
 * manager reside below the folder "/home/martin/testconfig".
 * Other plugins might have another URL scheme, however, the protocol part always
 * specifies the plugin (in this case "dir").
 */
GWENHYWFAR_API
GWEN_CONFIGMGR *GWEN_ConfigMgr_Factory(const char *url);

GWENHYWFAR_API
void GWEN_ConfigMgr_free(GWEN_CONFIGMGR *mgr);

GWENHYWFAR_API
int GWEN_ConfigMgr_GetGroup(GWEN_CONFIGMGR *mgr,
			    const char *groupName,
			    const char *subGroupName,
			    GWEN_DB_NODE **pDb);

GWENHYWFAR_API
int GWEN_ConfigMgr_SetGroup(GWEN_CONFIGMGR *mgr,
			    const char *groupName,
			    const char *subGroupName,
			    GWEN_DB_NODE *db);

GWENHYWFAR_API
int GWEN_ConfigMgr_LockGroup(GWEN_CONFIGMGR *mgr,
			     const char *groupName,
			     const char *subGroupName);

GWENHYWFAR_API
int GWEN_ConfigMgr_UnlockGroup(GWEN_CONFIGMGR *mgr,
			       const char *groupName,
			       const char *subGroupName);

GWENHYWFAR_API
int GWEN_ConfigMgr_GetUniqueId(GWEN_CONFIGMGR *mgr,
			       const char *groupName,
			       char *buffer,
			       uint32_t bufferLen);

GWENHYWFAR_API
int GWEN_ConfigMgr_DeleteGroup(GWEN_CONFIGMGR *mgr,
			       const char *groupName,
			       const char *subGroupName);


GWENHYWFAR_API
int GWEN_ConfigMgr_ListGroups(GWEN_CONFIGMGR *mgr,
			      GWEN_STRINGLIST *sl);

GWENHYWFAR_API
int GWEN_ConfigMgr_ListSubGroups(GWEN_CONFIGMGR *mgr,
				 const char *groupName,
				 GWEN_STRINGLIST *sl);


#ifdef __cplusplus
}
#endif


#endif

