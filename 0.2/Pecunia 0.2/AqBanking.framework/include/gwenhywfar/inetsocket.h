/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Tue Oct 02 2002
    copyright   : (C) 2002 by Martin Preuss
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

/**
 * @file inetsocket.h
 * @short This file contains sockets and socket sets.
 */

#ifndef GWEN_SOCKET_H
#define GWEN_SOCKET_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/error.h>
#include <gwenhywfar/inetaddr.h>
#include <gwenhywfar/list1.h>
#include <gwenhywfar/list2.h>


typedef struct GWEN_SOCKET GWEN_SOCKET;
typedef struct GWEN_SOCKETSETSTRUCT GWEN_SOCKETSET;

GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_SOCKET, GWEN_Socket, GWENHYWFAR_API)
GWEN_LIST2_FUNCTION_LIB_DEFS(GWEN_SOCKET, GWEN_Socket, GWENHYWFAR_API)


#ifdef __cplusplus
extern "C" {
#endif


/**
 * @defgroup MOD_SOCKETSANDSETS Sockets and Socket Sets
 * @ingroup MOD_OS
 *
 * This module handles sockets and socket sets.
 * @{
 */

/** @name Error Codes */
/*@{*/
#define GWEN_SOCKET_ERROR_TYPE "Socket"
#define GWEN_SOCKET_ERROR_BAD_SOCKETTYPE (-1)
#define GWEN_SOCKET_ERROR_NOT_OPEN       (-2)
#define GWEN_SOCKET_ERROR_TIMEOUT        (-3)
#define GWEN_SOCKET_ERROR_IN_PROGRESS    (-4)
#define GWEN_SOCKET_ERROR_STARTUP        (-5)
#define GWEN_SOCKET_ERROR_INTERRUPTED    (-6)
#define GWEN_SOCKET_ERROR_UNSUPPORTED    (-7)
#define GWEN_SOCKET_ERROR_ABORTED        (-8)
#define GWEN_SOCKET_ERROR_BROKEN_PIPE    (-9)
/*@}*/


/**
 * Socket types
 */
typedef enum {
  GWEN_SocketTypeTCP=1,
  GWEN_SocketTypeUDP,
  GWEN_SocketTypeRAW,
  GWEN_SocketTypeUnix,
  GWEN_SocketTypeFile
} GWEN_SOCKETTYPE;



/**
 * @defgroup MOD_SOCKETSET Socket Set Functions
 *
 * These functions operate on socket sets. A socket set is used by the socket
 * function @ref GWEN_Socket_Select() to check on which socket changes in state
 * occurred.
 * @{
 */

/**
 * @name Creation and destruction
 *
 * These functions initialize and de-initialize socket sets.
 * A socket set is a group of sockets. They are used for the function
 * @ref GWEN_Socket_Select.
 */
/*@{*/
GWENHYWFAR_API GWEN_SOCKETSET *GWEN_SocketSet_new();
GWENHYWFAR_API void GWEN_SocketSet_free(GWEN_SOCKETSET *ssp);
GWENHYWFAR_API int GWEN_SocketSet_Clear(GWEN_SOCKETSET *ssp);
/*@}*/

/**
 * @name Add, remove, check sockets
 *
 * These functions allow adding and removing sockets to/from a socket set
 * as well as checking whether a specific socket is part of a socket set.
 */
/*@{*/
GWENHYWFAR_API
  int GWEN_SocketSet_AddSocket(GWEN_SOCKETSET *ssp,
			       const GWEN_SOCKET *sp);
GWENHYWFAR_API
  int GWEN_SocketSet_RemoveSocket(GWEN_SOCKETSET *ssp,
                                             const GWEN_SOCKET *sp);
GWENHYWFAR_API int GWEN_SocketSet_HasSocket(GWEN_SOCKETSET *ssp,
                                            const GWEN_SOCKET *sp);
GWENHYWFAR_API int GWEN_SocketSet_GetSocketCount(GWEN_SOCKETSET *ssp);

/*@}*/
/*end of group socketset */
/*@}*/


/**
 * @defgroup MOD_SOCKET Socket Functions
 *
 * This group operates on IP sockets.
 * @{
 */

/**
 * @name Creation and Destruction
 */
/*@{*/

/**
 * Constructor. You should always use this to create socket variables.
 */
GWENHYWFAR_API GWEN_SOCKET *GWEN_Socket_new(GWEN_SOCKETTYPE socketType);

GWENHYWFAR_API GWEN_SOCKET *GWEN_Socket_fromFile(int fd);

/**
 * Destructor.
 */
GWENHYWFAR_API void GWEN_Socket_free(GWEN_SOCKET *sp);

/**
 * Arms the socket so that it can be used. This really creates a system
 * socket.
 */
GWENHYWFAR_API int GWEN_Socket_Open(GWEN_SOCKET *sp);

/**
 * Unarms a socket thus closing any connection associated with this socket.
 */
GWENHYWFAR_API int GWEN_Socket_Close(GWEN_SOCKET *sp);
/*@}*/

/**
 * @name Connecting and Disconnecting
 *
 * These functions allow active and passive connections to other hosts.
 */
/*@{*/
GWENHYWFAR_API
int GWEN_Socket_Connect(GWEN_SOCKET *sp, const GWEN_INETADDRESS *addr);

GWENHYWFAR_API
int GWEN_Socket_Bind(GWEN_SOCKET *sp, const GWEN_INETADDRESS *addr);

GWENHYWFAR_API int GWEN_Socket_Listen(GWEN_SOCKET *sp, int backlog);

/**
 * This accepts a new connection on the given socket. This socket must be
 * listening (achieved by calling @ref GWEN_Socket_Listen).
 * @param sp socket which is listening
 * @param addr pointer to a pointer to an address. Upon return this pointer
 * will point to a newly allocated address containing the address of the
 * connected peer.
 * Please note that if upon return this value is !=NULL then you are
 * responsible for freeing this address !
 * @param newsock pointer to a pointer to a socket. Upon return this holds
 * the pointer to a newly allocated socket.
 * Please note that if upon return this value is !=NULL then you are
 * responsible for freeing this socket !
 */
GWENHYWFAR_API
int GWEN_Socket_Accept(GWEN_SOCKET *sp,
		       GWEN_INETADDRESS **addr,
		       GWEN_SOCKET **newsock);

/*@}*/

/**
 * @name Informational Functions
 *
 * These functions return some usefull information about sockets or
 * connections.
 */
/*@{*/

/**
 * Returns the socket type.
 * @param sp socket
 */
GWENHYWFAR_API GWEN_SOCKETTYPE GWEN_Socket_GetSocketType(GWEN_SOCKET *sp);


/**
 * Retrieves the peer's address
 * @param sp socket
 * @param addr pointer to a pointer to an @ref GWEN_INETADDRESS.
 * Upon successful return that pointer will point to the address of the
 * peer. In that case the caller is responsible for freeing that address.
 */
GWENHYWFAR_API
  int GWEN_Socket_GetPeerAddr(GWEN_SOCKET *sp,
                                         GWEN_INETADDRESS **addr);

/**
 * This function waits for a group of sockets to change their state.
 * @param rs socket set, wait for readability of those sockets
 * @param ws socket set, wait for writeability of those sockets
 * @param xs socket set, wait for "exceptional events" on those sockets
 * @param timeout time to wait in milliseconds. If <0 then this function
 * will wait forever, if ==0 then it won't wait at all.
 */
GWENHYWFAR_API
  int GWEN_Socket_Select(GWEN_SOCKETSET *rs,
			 GWEN_SOCKETSET *ws,
			 GWEN_SOCKETSET *xs,
			 int timeout);

/**
 * Wait until the given socket becomes readable or a timeout occurrs.
 * @param sp socket
 * @param timeout please see @ref GWEN_Socket_Select for details
 */
GWENHYWFAR_API
  int GWEN_Socket_WaitForRead(GWEN_SOCKET *sp, int timeout);

/**
 * Wait until the given socket becomes writeable or a timeout occurrs.
 * @param sp socket
 * @param timeout please see @ref GWEN_Socket_Select for details
 */
GWENHYWFAR_API
  int GWEN_Socket_WaitForWrite(GWEN_SOCKET *sp, int timeout);
/*@}*/

/**
 * @name Data Exchange Functions
 *
 * These functions handle exchange of data with other hosts via the Internet
 * Protocol.
 */
/*@{*/

/**
 * Read bytes from a socket.
 * This function might return GWEN_ERROR_INTERRUPTED in case the read request was interrupted by a
 * posix signal or GWEN_ERROR_TIMEOUT on non-blocking sockets which have currently no data available.
 * @param sp socket
 * @param buffer pointer to the buffer to receive the data
 * @param bsize pointer to an integer variable. Upon call this should hold
 * the number of bytes to read, upon return it will contain the number of
 * bytes actually read.
 */
GWENHYWFAR_API int GWEN_Socket_Read(GWEN_SOCKET *sp,
                                               char *buffer,
                                               int *bsize);

/**
 * Write bytes to an open socket.
 * @param sp socket
 * @param buffer pointer to a buffer containing the bytes to be written
 * @param bsize pointer to an integer variable containing the number of bytes
 * to write. Upon return this variable holds the number of bytes actually
 * written. Please note that this function may write less bytes than expected!
 */
GWENHYWFAR_API int GWEN_Socket_Write(GWEN_SOCKET *sp,
				     const char *buffer,
				     int *bsize);

/**
 * Reads bytes from an UDP socket, which is connectionless.
 * @param sp socket
 * @param addr pointer to pointer to an address to receive the address of the
 * peer we have received data from.
 * Please note that if upon return this value is !=NULL then you are
 * responsible for freeing this address !
 * @param buffer pointer to a buffer to store the received data in
 * @param bsize pointer to an integer variable. Upon call this should hold
 * the number of bytes to read, upon return it will contain the number of
 * bytes actually read.
 */
GWENHYWFAR_API
  int GWEN_Socket_ReadFrom(GWEN_SOCKET *sp,
			   GWEN_INETADDRESS **addr,
			   char *buffer,
			   int *bsize);
/**
 * Writes data to an UDP socket, which is connectionless.
 * @param sp socket
 * @param addr pointer to the address struct specifying the recipient
 * @param buffer pointer to a buffer containing the bytes to be written
 * @param bsize pointer to an integer variable containing the number of bytes
 * to write. Upon return this variable holds the number of bytes actually
 * written. Please note that this function may write less bytes than expected!
  */
GWENHYWFAR_API
  int GWEN_Socket_WriteTo(GWEN_SOCKET *sp,
			  const GWEN_INETADDRESS *addr,
			  const char *buffer,
			  int *bsize);
/*@}*/

/**
 * @name Socket Settings Functions
 *
 * These functions manipulate settings on a socket.
 */
/*@{*/
/**
 * Toggles the sockets blocking/non-blocking mode.
 * @param sp socket
 * @param fl if 0 then nonblocking is requested, otherwise blocking is assumed
 */
GWENHYWFAR_API int GWEN_Socket_SetBlocking(GWEN_SOCKET *sp, int fl);
/**
 * Toggles the sockets broadcast/non-broadcast mode.
 * If in broadcast mode (for UDP sockets only) the socket is able to receive
 * packets that have been sent to a broadcast address, otherwise those
 * packets are ignored.
 * @param sp socket
 * @param fl if nonzero then broadcast is enabled
 */
GWENHYWFAR_API int GWEN_Socket_SetBroadcast(GWEN_SOCKET *sp, int fl);

/**
 * Returns a pending socket error. This is used when trying to connect to
 * a server when in non-blocking mode. In this case the connect call will
 * in some cases return with an error code indicating that the connect is in
 * progress. Later you will then need to find out whether that connect
 * succeeded or not. And this is the function which can tell you that ;-)
 * @param sp socket
 */
GWENHYWFAR_API int GWEN_Socket_GetSocketError(GWEN_SOCKET *sp);

/**
 * Normally after closing a socket the occupied TCP/UDP port will be
 * unavailable for another call to the system function bind (2).
 * If reusing is allowed then this latency is removed. This function is
 * usefull for servers.
 * @param sp socket
 * @param fl if nonzero then reusing the address is enabled
 */
GWENHYWFAR_API
  int GWEN_Socket_SetReuseAddress(GWEN_SOCKET *sp, int fl);
/*@}*/


/**
 * This function should only be used if it is absolutely necessary,
 * because it might not be supported by every system.
 * Hoever, it is currently supported by all systems on which the
 * Berkeley Socket API is used (e.g. most if not all POSIX systems,
 * in this implementation also WIN32).
 * What you can do with the value returned depends very much on the
 * underlying operating system. For POSIX systems the value returned
 * is just a file handle as returned by e.g. socket().
 */
GWENHYWFAR_API
int GWEN_Socket_GetSocketInt(const GWEN_SOCKET *sp);

/* end of group socket */
/*@}*/

/* end of group socketsandsets */
/*@}*/

#ifdef __cplusplus
}
#endif

#endif /* GWEN_SOCKET_H */



