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


#ifndef GWENHYWFAR_SYNCIO_H
#define GWENHYWFAR_SYNCIO_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/inherit.h>
#include <gwenhywfar/list1.h>
#include <gwenhywfar/stringlist.h>


#ifdef __cplusplus
extern "C" {
#endif



typedef struct GWEN_SYNCIO GWEN_SYNCIO;
GWEN_INHERIT_FUNCTION_LIB_DEFS(GWEN_SYNCIO, GWENHYWFAR_API)
GWEN_LIST_FUNCTION_LIB_DEFS(GWEN_SYNCIO, GWEN_SyncIo, GWENHYWFAR_API)


typedef enum {
  GWEN_SyncIo_Status_Unknown=-1,
  GWEN_SyncIo_Status_Unconnected=0,
  GWEN_SyncIo_Status_Disconnected,
  GWEN_SyncIo_Status_Connected,
  GWEN_SyncIo_Status_Disabled
} GWEN_SYNCIO_STATUS;



#define GWEN_SYNCIO_FLAGS_TRANSPARENT 0x80000000
#define GWEN_SYNCIO_FLAGS_DONTCLOSE   0x40000000
#define GWEN_SYNCIO_FLAGS_PASSIVE     0x20000000
#define GWEN_SYNCIO_FLAGS_PACKET_END  0x10000000
#define GWEN_SYNCIO_FLAGS_DOSMODE     0x08000000





GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_new(const char *typeName, GWEN_SYNCIO *baseIo);

GWENHYWFAR_API
void GWEN_SyncIo_Attach(GWEN_SYNCIO *sio);

GWENHYWFAR_API
void GWEN_SyncIo_free(GWEN_SYNCIO *sio);


GWENHYWFAR_API
int GWEN_SyncIo_Connect(GWEN_SYNCIO *sio);

GWENHYWFAR_API
int GWEN_SyncIo_Disconnect(GWEN_SYNCIO *sio);

GWENHYWFAR_API
int GWEN_SyncIo_Flush(GWEN_SYNCIO *sio);


GWENHYWFAR_API
int GWEN_SyncIo_Read(GWEN_SYNCIO *sio,
		     uint8_t *buffer,
		     uint32_t size);



GWENHYWFAR_API
int GWEN_SyncIo_Write(GWEN_SYNCIO *sio,
		      const uint8_t *buffer,
		      uint32_t size);

GWENHYWFAR_API
uint32_t GWEN_SyncIo_GetFlags(const GWEN_SYNCIO *sio);

GWENHYWFAR_API
void GWEN_SyncIo_SetFlags(GWEN_SYNCIO *sio, uint32_t fl);

GWENHYWFAR_API
void GWEN_SyncIo_AddFlags(GWEN_SYNCIO *sio, uint32_t fl);

GWENHYWFAR_API
void GWEN_SyncIo_SubFlags(GWEN_SYNCIO *sio, uint32_t fl);


GWENHYWFAR_API
GWEN_SYNCIO_STATUS GWEN_SyncIo_GetStatus(const GWEN_SYNCIO *sio);

GWENHYWFAR_API
void GWEN_SyncIo_SetStatus(GWEN_SYNCIO *sio, GWEN_SYNCIO_STATUS st);


GWENHYWFAR_API
const char *GWEN_SyncIo_GetTypeName(const GWEN_SYNCIO *sio);


GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_GetBaseIo(const GWEN_SYNCIO *sio);

GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_GetBaseIoByTypeName(const GWEN_SYNCIO *sio, const char *typeName);



GWENHYWFAR_API
int GWEN_SyncIo_WriteForced(GWEN_SYNCIO *sio,
			    const uint8_t *buffer,
			    uint32_t size);


GWENHYWFAR_API
int GWEN_SyncIo_ReadForced(GWEN_SYNCIO *sio,
			   uint8_t *buffer,
			   uint32_t size);



/**
 * This is just a convenience function to easily replace a function from
 * the deprecated module GWEN_BUFFEREDIO.
 */
GWENHYWFAR_API
int GWEN_SyncIo_WriteString(GWEN_SYNCIO *sio, const char *s);

GWENHYWFAR_API
int GWEN_SyncIo_WriteLine(GWEN_SYNCIO *sio, const char *s);

GWENHYWFAR_API
int GWEN_SyncIo_WriteChar(GWEN_SYNCIO *sio, char s);


GWENHYWFAR_API
int GWEN_SyncIo_Helper_ReadFileToStringList(const char *fname,
					    int maxLines,
					    GWEN_STRINGLIST *sl);




/** @name Declarations for Virtual Functions
 *
 */
/*@{*/
typedef GWENHYWFAR_CB int (*GWEN_SYNCIO_CONNECT_FN)(GWEN_SYNCIO *sio);
typedef GWENHYWFAR_CB int (*GWEN_SYNCIO_DISCONNECT_FN)(GWEN_SYNCIO *sio);
typedef GWENHYWFAR_CB int (*GWEN_SYNCIO_FLUSH_FN)(GWEN_SYNCIO *sio);


typedef GWENHYWFAR_CB int (*GWEN_SYNCIO_READ_FN)(GWEN_SYNCIO *sio,
						 uint8_t *buffer,
						 uint32_t size);



typedef GWENHYWFAR_CB int (*GWEN_SYNCIO_WRITE_FN)(GWEN_SYNCIO *sio,
						  const uint8_t *buffer,
						  uint32_t size);
/*@}*/



/** @name Setters for Virtual Functions
 *
 */
/*@{*/
GWENHYWFAR_API
GWEN_SYNCIO_CONNECT_FN GWEN_SyncIo_SetConnectFn(GWEN_SYNCIO *sio, GWEN_SYNCIO_CONNECT_FN fn);

GWENHYWFAR_API
GWEN_SYNCIO_DISCONNECT_FN GWEN_SyncIo_SetDisconnectFn(GWEN_SYNCIO *sio, GWEN_SYNCIO_DISCONNECT_FN fn);

GWENHYWFAR_API
GWEN_SYNCIO_FLUSH_FN GWEN_SyncIo_SetFlushFn(GWEN_SYNCIO *sio, GWEN_SYNCIO_FLUSH_FN fn);

GWENHYWFAR_API
GWEN_SYNCIO_READ_FN GWEN_SyncIo_SetReadFn(GWEN_SYNCIO *sio, GWEN_SYNCIO_READ_FN fn);

GWENHYWFAR_API
GWEN_SYNCIO_WRITE_FN GWEN_SyncIo_SetWriteFn(GWEN_SYNCIO *sio, GWEN_SYNCIO_WRITE_FN fn);
/*@}*/


#ifdef __cplusplus
}
#endif



#endif


