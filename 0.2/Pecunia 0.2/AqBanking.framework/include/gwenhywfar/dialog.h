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


#ifndef GWENHYWFAR_GUI_DIALOG_H
#define GWENHYWFAR_GUI_DIALOG_H


#include <gwenhywfar/inherit.h>
#include <gwenhywfar/list1.h>
#include <gwenhywfar/list2.h>
#include <gwenhywfar/xml.h>
#include <gwenhywfar/db.h>



/** @defgroup MOD_DIALOG_DIALOG Dialogs
 * @ingroup MOD_DIALOG
 *
 * @brief This module contains the definition of GWEN_GUI dialogs.
 *
 * A dialog contains widgets which can be accessed by name. A dialog can contain multiple
 * subdialogs. Widgets of a dialog and its subdialogs should have unique names.
 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif


typedef struct GWEN_DIALOG GWEN_DIALOG;
GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_DIALOG, GWENHYWFAR_API)
GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_DIALOG, GWEN_Dialog, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_DIALOG, GWEN_Dialog, GWENHYWFAR_API)


#define GWEN_WIDGET_FLAGS_NONE              0x00000000L
#define GWEN_WIDGET_FLAGS_FILLX             0x80000000L
#define GWEN_WIDGET_FLAGS_FILLY             0x40000000L
#define GWEN_WIDGET_FLAGS_READONLY          0x20000000L
#define GWEN_WIDGET_FLAGS_PASSWORD          0x10000000L
#define GWEN_WIDGET_FLAGS_DEFAULT_WIDGET    0x08000000L

#define GWEN_WIDGET_FLAGS_DECOR_SHRINKABLE  0x04000000L
#define GWEN_WIDGET_FLAGS_DECOR_STRETCHABLE 0x02000000L
#define GWEN_WIDGET_FLAGS_DECOR_MINIMIZE    0x01000000L
#define GWEN_WIDGET_FLAGS_DECOR_MAXIMIZE    0x00800000L
#define GWEN_WIDGET_FLAGS_DECOR_CLOSE       0x00400000L
#define GWEN_WIDGET_FLAGS_DECOR_MENU        0x00200000L

#define GWEN_WIDGET_FLAGS_FIXED_WIDTH       0x00100000L
#define GWEN_WIDGET_FLAGS_FIXED_HEIGHT      0x00080000L
#define GWEN_WIDGET_FLAGS_EQUAL_WIDTH       0x00040000L
#define GWEN_WIDGET_FLAGS_EQUAL_HEIGHT      0x00020000L

#define GWEN_WIDGET_FLAGS_JUSTIFY_LEFT      0x00010000L
#define GWEN_WIDGET_FLAGS_JUSTIFY_RIGHT     0x00008000L
#define GWEN_WIDGET_FLAGS_JUSTIFY_TOP       0x00004000L
#define GWEN_WIDGET_FLAGS_JUSTIFY_BOTTOM    0x00002000L
#define GWEN_WIDGET_FLAGS_JUSTIFY_CENTERX   0x00001000L
#define GWEN_WIDGET_FLAGS_JUSTIFY_CENTERY   0x00000800L

#define GWEN_WIDGET_FLAGS_NO_WORDWRAP       0x00000400L



typedef enum {
  GWEN_DialogEvent_TypeInit=0,
  GWEN_DialogEvent_TypeFini,
  GWEN_DialogEvent_TypeValueChanged,
  GWEN_DialogEvent_TypeActivated,
  GWEN_DialogEvent_TypeEnabled,
  GWEN_DialogEvent_TypeDisabled,
  GWEN_DialogEvent_TypeClose,

  GWEN_DialogEvent_TypeLast
} GWEN_DIALOG_EVENTTYPE;



/**
 * These are the predefined result codes to be returned by a signal handler.
 * (Note: this is not a typedef because the signal handler has to be able to
 * return GWEN_ERROR codes as well).
 */
enum {
  GWEN_DialogEvent_ResultHandled=0,
  GWEN_DialogEvent_ResultNotHandled,
  GWEN_DialogEvent_ResultAccept,
  GWEN_DialogEvent_ResultReject
};


/**
 * The signal handler should return one of the event result code
 * (see @ref GWEN_DialogEvent_ResultHandled and following) or a GWEN_ERROR
 * code.
 */
typedef int GWENHYWFAR_CB (*GWEN_DIALOG_SIGNALHANDLER)(GWEN_DIALOG *dlg,
						       GWEN_DIALOG_EVENTTYPE t,
						       const char *sender);



