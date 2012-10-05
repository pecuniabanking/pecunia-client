/***************************************************************************
 begin       : Mon Mar 01 2004
 copyright   : (C) 2004-2008 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_GUI_CGUI_H
#define GWEN_GUI_CGUI_H

#include <gwenhywfar/gui.h>


#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup MOD_GUI_CGUI GUI Implementation for the Console
 * @ingroup MOD_GUI
 *
 * This is an implementation of GWEN_GUI for the console. It supports
 * interactive and non-interactive mode, provides a cache for passwords/pins
 * and TLS certificates. It converts UTF8 messages into other character sets
 * if requested (e.g. for consoles which do not support UTF8).
 */
/*@{*/

/** Constructor
 *
 */
GWENHYWFAR_API 
GWEN_GUI *GWEN_Gui_CGui_new();


/** @name Character Set
 *
 * All messages and texts can be converted from UTF8 automatically.
 * This needs the name of the destination character set.
 * See output of <i>iconv --list</i> for a list of supported
 * character sets.
 */
/*@{*/
GWENHYWFAR_API 
const char *GWEN_Gui_CGui_GetCharSet(const GWEN_GUI *gui);

GWENHYWFAR_API 
void GWEN_Gui_CGui_SetCharSet(GWEN_GUI *gui, const char *s);

/*@}*/


/** @name Interactive/Non-interactive Mode
 *
 * This implementation can be used in interactive or non-interactive mode.
 * In non-interactive mode all input requests which can not be asked
 * automatically will return an error.
 * However, most questions concern input of pins and password, and for those
 * the password cache can be used. Another frequent source for input requests
 * is the acknowledging of TLS certificates which can also be handled
 * automatically by using the certificate cache (see below).
 *
 * Also, in non-interactive mode all calls to GWEN_GUI_MessageBox will be
 * handled different. If the severity of a message is
 * GWEN_GUI_MSG_FLAGS_SEVERITY_DANGEROUS or higher an error is returned.
 * Otherwise the default result (as indicated by the arguments of
 * @ref GWEN_GUI_MessageBox) is returned instead.
 *
 * These settings together allow for a non-interactive use.
 */
/*@{*/
GWENHYWFAR_API DEPRECATED
int GWEN_Gui_CGui_GetIsNonInteractive(const GWEN_GUI *gui);

GWENHYWFAR_API DEPRECATED
void GWEN_Gui_CGui_SetIsNonInteractive(GWEN_GUI *gui, int i);
/*@}*/


/** @name Password Cache
 *
 * This implementation provides a password cache. This will be
 * consulted upon @ref GWEN_Gui_GetPassword. The implementation of
 * @ref GWEN_Gui_SetPasswordStatus also accesses this password cache.
 *
 * Normally this cache is filled from password files (like those
 * specified via option <i>-P</i> of <i>aqbanking-cli</i>).
 */
/**@{*/
/**
 * Set the password DB. Takes over the given DB.
 * @param gui GUI object
 * @param dbPasswords password cache
 * @param persistent if !=0 then the passwords come from a password file
 * and a request to clear the password cache will be ignored.
 */
GWENHYWFAR_API 
void GWEN_Gui_CGui_SetPasswordDb(GWEN_GUI *gui,
				 GWEN_DB_NODE *dbPasswords,
				 int persistent);

/**
 * Returns a pointer to the internally used password cache. The GUI
 * object remains the owner of the object returned (if any).
 */
GWENHYWFAR_API 
GWEN_DB_NODE *GWEN_Gui_CGui_GetPasswordDb(const GWEN_GUI *gui);
/*@}*/


/** @name TLS Certificate Cache
 *
 * This implementation provides a certificate cache which takes
 * into account the fingerprint of a certificate offered and the
 * status text. This combination is hashed and the resulting hash is
 * the key into the internal cert db.
 *
 * Most AqBanking applications nowadays use the shared application data
 * "certs" as returned by AB_Banking_GetSharedData() to read and write
 * the certificate DB.
 */
/**@{*/
/**
 * Set the certificate DB. Takes over the given DB.
 */
GWENHYWFAR_API 
void GWEN_Gui_CGui_SetCertDb(GWEN_GUI *gui, GWEN_DB_NODE *dbCerts);

/**
 * Returns a pointer to the internal certificate cache. The GUI
 * object remains the owner of the object returned (if any).
 */
GWENHYWFAR_API 
GWEN_DB_NODE *GWEN_Gui_CGui_GetCertDb(const GWEN_GUI *gui);

/**
 * In non-interactive mode only known certificates are accepted.
 * If the parameter i unequals zero new certs are also accepted if they
 * are valid (which means signed by a known and trusted authority, not expired
 * etc).
 * Invalid certificates are always rejected in non-interactive mode.
 */
GWENHYWFAR_API DEPRECATED
void GWEN_Gui_CGui_SetAcceptAllValidCerts(GWEN_GUI *gui, int i);

/**
 * See @ref GWEN_Gui_CGui_SetAcceptAllValidCerts
 */
GWENHYWFAR_API DEPRECATED
int GWEN_Gui_CGui_GetAcceptAllValidCerts(const GWEN_GUI *gui);

/*@}*/


/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif



