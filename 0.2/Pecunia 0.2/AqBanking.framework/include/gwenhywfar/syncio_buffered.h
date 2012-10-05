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


#ifndef GWENHYWFAR_SYNCIO_BUFFERED_H
#define GWENHYWFAR_SYNCIO_BUFFERED_H

#include <gwenhywfar/syncio.h>
#include <gwenhywfar/buffer.h>
#include <gwenhywfar/stringlist.h>


#define GWEN_SYNCIO_BUFFERED_TYPE "buffered"



#ifdef __cplusplus
extern "C" {
#endif



GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_Buffered_new(GWEN_SYNCIO *baseIo);

GWENHYWFAR_API
int GWEN_SyncIo_Buffered_ReadLineToBuffer(GWEN_SYNCIO *sio, GWEN_BUFFER *tbuf);

GWENHYWFAR_API
int GWEN_SyncIo_Buffered_ReadLinesToStringList(GWEN_SYNCIO *sio, int maxLines, GWEN_STRINGLIST *sl);


#ifdef __cplusplus
}
#endif


#endif