GWENHYWFAR_API
GWEN_DIALOG *GWEN_Dialog_new(const char *dialogId);

GWENHYWFAR_API
void GWEN_Dialog_free(GWEN_DIALOG *dlg);

/**
 * Read dialog description from the given XML element.
 */
GWENHYWFAR_API
int GWEN_Dialog_ReadXml(GWEN_DIALOG *dlg, GWEN_XMLNODE *node);


/**
 * Read dialog description from the given XML file.
 */
GWENHYWFAR_API
int GWEN_Dialog_ReadXmlFile(GWEN_DIALOG *dlg, const char *fname);

/**
 * The dialog id is in most cases hardcoded into the describing XML
 * file. It is the unique name of the dialog. This name is used to
 * read/write dialog preferences.
 */
GWENHYWFAR_API
const char*GWEN_Dialog_GetId(const GWEN_DIALOG *dlg);


GWENHYWFAR_API
uint32_t GWEN_Dialog_GetGuiId(const GWEN_DIALOG *dlg);


/**
 * Add a path where to find media such as icons, images etc when used
 * e.g. with pushbuttons or images.
 */
GWENHYWFAR_API
void GWEN_Dialog_AddMediaPath(GWEN_DIALOG *dlg, const char *s);


/**
 * Add paths from the given path manager.
 * For each entry of the given path managers path list that entry is
 * concatenated with the relPath argument (if not NULL) and added to the
 * dialogs list of media paths.
 * @param dlg dialog to which media paths are to be added
 * @param destlib see the argument of the same name in @ref GWEN_PathManager_GetPaths
 * @param pathName see the argument of the same name in @ref GWEN_PathManager_GetPaths
 * @param relPath optional relative path to be added to each entry of the given
 *   path manager's entry to form a media path for this dialog
 */
GWENHYWFAR_API
void GWEN_Dialog_AddMediaPathsFromPathManager(GWEN_DIALOG *dlg,
					      const char *destlib,
					      const char *pathName,
					      const char *relPath);


/**
 * Inserts a sub-dialog into the given dialog. The widgets of the subdialog become
 * children of the main dialog below the widget referenced to by parentName.
 * Please take care that the subdialog doesn't contain widgets with the same name as
 * the main dialog.
 * This only works if @ref GWEN_Gui_ExecDialog has not been called yet!
 * Takes over ownership of the given subdialog.
 */
GWENHYWFAR_API
int GWEN_Dialog_AddSubDialog(GWEN_DIALOG *dlg,
			     const char *parentWidgetName,
			     GWEN_DIALOG *subdlg);

GWENHYWFAR_API
int GWEN_Dialog_RemoveWidget(GWEN_DIALOG *dlg, const char *name);


/**
 * Sets the signal handler of the dialog. Please note that this doesn't set the signal
 * handler of any sub-dialog, so each dialog will only receive its own signals.
 */
GWENHYWFAR_API
GWEN_DIALOG_SIGNALHANDLER GWEN_Dialog_SetSignalHandler(GWEN_DIALOG *dlg,
                                                       GWEN_DIALOG_SIGNALHANDLER fn);





typedef enum {
  GWEN_DialogProperty_None=0,

  GWEN_DialogProperty_Title,
  GWEN_DialogProperty_Value,
  GWEN_DialogProperty_MinValue,
  GWEN_DialogProperty_MaxValue,
  GWEN_DialogProperty_Enabled,
  GWEN_DialogProperty_AddValue,
  GWEN_DialogProperty_ClearValues,
  GWEN_DialogProperty_ValueCount,
  GWEN_DialogProperty_ColumnWidth,
  GWEN_DialogProperty_Width,
  GWEN_DialogProperty_Height,
  GWEN_DialogProperty_SelectionMode,
  GWEN_DialogProperty_SelectionState,
  GWEN_DialogProperty_Focus,
  /** value=direction, index=column */
  GWEN_DialogProperty_SortDirection,
  GWEN_DialogProperty_Sort,
  GWEN_DialogProperty_Visibility,

  GWEN_DialogProperty_Unknown=-1
} GWEN_DIALOG_PROPERTY;


typedef enum {
  GWEN_Dialog_SelectionMode_None=0,
  GWEN_Dialog_SelectionMode_Single,
  GWEN_Dialog_SelectionMode_Multi
} GWEN_DIALOG_SELECTION_MODE;


