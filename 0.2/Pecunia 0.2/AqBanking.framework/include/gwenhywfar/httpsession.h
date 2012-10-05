/***************************************************************************
    begin       : Fri Feb 15 2008
    copyright   : (C) 2008-2010 by Martin Preuss
    email       : martin@libchipcard.de

 ***************************************************************************
 *          Please see toplevel file COPYING for license details           *
 ***************************************************************************/


#ifndef GWEN_HTTP_SESSION_H
#define GWEN_HTTP_SESSION_H


#include <gwenhywfar/inherit.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_HTTP_SESSION GWEN_HTTP_SESSION;
GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_HTTP_SESSION, GWENHYWFAR_API)

#ifdef __cplusplus
}
#endif


#include <gwenhywfar/url.h>
#include <gwenhywfar/buffer.h>


/**
 * This flag forces SSLv3 connections when in HTTPS mode.
 */
#define GWEN_HTTP_SESSION_FLAGS_FORCE_SSL3 0x00000001
#define GWEN_HTTP_SESSION_FLAGS_NO_CACHE   0x00000002


#ifdef __cplusplus
extern "C" {
#endif


/** @defgroup MOD_HTTP_SESSION HTTP Session
 *
 * This module provides support for exchanging a HTTP(s) request.
 */
/*@{*/

/** @name Contructor/Destructor
 *
 */
/*@{*/

GWENHYWFAR_API
GWEN_HTTP_SESSION *GWEN_HttpSession_new(const char *url, const char *defaultProto, int defaultPort);

GWENHYWFAR_API
void GWEN_HttpSession_Attach(GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
void GWEN_HttpSession_free(GWEN_HTTP_SESSION *sess);
/*@}*/



/** @name HTTP Setup Functions
 *
 * Functions of this groups should be called before @ref GWEN_HttpSession_Init
 * because the information conveyed via these functions is needed upon
 * initialisation.
 */
/*@{*/

GWENHYWFAR_API
uint32_t GWEN_HttpSession_GetFlags(const GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
void GWEN_HttpSession_SetFlags(GWEN_HTTP_SESSION *sess, uint32_t fl);

GWENHYWFAR_API
void GWEN_HttpSession_AddFlags(GWEN_HTTP_SESSION *sess, uint32_t fl);

GWENHYWFAR_API
void GWEN_HttpSession_SubFlags(GWEN_HTTP_SESSION *sess, uint32_t fl);

GWENHYWFAR_API
const char *GWEN_HttpSession_GetHttpUserAgent(const GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
void GWEN_HttpSession_SetHttpUserAgent(GWEN_HTTP_SESSION *sess, const char *s);

GWENHYWFAR_API
const char *GWEN_HttpSession_GetHttpContentType(const GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
void GWEN_HttpSession_SetHttpContentType(GWEN_HTTP_SESSION *sess, const char *s);


GWENHYWFAR_API
int GWEN_HttpSession_GetHttpVMajor(const GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
void GWEN_HttpSession_SetHttpVMajor(GWEN_HTTP_SESSION *sess, int i);

GWENHYWFAR_API
int GWEN_HttpSession_GetHttpVMinor(const GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
void GWEN_HttpSession_SetHttpVMinor(GWEN_HTTP_SESSION *sess, int i);
/*@}*/



/** @name Initialisation and Deinitialisation
 *
 */
/*@{*/
GWENHYWFAR_API
int GWEN_HttpSession_Init(GWEN_HTTP_SESSION *sess);

GWENHYWFAR_API
int GWEN_HttpSession_Fini(GWEN_HTTP_SESSION *sess);



/** @name Sending and Receiving
 *
 */
/*@{*/

/**
 * This function connects to the server and then sends the given message.
 * The buffer given as argument to this function must only contain the
 * raw data (i.e. the HTTP body, no header).
 * @param sess http session object
 * @param httpCommand HTTP command to send (e.g. "GET", "POST")
 * @param buf pointer to the http body data to send
 * @param blen size of the http body data to send (might be 0)
 * @param timeout timeout in milliseconds
 */
GWENHYWFAR_API
int GWEN_HttpSession_SendPacket(GWEN_HTTP_SESSION *sess,
				const char *httpCommand,
				const uint8_t *buf, uint32_t blen);

/**
 * This function receives a response packet from the server and closes
 * the connection. It expects the connection to be established by
 * @ref GWEN_HttpSession_SendPacket().
 */
GWENHYWFAR_API
int GWEN_HttpSession_RecvPacket(GWEN_HTTP_SESSION *sess, GWEN_BUFFER *buf);

/**
 * Test-connect to the server. This function can be used to retrieve the SSL
 * certificate from a server as the cert exchange is part of the establishing of
 * a connection.
 * This function connects to the server and immediately disconnects.
 */
GWENHYWFAR_API
int GWEN_HttpSession_ConnectionTest(GWEN_HTTP_SESSION *sess);

/*@}*/


/*@}*/ /* defgroup */


#ifdef __cplusplus
}
#endif


#endif

