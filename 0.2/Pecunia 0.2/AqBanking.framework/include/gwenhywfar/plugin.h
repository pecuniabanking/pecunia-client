/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Fri Sep 12 2003
    copyright   : (C) 2003 by Martin Preuss
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


#ifndef GWENHYWFAR_PLUGIN_H
#define GWENHYWFAR_PLUGIN_H

#include <gwenhywfar/inherit.h>
#include <gwenhywfar/misc.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_PLUGIN GWEN_PLUGIN;
typedef struct GWEN_PLUGIN_MANAGER GWEN_PLUGIN_MANAGER;

GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_PLUGIN, GWENHYWFAR_API)
GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_PLUGIN_MANAGER, GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif

#include <gwenhywfar/error.h>
#include <gwenhywfar/libloader.h>
#include <gwenhywfar/plugindescr.h>
#include <gwenhywfar/stringlist.h>
#include <gwenhywfar/pathmanager.h>

#ifdef __cplusplus
extern "C" {
#endif




typedef GWEN_PLUGIN* (*GWEN_PLUGIN_FACTORYFN)(GWEN_PLUGIN_MANAGER *pm,
                                              const char *name,
                                              const char *fileName);


GWENHYWFAR_API
GWEN_PLUGIN *GWEN_Plugin_new(GWEN_PLUGIN_MANAGER *pm,
                             const char *name,
                             const char *fileName);

GWENHYWFAR_API
void GWEN_Plugin_free(GWEN_PLUGIN *p);

GWENHYWFAR_API
GWEN_PLUGIN_MANAGER *GWEN_Plugin_GetManager(const GWEN_PLUGIN *p);

GWENHYWFAR_API
const char *GWEN_Plugin_GetName(const GWEN_PLUGIN *p);

GWENHYWFAR_API
const char *GWEN_Plugin_GetFileName(const GWEN_PLUGIN *p);

GWENHYWFAR_API
GWEN_LIBLOADER *GWEN_Plugin_GetLibLoader(const GWEN_PLUGIN *p);






/**
 * @param destLib The name of the library that this plugin is supposed to
 * belong to.
 */
GWENHYWFAR_API
GWEN_PLUGIN_MANAGER *GWEN_PluginManager_new(const char *name,
					    const char *destLib);

GWENHYWFAR_API
void GWEN_PluginManager_free(GWEN_PLUGIN_MANAGER *pm);


GWENHYWFAR_API
const char *GWEN_PluginManager_GetName(const GWEN_PLUGIN_MANAGER *pm);

/** Add a directory path to lookup plugins from.
 * The plugin manager must already be registered with Gwen (using
 * @ref GWEN_PluginManager_Register) otherwise the path can not be
 * added
 */
GWENHYWFAR_API
int GWEN_PluginManager_AddPath(GWEN_PLUGIN_MANAGER *pm,
			       const char *callingLib,
			       const char *path);

GWENHYWFAR_API
int GWEN_PluginManager_AddRelPath(GWEN_PLUGIN_MANAGER *pm,
				  const char *callingLib,
				  const char *relpath,
				  GWEN_PATHMANAGER_RELMODE rm);

/** Insert a directory path to lookup plugins from.
 * The plugin manager must already be registered with Gwen (using
 * @ref GWEN_PluginManager_Register) otherwise the path can not be
 * added.
 */
GWENHYWFAR_API
int GWEN_PluginManager_InsertPath(GWEN_PLUGIN_MANAGER *pm,
				  const char *callingLib,
				  const char *path);

GWENHYWFAR_API
int GWEN_PluginManager_RemovePath(GWEN_PLUGIN_MANAGER *pm,
				  const char *callingLib,
				  const char *path);

/** Add a directory path from the windows registry HKEY_LOCAL_MACHINE,
 * to lookup plugins from. On Non-Windows systems, this function does
 * nothing and returns zero.
 *
 * Note: Gwenhywfar-2.6.0 and older used to lookup the paths under
 * HKEY_CURRENT_USER, but with gwen-2.6.1 this was changed to
 * HKEY_LOCAL_MACHINE because we're talking about installation paths
 * as opposed to per-user configuration settings.
 *
 * The plugin manager must already be registered with Gwen (using
 * @ref GWEN_PluginManager_Register) otherwise the path can not be
 * added.
 *
 * @return Zero on success, and non-zero on error.
 *
 * @param pm The PluginManager
 *
 * @param keypath The path to the registry key,
 * e.g. "Software\\MySoftware\\Whatever"
 *
 * @param varname The key name (variable name?) inside the given
 * registry key, e.g. "myvariable".
*/
GWENHYWFAR_API
int GWEN_PluginManager_AddPathFromWinReg(GWEN_PLUGIN_MANAGER *pm,
					 const char *callingLib,
					 const char *keypath,
					 const char *varname);

/** Returns the list of all search paths of the given
 * PluginManager. */
GWENHYWFAR_API 
GWEN_STRINGLIST *GWEN_PluginManager_GetPaths(const GWEN_PLUGIN_MANAGER *pm);

GWENHYWFAR_API
GWEN_PLUGIN *GWEN_PluginManager_LoadPlugin(GWEN_PLUGIN_MANAGER *pm,
                                           const char *modName);

GWENHYWFAR_API
GWEN_PLUGIN *GWEN_PluginManager_LoadPluginFile(GWEN_PLUGIN_MANAGER *pm,
					       const char *modName,
					       const char *fname);


GWENHYWFAR_API
GWEN_PLUGIN *GWEN_PluginManager_GetPlugin(GWEN_PLUGIN_MANAGER *pm,
                                          const char *s);

/**
 * Add a plugin to this plugin manager. Normally plugins are loaded upon
 * @ref GWEN_PluginManager_GetPlugin. This function allows for plugins
 * that are created by other means (e.g. by static linking)
 */
GWENHYWFAR_API
void GWEN_PluginManager_AddPlugin(GWEN_PLUGIN_MANAGER *pm, GWEN_PLUGIN *p);


GWENHYWFAR_API
int GWEN_PluginManager_Register(GWEN_PLUGIN_MANAGER *pm);

GWENHYWFAR_API
int GWEN_PluginManager_Unregister(GWEN_PLUGIN_MANAGER *pm);

GWENHYWFAR_API
GWEN_PLUGIN_MANAGER *GWEN_PluginManager_FindPluginManager(const char *s);


GWENHYWFAR_API
GWEN_PLUGIN_DESCRIPTION_LIST2*
GWEN_PluginManager_GetPluginDescrs(GWEN_PLUGIN_MANAGER *pm);


GWENHYWFAR_API
GWEN_PLUGIN_DESCRIPTION*
GWEN_PluginManager_GetPluginDescr(GWEN_PLUGIN_MANAGER *pm,
                                  const char *modName);


#ifdef __cplusplus
}
#endif

#endif


