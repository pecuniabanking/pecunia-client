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
 * @file inetaddr.h
 * @short This file contains the internet address handling module
 */

#ifndef GWEN_INETADDR_H
#define GWEN_INETADDR_H


#include <gwenhywfar/gwenhywfarapi.h>
#include "gwenhywfar/error.h"

#ifdef __cplusplus
extern "C" {
#endif


/**
 * @defgroup MOD_INETADDR Internet Address Module
 * @ingroup MOD_OS
 * @short This module handles internet addresses
 *
 * This module allows using of internet IP addresses. It is also capable of
 * resolving addresses and hostnames.
 * @author Martin Preuss<martin@libchipcard.de>
 */
/*@{*/

/** @name Error Codes */
/*@{*/
#define GWEN_INETADDR_ERROR_TYPE "InetAddr"
#define GWEN_INETADDR_ERROR_MEMORY_FULL          1
#define GWEN_INETADDR_ERROR_BAD_ADDRESS          2
#define GWEN_INETADDR_ERROR_BUFFER_OVERFLOW      3
#define GWEN_INETADDR_ERROR_HOST_NOT_FOUND       4
#define GWEN_INETADDR_ERROR_NO_ADDRESS           5
#define GWEN_INETADDR_ERROR_NO_RECOVERY          6
#define GWEN_INETADDR_ERROR_TRY_AGAIN            7
#define GWEN_INETADDR_ERROR_UNKNOWN_DNS_ERROR    8
#define GWEN_INETADDR_ERROR_BAD_ADDRESS_FAMILY   9
#define GWEN_INETADDR_ERROR_UNSUPPORTED          10
/*@}*/

/** @name Capabilities of this module
 *
 */
/*@{*/
#define GWEN_INETADDR_CAPS_AF_TCP  0x00000001
#define GWEN_INETADDR_CAPS_AF_UNIX 0x00000002

GWENHYWFAR_API uint32_t GWEN_InetAddr_GetCapabilities();
/*@}*/


/**
 * Address family (in most cases this is AddressFamilyIP)
 */
typedef enum {
  /** Internet Protocol (IP) */
  GWEN_AddressFamilyIP=0,
  /* Unix Domain Socket */
  GWEN_AddressFamilyUnix
} GWEN_AddressFamily;


/**
 * You shoukd treat this type as opaque. Its members are not part of the API,
 * i.e. they are subject to changes without notice !
 */
typedef struct GWEN_INETADDRESSSTRUCT GWEN_INETADDRESS;


/**
 * @name Construction and destruction
 *
 * These functions allocate and free administrative data about IP addresses.
 */
/*@{*/

GWENHYWFAR_API GWEN_INETADDRESS *GWEN_InetAddr_new(GWEN_AddressFamily af);
GWENHYWFAR_API void GWEN_InetAddr_free(GWEN_INETADDRESS *ia);
GWENHYWFAR_API GWEN_INETADDRESS *GWEN_InetAddr_dup(const GWEN_INETADDRESS *ia);

/*@}*/


/**
 * @name Get and set address
 *
 * These functions allow getting and setting of IP addresses either by
 * hostname or host address.
 */
/*@{*/

/**
 * Sets the IP address.
 * @return error code
 * @param ia INETADDRESS to manipulate
 * @param addr IP address in 3-dot-notation ("1.2.3.4")
 */
GWENHYWFAR_API int GWEN_InetAddr_SetAddress(GWEN_INETADDRESS *ia, const char *addr);

/**
 * Sets the IP name and resolves its address.
 * @return error code
 * @param ia INETADDRESS to manipulate
 * @param name hostname whose address is to be resolved in 3-dot-notation
 */
GWENHYWFAR_API int GWEN_InetAddr_SetName(GWEN_INETADDRESS *ia, const char *name);

/**
 * Gets the IP address stored in the INETADDRESS.
 * @return error code
 * @param ia INETADDRESS to use
 * @param buffer pointer to a buffer to receive the address
 * @param bsize size of the buffer in bytes
 */
GWENHYWFAR_API
  int GWEN_InetAddr_GetAddress(const GWEN_INETADDRESS *ia,
                                          char *buffer, unsigned int bsize);

/**
 * Gets the host name stored in the INETADDRESS. If there is none, then the
 * IP address stored in the INETADDRESS will be used to resolve the hostname.
 * @return error code
 * @param ia INETADDRESS to use
 * @param buffer pointer to a buffer to receive the name
 * @param bsize size of the buffer in bytes
 */
GWENHYWFAR_API
  int GWEN_InetAddr_GetName(const GWEN_INETADDRESS *ia,
                                       char *buffer, unsigned int bsize);
/*@}*/

/**
 * @name Get and set port
 *
 * These functions allow getting and setting of the port.
 */
/*@{*/

/**
 * Return the port stored in the INETADDRESS
 * @param ia INETADDRESS to use
 */
GWENHYWFAR_API int GWEN_InetAddr_GetPort(const GWEN_INETADDRESS *ia);

/**
 * Set the port in the given INETADDRESS.
 * @return error code
 * @param ia INETADDRESS to manipulate
 * @param port port to set (0-65535)
 */
GWENHYWFAR_API int GWEN_InetAddr_SetPort(GWEN_INETADDRESS *ia,
					 int port);
/*@}*/



#ifdef __cplusplus
}
#endif

/*@} defgroup */


#endif /* GWEN_INETADDR_H */




