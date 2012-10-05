/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id: crypttoken.h 1113 2007-01-10 09:14:16Z martin $
    begin       : Wed Mar 16 2005
    copyright   : (C) 2005 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_CRYPT_TOKEN_PLUGIN_H
#define GWEN_CRYPT_TOKEN_PLUGIN_H


#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/plugin.h>
#include <gwenhywfar/ct.h>



#define GWEN_CRYPT_TOKEN_PLUGIN_TYPENAME "ct"
#define GWEN_CRYPT_TOKEN_FOLDER "ct"


#ifdef __cplusplus
extern "C" {
#endif


GWENHYWFAR_API GWEN_CRYPT_TOKEN *GWEN_Crypt_Token_Plugin_CreateToken(GWEN_PLUGIN *pl, const char *name);



/**
 * <p>This function is used to let a crypt token plugin check whether it
 * supports a given plugin.</p>
 * <p>Initially the given buffers may contain some values to narrow the
 * search. For chip cards the <i>name</i> argument may contain the serial
 * number of the card (if known). For file based crypt tokens this argument
 * must contain the path to the file to check.</p>
 *
 * This function should return one of the following error codes:
 * <ul>
 *  <li>GWEN_SUCCESS: CryptToken is supported by this plugin, the buffers
 *   for typeName, subTypeName and name are updated accordingly</li>
 *  <li>GWEN_ERROR_CT_NOT_IMPLEMENTED: function not implmented</li>
 *  <li>GWEN_ERROR_CT_NOT_SUPPORTED: medium not supported by this plugin</li>
 *  <li>GWEN_ERROR_CT_BAD_NAME: Medium is supported but the name doesn't
 *      match that of the currently checked medium</li>
 *  <li>GWEN_ERROR_CT_IO_ERROR: any type of IO error occurred</li>
 *  <li>other codes as appropriate</li>
 * </ul>
 */
GWENHYWFAR_API int GWEN_Crypt_Token_Plugin_CheckToken(GWEN_PLUGIN *pl, GWEN_BUFFER *name);

GWENHYWFAR_API GWEN_CRYPT_TOKEN_DEVICE GWEN_Crypt_Token_Plugin_GetDeviceType(const GWEN_PLUGIN *pl);





/** @name CryptManager
 *
 */
/*@{*/

/**
 * This function tries to find a token plugin which is able to handle the
 * token given by the device type and name.
 */
GWENHYWFAR_API int GWEN_Crypt_Token_PluginManager_CheckToken(GWEN_PLUGIN_MANAGER *cm,
							     GWEN_CRYPT_TOKEN_DEVICE devt,
							     GWEN_BUFFER *typeName,
							     GWEN_BUFFER *tokenName,
							     uint32_t guiid);

GWENHYWFAR_API
GWEN_PLUGIN_DESCRIPTION_LIST2 *GWEN_Crypt_Token_PluginManager_GetPluginDescrs(GWEN_PLUGIN_MANAGER *pm,
									      GWEN_CRYPT_TOKEN_DEVICE devt);

/*@}*/


#ifdef __cplusplus
}
#endif



#endif


