/***************************************************************************
    begin       : Tue Oct 02 2002
    copyright   : (C) 2002-2010 by Martin Preuss
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

#ifndef GWENHYWFAR_GUI_GUI_BE_H
#define GWENHYWFAR_GUI_GUI_BE_H


#include <gwenhywfar/gui.h>


#ifdef __cplusplus
extern "C" {
#endif



GWENHYWFAR_API
void GWEN_Gui_SetName(GWEN_GUI *gui, const char *name);




/** @name Prototypes For Virtual User Interaction Functions
 *
 */
/*@{*/


/**
 * This function is used to make the application print something.
 * The same restrictions noted above apply to the text parameter (utf-8,
 * maybe containing HTML).
 * Please see @ref GWEN_Gui_Print for details.
 */
typedef int (*GWEN_GUI_PRINT_FN)(GWEN_GUI *gui,
				 const char *docTitle,
				 const char *docType,
				 const char *descr,
				 const char *text,
				 uint32_t guiid);

/**
 * This function retrieves a pasword or pin.
 */
typedef int (*GWEN_GUI_GETPASSWORD_FN)(GWEN_GUI *gui,
				       uint32_t flags,
				       const char *token,
				       const char *title,
				       const char *text,
				       char *buffer,
				       int minLen,
				       int maxLen,
				       uint32_t guiid);

/**
 * This functions sets the status of a password.
 */
typedef int (*GWEN_GUI_SETPASSWORDSTATUS_FN)(GWEN_GUI *gui,
					     const char *token,
					     const char *pin,
					     GWEN_GUI_PASSWORD_STATUS status,
					     uint32_t guiid);


/**
 * This function is called at the beginning of @ref GWEN_Logger_Log() and my be used
 * to intercept log messages in general (e.g. to divert them to an internal
 * log mechanism of the application).
 * @return 1 if the message has been handled by the application,
 *         0 if the message should be handled as usual
 * @param gui pointer to the gui which receives this call
 * @param logDomain name of the logging domain (e.g. GWEN_LOGDOMAIN)
 * @param priority see @ref GWEN_Logger_Log
 * @param s the message to be logged (this is the raw message from the caller)
 *
 */
typedef int (*GWEN_GUI_LOG_HOOK_FN)(GWEN_GUI *gui,
				    const char *logDomain,
				    GWEN_LOGGER_LEVEL priority, const char *s);

typedef int (*GWEN_GUI_WAITFORSOCKETS_FN)(GWEN_GUI *gui,
					  GWEN_SOCKET_LIST2 *readSockets,
					  GWEN_SOCKET_LIST2 *writeSockets,
					  int msecs,
					  uint32_t guiid);

typedef int (*GWEN_GUI_CHECKCERT_FN)(GWEN_GUI *gui,
				     const GWEN_SSLCERTDESCR *cert,
				     GWEN_SYNCIO *sio,
				     uint32_t guiid);

typedef int (*GWEN_GUI_KEYDATAFROMTEXT_OPENSSL_FN)(GWEN_GUI *gui,
						   const char *text,
						   unsigned char *buffer,
						   unsigned int bufLength);

typedef int (*GWEN_GUI_EXEC_DIALOG_FN)(GWEN_GUI *gui,
				       GWEN_DIALOG *dlg,
				       uint32_t guiid);


typedef int (*GWEN_GUI_OPEN_DIALOG_FN)(GWEN_GUI *gui,
				       GWEN_DIALOG *dlg,
				       uint32_t guiid);

typedef int (*GWEN_GUI_CLOSE_DIALOG_FN)(GWEN_GUI *gui, GWEN_DIALOG *dlg);

typedef int (*GWEN_GUI_RUN_DIALOG_FN)(GWEN_GUI *gui, GWEN_DIALOG *dlg, int timeout);


typedef int (*GWEN_GUI_READ_DIALOG_PREFS_FN)(GWEN_GUI *gui, const char *groupName, const char *altName,
					     GWEN_DB_NODE **pDb);

typedef int (*GWEN_GUI_WRITE_DIALOG_PREFS_FN)(GWEN_GUI *gui, const char *groupName,
					      GWEN_DB_NODE *db);


typedef int (*GWEN_GUI_GET_FILENAME_FN)(GWEN_GUI *gui,
                                        const char *caption,
					GWEN_GUI_FILENAME_TYPE fnt,
					uint32_t flags,
					const char *patterns,
					GWEN_BUFFER *pathBuffer,
					uint32_t guiid);

typedef int (*GWEN_GUI_GETSYNCIO_FN)(GWEN_GUI *gui, const char *url,
				     const char *defaultProto,
                                     int defaultPort,
				     GWEN_SYNCIO **pSio);


/*@}*/





/** @name Setters For Virtual User Interaction Functions
 *
 * The functions in this group set the corresponding callback function
 * pointers.
 */
/*@{*/


GWENHYWFAR_API
GWEN_GUI_PRINT_FN GWEN_Gui_SetPrintFn(GWEN_GUI *gui, GWEN_GUI_PRINT_FN f);

