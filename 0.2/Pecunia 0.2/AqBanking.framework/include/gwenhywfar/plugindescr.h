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


#ifndef GWENHYWFAR_PLUGINDESCR_H
#define GWENHYWFAR_PLUGINDESCR_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/misc.h>
#include <gwenhywfar/misc2.h>
#include <gwenhywfar/xml.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_PLUGIN_DESCRIPTION GWEN_PLUGIN_DESCRIPTION;

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_PLUGIN_DESCRIPTION, GWEN_PluginDescription, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_PLUGIN_DESCRIPTION, GWEN_PluginDescription, GWENHYWFAR_API)
/* Do not terminate these lines with semicolon because they are
   macros, not functions, and ISO C89 does not allow a semicolon
   there. */

GWENHYWFAR_API
void GWEN_PluginDescription_List2_freeAll(GWEN_PLUGIN_DESCRIPTION_LIST2 *pdl);


GWENHYWFAR_API
GWEN_PLUGIN_DESCRIPTION_LIST2 *GWEN_LoadPluginDescrs(const char *path);


/**
 * Loads a list of plugins descriptions.
 * When parsing the description files entries for the current language will
 * be selected. The current language can be set via @ref GWEN_I18N_SetLocale.
 * @param path folder to search for XML files
 * @param type plugin type (property "type" of tag "plugin")
 * @param pdl plugin descriptions list2 to load descriptions to
 */
GWENHYWFAR_API
int GWEN_LoadPluginDescrsByType(const char *path,
                                const char *type,
                                GWEN_PLUGIN_DESCRIPTION_LIST2 *pdl);


GWENHYWFAR_API
void GWEN_PluginDescription_free(GWEN_PLUGIN_DESCRIPTION *pd);


GWENHYWFAR_API
GWEN_PLUGIN_DESCRIPTION*
GWEN_PluginDescription_dup(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
void GWEN_PluginDescription_Attach(GWEN_PLUGIN_DESCRIPTION *pd);


/**
 * Returns the XML node this description consists of (the "plugin" node).
 * It may contain additional information used by programs.
 * This function does not relinquish ownership of the returned pointer,
 * so you MUST NOT free it. As soon as the description itself is destroyed
 * this XML node will be, too. So you have to call GWEN_XMLNode_dup() if
 * you want the XML node to survive the description.
 */
GWENHYWFAR_API
GWEN_XMLNODE*
  GWEN_PluginDescription_GetXmlNode(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char *GWEN_PluginDescription_GetPath(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
void GWEN_PluginDescription_SetPath(GWEN_PLUGIN_DESCRIPTION *pd,
                                    const char *s);

GWENHYWFAR_API
const char *GWEN_PluginDescription_GetName(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char *GWEN_PluginDescription_GetType(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char*
  GWEN_PluginDescription_GetShortDescr(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char*
  GWEN_PluginDescription_GetAuthor(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char*
  GWEN_PluginDescription_GetVersion(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char*
  GWEN_PluginDescription_GetLongDescr(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
const char*
  GWEN_PluginDescription_GetFileName(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
void GWEN_PluginDescription_SetFileName(GWEN_PLUGIN_DESCRIPTION *pd,
                                        const char *s);



/**
 * <p>
 * Seeks for a long description with the given format and the currently
 * selected locale and appends it to the data in the given buffer.
 * </p>
 * <p>
 * The DESCR tag of the plugin description is expected to contain sub tags
 * named TEXT with the property "FORMAT" describing the format and "LANG"
 * containing the language of the element.
 * </p>
 * <p>
 * Currently supported format is "html".
 * </p>
 * @return 0 if ok, !=0 on error
 * @param pd plugin description
 * @param s name of the format (e.g. <i>html</i>)
 * @param buf buffer to append the description to
 */
GWENHYWFAR_API
int
GWEN_PluginDescription_GetLongDescrByFormat(const GWEN_PLUGIN_DESCRIPTION *pd,
                                            const char *s,
                                            GWEN_BUFFER *buf);

GWENHYWFAR_API
  int GWEN_PluginDescription_IsActive(const GWEN_PLUGIN_DESCRIPTION *pd);

GWENHYWFAR_API
  void GWEN_PluginDescription_SetIsActive(GWEN_PLUGIN_DESCRIPTION *pd, int i);


#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_PLUGINDESCR_H */
