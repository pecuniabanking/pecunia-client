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


#ifndef GWENHYWFAR_SYNCIO_MEMORY_H
#define GWENHYWFAR_SYNCIO_MEMORY_H

#include <gwenhywfar/syncio.h>
#include <gwenhywfar/buffer.h>


#define GWEN_SYNCIO_MEMORY_TYPE "memory"



#ifdef __cplusplus
extern "C" {
#endif



GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_Memory_new(GWEN_BUFFER *buffer, int take);

GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_Memory_fromBuffer(const uint8_t *buffer, int size);


GWENHYWFAR_API
GWEN_BUFFER *GWEN_SyncIo_Memory_GetBuffer(const GWEN_SYNCIO *sio);

GWENHYWFAR_API
GWEN_BUFFER *GWEN_SyncIo_Memory_TakeBuffer(const GWEN_SYNCIO *sio);


#ifdef __cplusplus
}
#endif


#endif