typedef enum {
  GWEN_DialogSortDirection_None=0,
  GWEN_DialogSortDirection_Up,
  GWEN_DialogSortDirection_Down
} GWEN_DIALOG_SORT_DIRECTION;


/** @name Functions Available After Init Event
 *
 * Functions in this group can only be called while in a @ref GWEN_Gui_ExecDialog
 * loop or between calls to @ref GWEN_Gui_OpenDialog() and @ref GWEN_Gui_CloseDialog()
 * because these functions directly manipulate GUI widgets which are only valid in the
 * intervals mentioned above.
 */
/*@{*/

/**
 * This function sets the value of an integer property.
 * @param dlg pointer to the dialog to be manipulated
 * @param name name of the widget of the dialog whose property is to be
 *   manipulated. Use NULL or an empty string to select the dialog itself
 * @param prop property to modify (see @ref GWEN_DialogProperty_Title ff)
 * @param index for widgets with array like data this is the index into that
 *   array. Normally this value is 0. However, there are examples when this
 *   parameter does not equal 0. The property @ref GWEN_DialogProperty_ColumnWidth
 *   of a @ref GWEN_Widget_TypeListBox is such an example. Here the index
 *   selects the column whose width is to be changed.
 * @param value the value to set
 * @param doSignal some implementations send the @ref GWEN_DialogEvent_TypeValueChanged
 *   signal when values are manipulated. Set this parameter to 0 if you don't need that.
 *   However, this is just a hint for the implementation, you should not rely on it
 *   actually being regarded by the implementation. So you might or might not get such
 *   a signal upon manipulation of a property.
 */
GWENHYWFAR_API
int GWEN_Dialog_SetIntProperty(GWEN_DIALOG *dlg,
			       const char *name,
			       GWEN_DIALOG_PROPERTY prop,
                               int index,
			       int value,
			       int doSignal);

/**
 * This function returns the value of an integer property.
 * @param dlg pointer to the dialog to be inspected
 * @param name name of the widget of the dialog whose property is to be
 *   read. Use NULL or an empty string to select the dialog itself
 * @param prop property to read (see @ref GWEN_DialogProperty_Title ff)
 * @param index (see @ref GWEN_Dialog_SetIntProperty for an explanation)
 * @param defaultValue default value to be returned if the real value is unavailable
 */
GWENHYWFAR_API
int GWEN_Dialog_GetIntProperty(GWEN_DIALOG *dlg,
			       const char *name,
			       GWEN_DIALOG_PROPERTY prop,
			       int index,
			       int defaultValue);

/**
 * Modify a string property.
 *
 * This might invalidate a pointer previously returned via
 * @ref GWEN_Dialog_GetCharProperty.
 */
GWENHYWFAR_API
int GWEN_Dialog_SetCharProperty(GWEN_DIALOG *dlg,
				const char *name,
				GWEN_DIALOG_PROPERTY prop,
				int index,
				const char *value,
				int doSignal);

/**
 * Returns a string property.
 *
 * If the pointer returned is not the @c defaultValue but rather a pointer
 * generated by the dialog framework implementation then the pointer is only
 * guaranteed to be valid until the next call with the same values of
 * @c name and @c property.
 *
 * Example: If you cycle through all entries of a listbox (by modifying @c index)
 * each successive call overwrites the string previously returned.
 * However, when you call this function once with the property
 * @ref GWEN_DialogProperty_Title and next time with a property of
 * @ref GWEN_DialogProperty_Value those two pointers will not influence
 * each other.
 * @param dlg pointer to the dialog to be inspected
 * @param name name of the widget of the dialog whose property is to be
 *   read. Use NULL or an empty string to select the dialog itself
 * @param prop property to read (see @ref GWEN_DialogProperty_Title ff)
 * @param index (see @ref GWEN_Dialog_SetIntProperty for an explanation)
 * @param defaultValue default value to be returned if the real value is unavailable (e.g.
 *   if the current value is an empty string)
 */
GWENHYWFAR_API
const char *GWEN_Dialog_GetCharProperty(GWEN_DIALOG *dlg,
					const char *name,
					GWEN_DIALOG_PROPERTY prop,
					int index,
					const char *defaultValue);
/*@}*/




/** @name Functions Available After Construction
 *
 * These functions manipulate the descriptions of dialogs and widgets, the don't operate
 * on the GUI widgets. That's why they are immediately available after construction.
 */
