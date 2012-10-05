/***************************************************************************
 begin       : Tue Apr 27 2010
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


#ifndef GWENHYWFAR_SYNCIO_SOCKET_H
#define GWENHYWFAR_SYNCIO_SOCKET_H

#include <gwenhywfar/syncio.h>
#include <gwenhywfar/inetsocket.h>


#define GWEN_SYNCIO_SOCKET_TYPE "socket"



#ifdef __cplusplus
extern "C" {
#endif



GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_Socket_new(GWEN_SOCKETTYPE sockType,
				    GWEN_AddressFamily addressFamily);

GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_Socket_TakeOver(GWEN_SOCKET *socket);

GWENHYWFAR_API
const char *GWEN_SyncIo_Socket_GetAddress(const GWEN_SYNCIO *sio);

GWENHYWFAR_API
void GWEN_SyncIo_Socket_SetAddress(GWEN_SYNCIO *sio, const char *s);

GWENHYWFAR_API
int GWEN_SyncIo_Socket_GetPort(const GWEN_SYNCIO *sio);


GWENHYWFAR_API
void GWEN_SyncIo_Socket_SetPort(GWEN_SYNCIO *sio, int i);


#ifdef __cplusplus
}
#endif


#endif


