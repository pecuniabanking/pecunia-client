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
 * @file base/error.h
 * @short This file contains the module for error handling.
 */

#ifndef GWENHYWFAR_ERROR_H
#define GWENHYWFAR_ERROR_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>


/**
 * @defgroup MOD_ERROR Error module
 * @ingroup MOD_BASE
 * @short This module does all error handling
 * @author Martin Preuss<martin@libchipcard.de>
 *
 */
/*@{*/

/*
 * Allow this to be used from C and C++
 */
#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup MOD_ERROR_SIMPLE Simplified Error Codes
 *
 */
/*@{*/
#define GWEN_SUCCESS 0
/* generic errors */
#define GWEN_ERROR_GENERIC              (-1)
#define GWEN_ERROR_ABORTED              (-2)
#define GWEN_ERROR_NOT_AVAILABLE        (-3)
#define GWEN_ERROR_USER_ABORTED         (-4)
#define GWEN_ERROR_OPEN                 (-5)
#define GWEN_ERROR_INVALID              (-6)
/* socket errors */
#define GWEN_ERROR_BAD_SOCKETTYPE       (-32)
#define GWEN_ERROR_NOT_OPEN             (-33)
#define GWEN_ERROR_TIMEOUT              (-34)
#define GWEN_ERROR_IN_PROGRESS          (-35)
#define GWEN_ERROR_STARTUP              (-36)
#define GWEN_ERROR_INTERRUPTED          (-37)
#define GWEN_ERROR_BROKEN_PIPE          (-39)
/* inet address errors */
#define GWEN_ERROR_MEMORY_FULL          (-40)
#define GWEN_ERROR_BAD_ADDRESS          (-41)
#define GWEN_ERROR_BUFFER_OVERFLOW      (-42)
#define GWEN_ERROR_HOST_NOT_FOUND       (-43)
#define GWEN_ERROR_NO_ADDRESS           (-44)
#define GWEN_ERROR_NO_RECOVERY          (-45)
#define GWEN_ERROR_TRY_AGAIN            (-46)
#define GWEN_ERROR_UNKNOWN_DNS_ERROR    (-47)
#define GWEN_ERROR_BAD_ADDRESS_FAMILY   (-48)
/* libloader errors */
#define GWEN_ERROR_COULD_NOT_LOAD       (-49)
#define GWEN_ERROR_COULD_NOT_RESOLVE    (-50)
#define GWEN_ERROR_NOT_FOUND            (-51)
/* buffered IO errors */
#define GWEN_ERROR_READ                 (-52)
#define GWEN_ERROR_WRITE                (-53)
#define GWEN_ERROR_CLOSE                (-54)
#define GWEN_ERROR_NO_DATA              (-55)
#define GWEN_ERROR_PARTIAL              (-56)
#define GWEN_ERROR_EOF                  (-57)
/* crypt errors */
#define GWEN_ERROR_ALREADY_REGISTERED   (-58)
#define GWEN_ERROR_NOT_REGISTERED       (-59)
#define GWEN_ERROR_BAD_SIZE             (-60)
#define GWEN_ERROR_ENCRYPT              (-62)
#define GWEN_ERROR_DECRYPT              (-63)
#define GWEN_ERROR_SIGN                 (-64)
#define GWEN_ERROR_VERIFY               (-65)
#define GWEN_ERROR_SSL                  (-66)

/* crypt token errors */
#define GWEN_ERROR_NOT_IMPLEMENTED      (-67)
#define GWEN_ERROR_NOT_SUPPORTED        (-68)
#define GWEN_ERROR_BAD_NAME             (-69)
#define GWEN_ERROR_BAD_PIN              (-70)
#define GWEN_ERROR_BAD_PIN_0_LEFT       (-71)
#define GWEN_ERROR_BAD_PIN_1_LEFT       (-72)
#define GWEN_ERROR_BAD_PIN_2_LEFT       (-73)
#define GWEN_ERROR_NO_KEY               (-74)
#define GWEN_ERROR_REMOVED              (-75)
#define GWEN_ERROR_DEFAULT_VALUE        (-76)

/* new error codes in GWEN2 */
#define GWEN_ERROR_NOT_CONNECTED        (-100)
#define GWEN_ERROR_BAD_DATA             (-101)
#define GWEN_ERROR_FOUND                (-102)
#define GWEN_ERROR_IO                   (-103)

#define GWEN_ERROR_INTERNAL             (-104)
#define GWEN_ERROR_PERMISSIONS          (-105)
#define GWEN_ERROR_CONN_REFUSED         (-106)
#define GWEN_ERROR_NET_UNREACHABLE      (-107)
#define GWEN_ERROR_SSL_SECURITY         (-108)

#define GWEN_ERROR_LOCK                 (-109)


#define GWEN_ERROR_USEROFFSET           (-1000)



/*@}*/


/**
 * @name Verbosity
 *
 * Composing error messages.
 */
/*@{*/
/**
 * Dumps the string corresponding to the given erro code.
 * @return 1 detailed error message created, 0 otherwise
 * @param c error code
 * @param buffer pointer to a buffer to receive the message
 * @param bsize size of that buffer in bytes
 */
GWENHYWFAR_API int GWEN_Error_ToString(int c, char *buffer, int bsize);
/*@}*/


/*@}*/

#ifdef __cplusplus
}
#endif

/*@} group mod_error */


#endif /* MOD_ERROR_H */