GWENHYWFAR_API 
GWEN_GUI_GETPASSWORD_FN GWEN_Gui_SetGetPasswordFn(GWEN_GUI *gui, GWEN_GUI_GETPASSWORD_FN f);

GWENHYWFAR_API
GWEN_GUI_SETPASSWORDSTATUS_FN
GWEN_Gui_SetSetPasswordStatusFn(GWEN_GUI *gui, GWEN_GUI_SETPASSWORDSTATUS_FN f);


GWENHYWFAR_API
GWEN_GUI_LOG_HOOK_FN GWEN_Gui_SetLogHookFn(GWEN_GUI *gui, GWEN_GUI_LOG_HOOK_FN f);


GWENHYWFAR_API
GWEN_GUI_WAITFORSOCKETS_FN GWEN_Gui_SetWaitForSocketsFn(GWEN_GUI *gui, GWEN_GUI_WAITFORSOCKETS_FN f);

GWENHYWFAR_API
GWEN_GUI_CHECKCERT_FN GWEN_Gui_SetCheckCertFn(GWEN_GUI *gui, GWEN_GUI_CHECKCERT_FN f);

GWENHYWFAR_API
  GWEN_GUI_KEYDATAFROMTEXT_OPENSSL_FN
  GWEN_Gui_SetKeyDataFromTextOpenSslFn(GWEN_GUI *gui,
                                       GWEN_GUI_KEYDATAFROMTEXT_OPENSSL_FN f);

GWENHYWFAR_API
GWEN_GUI_EXEC_DIALOG_FN GWEN_Gui_SetExecDialogFn(GWEN_GUI *gui, GWEN_GUI_EXEC_DIALOG_FN f);


GWENHYWFAR_API
GWEN_GUI_OPEN_DIALOG_FN GWEN_Gui_SetOpenDialogFn(GWEN_GUI *gui, GWEN_GUI_OPEN_DIALOG_FN f);

GWENHYWFAR_API
GWEN_GUI_CLOSE_DIALOG_FN GWEN_Gui_SetCloseDialogFn(GWEN_GUI *gui, GWEN_GUI_CLOSE_DIALOG_FN f);

GWENHYWFAR_API
GWEN_GUI_RUN_DIALOG_FN GWEN_Gui_SetRunDialogFn(GWEN_GUI *gui, GWEN_GUI_RUN_DIALOG_FN f);


GWENHYWFAR_API
GWEN_GUI_READ_DIALOG_PREFS_FN
  GWEN_Gui_SetReadDialogPrefsFn(GWEN_GUI *gui, GWEN_GUI_READ_DIALOG_PREFS_FN f);

GWENHYWFAR_API
GWEN_GUI_WRITE_DIALOG_PREFS_FN
  GWEN_Gui_SetWriteDialogPrefsFn(GWEN_GUI *gui, GWEN_GUI_WRITE_DIALOG_PREFS_FN f);


GWENHYWFAR_API
GWEN_GUI_GET_FILENAME_FN GWEN_Gui_SetGetFileNameFn(GWEN_GUI *gui, GWEN_GUI_GET_FILENAME_FN f);


GWENHYWFAR_API
GWEN_GUI_GETSYNCIO_FN GWEN_Gui_SetGetSyncIoFn(GWEN_GUI *gui, GWEN_GUI_GETSYNCIO_FN f);


/*@}*/




/** @name Dialog Related Functions
 *
 * These are obsoleted by the GWEN_DIALOG framework.
 */
/*@{*/

/**
 * The implementation should call this function if it implements the dialog framework.
 * It sets the obsoleted callbacks to use the GWEN_DIALOG framework.
 */
GWENHYWFAR_API
void GWEN_Gui_UseDialogs(GWEN_GUI *gui);


/**
 * Let the application read a GWEN_DB. This function is used by the platform-independent
 * dialogs to read GUI settings (e.g. width, height etc).
 *
 * This is implemented by AB_Gui, an extension of the GWEN_GUI in AqBanking using
 * AqBanking's shared configuration module to load/save dialog settings.
 *
 * @return 0 on success, error code on error
 *
 * @param groupName name of the db to load
 *
 * @param altName alternative name in case there is no group of the name @b groupName
 *
 * @param pDb pointer to receive the GWEN_DB read
 */
GWENHYWFAR_API
int GWEN_Gui_ReadDialogPrefs(const char *groupName,
			     const char *altName,
			     GWEN_DB_NODE **pDb);

/**
 * Let the application write a GWEN_DB. This function is used by the platform-independent
 * dialogs to write GUI settings (e.g. width, height etc).
 *
 * @return 0 on success, error code on error
 *
 * @param groupName name of the db to save
 *
 * @param pDb pointer to receive the GWEN_DB read
 */
GWENHYWFAR_API
int GWEN_Gui_WriteDialogPrefs(const char *groupName,
			      GWEN_DB_NODE *db);


/*@}*/