/*@{*/
GWENHYWFAR_API
uint32_t GWEN_Dialog_GetWidgetFlags(const GWEN_DIALOG *dlg, const char *name);

GWENHYWFAR_API
void GWEN_Dialog_SetWidgetFlags(GWEN_DIALOG *dlg, const char *name, uint32_t fl);

GWENHYWFAR_API
void GWEN_Dialog_AddWidgetFlags(GWEN_DIALOG *dlg, const char *name, uint32_t fl);

GWENHYWFAR_API
void GWEN_Dialog_SubWidgetFlags(GWEN_DIALOG *dlg, const char *name, uint32_t fl);

/**
 * This is another attribute from the dialog description file. It is used with
 * widgets like @ref GWEN_Widget_TypeLineEdit to specify the widget width in
 * number of characters. It is also used for @ref GWEN_Widget_TypeGridLayout to specify
 * the number of columns.
 * @param dlg pointer to the dialog to be inspected
 * @param name name of the widget of the dialog whose attribute is to be read.
 */
GWENHYWFAR_API
int GWEN_Dialog_GetWidgetColumns(const GWEN_DIALOG *dlg, const char *name);



/**
 * Set the number of columns (see @ref GWEN_Dialog_GetWidgetColumns).
 */
GWENHYWFAR_API
void GWEN_Dialog_SetWidgetColumns(GWEN_DIALOG *dlg, const char *name, int i);



/**
 * This is another attribute from the dialog description file. It is used with
 * widgets @ref GWEN_Widget_TypeGridLayout to specify the number of rows.
 * @param dlg pointer to the dialog to be inspected
 * @param name name of the widget of the dialog whose attribute is to be read.
 */
GWENHYWFAR_API
int GWEN_Dialog_GetWidgetRows(const GWEN_DIALOG *dlg, const char *name);


/**
 * Set the number of columns (see @ref GWEN_Dialog_GetWidgetRows).
 */
GWENHYWFAR_API
void GWEN_Dialog_SetWidgetRows(GWEN_DIALOG *dlg, const char *name, int i);


GWENHYWFAR_API
const char *GWEN_Dialog_GetWidgetText(const GWEN_DIALOG *dlg, const char *name);

GWENHYWFAR_API
void GWEN_Dialog_SetWidgetText(GWEN_DIALOG *dlg, const char *name, const char *t);


/**
 * Returns a DB which can be used to read and store preference for the dialog.
 * Most dialogs in AqBanking use this to remember the dialog geometry or the widths
 * of columns in lists etc.
 * This DB is automatically read from within the constructor (@ref GWEN_Dialog_new)
 * and written from within the destructor (@ref GWEN_Dialog_free). This is achieved by
 * calling the virtual functions @ref GWEN_Gui_ReadDialogPrefs and @ref GWEN_Gui_WriteDialogPrefs
 * respectively.
 * However, the current GWEN_GUI implementation must implement these functions. Fortunately,
 * AqBanking's GUI implementation (use it with @ref AB_Gui_Extend) does that. It reads/writes
 * those dialog settings from/into its shared settings database.
 */
GWENHYWFAR_API
GWEN_DB_NODE *GWEN_Dialog_GetPreferences(const GWEN_DIALOG *dlg);

/*@}*/



/** @name Localisation
 *
 */
/*@{*/

/**
 * Set the I18N domain (see @ref GWEN_Dialog_GetI18nDomain).
 */
GWENHYWFAR_API
void GWEN_Dialog_SetI18nDomain(GWEN_DIALOG *dlg, const char *s);

/**
 * Returns the I18N domain of the dialog. This is normally taken from the dialog
 * description file (attribute "i18n" of the "dialog" element).
 * This domain is used to localize strings of the dialog description file by using
 * it as first argument to @ref GWEN_I18N_Translate().
 * This allows for translation within the context of the dialog. AqBanking's dialogs
 * use "aqbanking" as I18N domain, so the translation for its dialogs also appear in
 * its pot files.
 */
GWENHYWFAR_API
const char *GWEN_Dialog_GetI18nDomain(const GWEN_DIALOG *dlg);

/**
 * Translates a string within the I18N domain of the dialog (see @ref GWEN_Dialog_GetI18nDomain).
 */
GWENHYWFAR_API
const char *GWEN_Dialog_TranslateString(const GWEN_DIALOG *dlg, const char *s);
/*@}*/


#ifdef __cplusplus
}
#endif



/*@}*/


#endif
