/***************************************************************************
    begin       : Mon Mar 01 2004
    copyright   : (C) 2004-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 * This file is part of the project "AqBanking".                           *
 * Please see toplevel file COPYING of that project for license details.   *
 ***************************************************************************/


#ifndef AB_HTTPSESS_H
#define AB_HTTPSESS_H

#include <aqbanking/user.h>
#include <aqbanking/provider.h>

#include <gwenhywfar/httpsession.h>


/** @defgroup G_AB_PROVIDER_HTTPSESS HTTP Session Management
 * @ingroup G_AB_BE_INTERFACE
 *
 * Functions in this group provide a HTTP session management. This can be
 * used by backends which use the SSL transport protocol.
 */
/*@{*/


/** @name Constructor/Destructor
 *
 */
/*@{*/
AQBANKING_API 
GWEN_HTTP_SESSION *AB_HttpSession_new(AB_PROVIDER *pro, AB_USER *u,
				      const char *url,
				      const char *defaultProto,
				      int defaultPort);

/*@}*/



/** @name Getters for Related Objects
 *
 */
/*@{*/
AQBANKING_API 
AB_USER *AB_HttpSession_GetUser(const GWEN_HTTP_SESSION *sess);

AQBANKING_API 
AB_PROVIDER *AB_HttpSession_GetProvider(const GWEN_HTTP_SESSION *sess);

AQBANKING_API 
void Ab_HttpSession_AddLog(GWEN_HTTP_SESSION *sess,
			   const char *s);

AQBANKING_API
const char *AB_HttpSession_GetLog(const GWEN_HTTP_SESSION *sess);

AQBANKING_API 
void AB_HttpSession_ClearLog(GWEN_HTTP_SESSION *sess);



/*@}*/


/*@}*/ /* defgroup */



#endif