/** @name Prototypes For Virtual Lowlevel User Interaction Functions
 *
 * Please note that these virtual functions are now obsolete
 * since the dialog framework is now able to handle them.
 *
 * If these functions are unchanged then the current dialog framework implementation
 * will handle them. Currently there are implementations for FOX1.6, QT3 and QT4.
 */
/*@{*/
/**
 * Please see @ref GWEN_Gui_MessageBox for details.
 *
 */
typedef int (*GWEN_GUI_MESSAGEBOX_FN)(GWEN_GUI *gui,
				      uint32_t flags,
				      const char *title,
				      const char *text,
				      const char *b1,
				      const char *b2,
				      const char *b3,
				      uint32_t guiid);

/**
 * Please see @ref GWEN_Gui_InputBox for details.
 *
 */
typedef int (*GWEN_GUI_INPUTBOX_FN)(GWEN_GUI *gui,
				    uint32_t flags,
				    const char *title,
				    const char *text,
				    char *buffer,
				    int minLen,
				    int maxLen,
				    uint32_t guiid);

/**
 * Please see @ref GWEN_Gui_ShowBox for details.
 *
 */
typedef uint32_t (*GWEN_GUI_SHOWBOX_FN)(GWEN_GUI *gui, 
					uint32_t flags,
					const char *title,
					const char *text,
					uint32_t guiid);

/**
 * Please see @ref GWEN_Gui_HideBox for details.
 *
 */
typedef void (*GWEN_GUI_HIDEBOX_FN)(GWEN_GUI *gui, uint32_t id);

/**
 * Please see @ref GWEN_Gui_ProgressStart for details.
 *
 */
typedef uint32_t
  (*GWEN_GUI_PROGRESS_START_FN)(GWEN_GUI *gui, 
				uint32_t progressFlags,
				const char *title,
				const char *text,
				uint64_t total,
				uint32_t guiid);

/**
 * Please see @ref GWEN_Gui_ProgressAdvance for details.
 *
 */
typedef int (*GWEN_GUI_PROGRESS_ADVANCE_FN)(GWEN_GUI *gui, 
					    uint32_t id,
					    uint64_t progress);

/**
 * Please see @ref GWEN_Gui_ProgressLog for details.
 *
 */
typedef int (*GWEN_GUI_PROGRESS_LOG_FN)(GWEN_GUI *gui, 
					uint32_t id,
					GWEN_LOGGER_LEVEL level,
					const char *text);
/**
 * Please see @ref GWEN_Gui_ProgressEnd for details.
 *
 */
typedef int (*GWEN_GUI_PROGRESS_END_FN)(GWEN_GUI *gui, uint32_t id);
/*@}*/



/** @name Obsolete Setters For Virtual User Interaction Functions
 *
 * These are obsoleted by the GWEN_DIALOG framework.
 *
 * If your GWEN_GUI implementation supports the GWEN_DIALOG framework (as
 * the provided FOX16, QT3 and QT4 implementations do) it should call
 * @ref GWEN_Gui_UseDialogs to make GWEN_GUI uses platform independent
 * dialogs for the functions in this group.
 */
/*@{*/

GWENHYWFAR_API 
GWEN_GUI_MESSAGEBOX_FN GWEN_Gui_SetMessageBoxFn(GWEN_GUI *gui,
						GWEN_GUI_MESSAGEBOX_FN f);
GWENHYWFAR_API 
GWEN_GUI_INPUTBOX_FN GWEN_Gui_SetInputBoxFn(GWEN_GUI *gui,
					    GWEN_GUI_INPUTBOX_FN f);
GWENHYWFAR_API 
GWEN_GUI_SHOWBOX_FN GWEN_Gui_SetShowBoxFn(GWEN_GUI *gui,
					  GWEN_GUI_SHOWBOX_FN f);
GWENHYWFAR_API
GWEN_GUI_HIDEBOX_FN GWEN_Gui_SetHideBoxFn(GWEN_GUI *gui,
					  GWEN_GUI_HIDEBOX_FN f);

GWENHYWFAR_API 
GWEN_GUI_PROGRESS_START_FN
GWEN_Gui_SetProgressStartFn(GWEN_GUI *gui, GWEN_GUI_PROGRESS_START_FN f);

GWENHYWFAR_API
GWEN_GUI_PROGRESS_ADVANCE_FN
GWEN_Gui_SetProgressAdvanceFn(GWEN_GUI *gui, GWEN_GUI_PROGRESS_ADVANCE_FN f);

GWENHYWFAR_API
GWEN_GUI_PROGRESS_LOG_FN
GWEN_Gui_SetProgressLogFn(GWEN_GUI *gui, GWEN_GUI_PROGRESS_LOG_FN f);

GWENHYWFAR_API 
GWEN_GUI_PROGRESS_END_FN
GWEN_Gui_SetProgressEndFn(GWEN_GUI *gui, GWEN_GUI_PROGRESS_END_FN f);


/*@}*/


#ifdef __cplusplus
}
#endif


#endif

