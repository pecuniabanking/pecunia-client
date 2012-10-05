/***************************************************************************
 begin       : Wed Apr 28 2010
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


#ifndef GWENHYWFAR_SYNCIO_HTTP_H
#define GWENHYWFAR_SYNCIO_HTTP_H

#include <gwenhywfar/syncio.h>
#include <gwenhywfar/db.h>


#define GWEN_SYNCIO_HTTP_TYPE "http"



#ifdef __cplusplus
extern "C" {
#endif



/** @name Constructor
 *
 */
/*@{*/
/**
 * The base GWEN_SYNCIO is expected to be of type @ref GWEN_SYNCIO_BUFFERED_TYPE
 * (see @ref GWEN_SyncIo_Buffered_new).
 */
GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_Http_new(GWEN_SYNCIO *baseIo);
/*@}*/


/** @name Get Information About Incoming HTTP Messages
 *
 */
/*@{*/

GWENHYWFAR_API GWEN_DB_NODE *GWEN_SyncIo_Http_GetDbCommandIn(const GWEN_SYNCIO *sio);
GWENHYWFAR_API GWEN_DB_NODE *GWEN_SyncIo_Http_GetDbStatusIn(const GWEN_SYNCIO *sio);
GWENHYWFAR_API GWEN_DB_NODE *GWEN_SyncIo_Http_GetDbHeaderIn(const GWEN_SYNCIO *sio);
/*@}*/



/** @name Get Information About Outgoing HTTP Messages
 *
 */
/*@{*/

GWENHYWFAR_API GWEN_DB_NODE *GWEN_SyncIo_Http_GetDbCommandOut(const GWEN_SYNCIO *sio);
GWENHYWFAR_API GWEN_DB_NODE *GWEN_SyncIo_Http_GetDbStatusOut(const GWEN_SYNCIO *sio);
GWENHYWFAR_API GWEN_DB_NODE *GWEN_SyncIo_Http_GetDbHeaderOut(const GWEN_SYNCIO *sio);
/*@}*/



GWENHYWFAR_API int GWEN_SyncIo_Http_RecvBody(GWEN_SYNCIO *sio, GWEN_BUFFER *buf);


#ifdef __cplusplus
}
#endif


#endif


