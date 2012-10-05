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


#ifndef GWENHYWFAR_I18N_H
#define GWENHYWFAR_I18N_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/misc.h>
#include <gwenhywfar/misc2.h>
#include <gwenhywfar/xml.h>
#include <gwenhywfar/stringlist.h>



#ifdef __cplusplus
extern "C" {
#endif

GWENHYWFAR_API
int GWEN_I18N_SetLocale(const char *s);

/**
 * Gwenhywfar remains the owner of the object returned (if any), so you
 * MUST NOT free it.
 */
GWENHYWFAR_API
GWEN_STRINGLIST *GWEN_I18N_GetCurrentLocaleList();

GWENHYWFAR_API
const char *GWEN_I18N_GetCurrentLocale();

GWENHYWFAR_API
const char *GWEN_I18N_Translate(const char *textdomain, const char *text);

GWENHYWFAR_API
int GWEN_I18N_BindTextDomain_Dir(const char *textdomain, const char *folder);

GWENHYWFAR_API
int GWEN_I18N_BindTextDomain_Codeset(const char *textdomain, const char *cs);

#ifdef __cplusplus
}
#endif




#endif




