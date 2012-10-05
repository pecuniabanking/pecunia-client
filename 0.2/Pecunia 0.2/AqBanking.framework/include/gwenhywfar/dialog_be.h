/***************************************************************************
    begin       : Wed Jan 20 2010
    copyright   : (C) 2010 by Martin Preuss
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


#ifndef GWENHYWFAR_GUI_DIALOG_BE_H
#define GWENHYWFAR_GUI_DIALOG_BE_H


#include <gwenhywfar/dialog.h>
#include <gwenhywfar/widget_be.h>
#include <gwenhywfar/stringlist.h>

#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif


typedef int GWENHYWFAR_CB (*GWEN_DIALOG_SETINTPROPERTY_FN)(GWEN_DIALOG *dlg,
							   GWEN_WIDGET *w,
							   GWEN_DIALOG_PROPERTY prop,
							   int index,
							   int value,
							   int doSignal);

typedef int GWENHYWFAR_CB (*GWEN_DIALOG_GETINTPROPERTY_FN)(GWEN_DIALOG *dlg,
							   GWEN_WIDGET *w,
							   GWEN_DIALOG_PROPERTY prop,
							   int index,
							   int defaultValue);

typedef int GWENHYWFAR_CB (*GWEN_DIALOG_SETCHARPROPERTY_FN)(GWEN_DIALOG *dlg,
							    GWEN_WIDGET *w,
							    GWEN_DIALOG_PROPERTY prop,
							    int index,
							    const char *value,
							    int doSignal);

typedef const char* GWENHYWFAR_CB (*GWEN_DIALOG_GETCHARPROPERTY_FN)(GWEN_DIALOG *dlg,
								    GWEN_WIDGET *w,
								    GWEN_DIALOG_PROPERTY prop,
								    int index,
								    const char *defaultValue);


GWENHYWFAR_API
GWEN_DIALOG_SETINTPROPERTY_FN GWEN_Dialog_SetSetIntPropertyFn(GWEN_DIALOG *dlg,
							      GWEN_DIALOG_SETINTPROPERTY_FN fn);

GWENHYWFAR_API
GWEN_DIALOG_GETINTPROPERTY_FN GWEN_Dialog_SetGetIntPropertyFn(GWEN_DIALOG *dlg,
							      GWEN_DIALOG_GETINTPROPERTY_FN fn);

GWENHYWFAR_API
GWEN_DIALOG_SETCHARPROPERTY_FN GWEN_Dialog_SetSetCharPropertyFn(GWEN_DIALOG *dlg,
								GWEN_DIALOG_SETCHARPROPERTY_FN fn);

GWENHYWFAR_API
GWEN_DIALOG_GETCHARPROPERTY_FN GWEN_Dialog_SetGetCharPropertyFn(GWEN_DIALOG *dlg,
								GWEN_DIALOG_GETCHARPROPERTY_FN fn);


GWENHYWFAR_API
GWEN_WIDGET_TREE *GWEN_Dialog_GetWidgets(const GWEN_DIALOG *dlg);

GWENHYWFAR_API
GWEN_WIDGET *GWEN_Dialog_FindWidgetByName(const GWEN_DIALOG *dlg, const char *name);

GWENHYWFAR_API
GWEN_WIDGET *GWEN_Dialog_FindWidgetByImplData(const GWEN_DIALOG *dlg, int index, const void *ptr);


GWENHYWFAR_API
void GWEN_Dialog_SetGuiId(GWEN_DIALOG *dlg, uint32_t guiid);


/**
 * The dialog remains the owner of the object returned (if any).
 */
GWENHYWFAR_API
GWEN_STRINGLIST *GWEN_Dialog_GetMediaPaths(const GWEN_DIALOG *dlg);


/**
 * Sends a signal to the signal handler of the given dialog. This does @b not send the signal
 * to sub-dialogs. Use @ref GWEN_Dialog_EmitSignalToAll for that.
 */
GWENHYWFAR_API
int GWEN_Dialog_EmitSignal(GWEN_DIALOG *dlg,
			   GWEN_DIALOG_EVENTTYPE t,
			   const char *sender);

/**
 * Emits signals to the given dialog and all its sub-dialogs. This should only be used
 * for signals like @ref GWEN_DialogEvent_TypeInit and @ref GWEN_DialogEvent_TypeFini.
 */
GWENHYWFAR_API
int GWEN_Dialog_EmitSignalToAll(GWEN_DIALOG *dlg,
				GWEN_DIALOG_EVENTTYPE t,
				const char *sender);


GWENHYWFAR_API
GWEN_DIALOG *GWEN_Dialog_GetParentDialog(const GWEN_DIALOG *dlg);


GWENHYWFAR_API
void GWEN_Dialog_Dump(const GWEN_DIALOG *dlg, FILE *f, unsigned int indent);

#ifdef __cplusplus
}
#endif




#endif
