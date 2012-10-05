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


#ifndef GWENHYWFAR_SYNCIO_FILE_H
#define GWENHYWFAR_SYNCIO_FILE_H

#include <gwenhywfar/syncio.h>


#define GWEN_SYNCIO_FILE_TYPE "file"



typedef enum {
  GWEN_SyncIo_File_CreationMode_Unknown=-1,
  GWEN_SyncIo_File_CreationMode_OpenExisting=0,
  GWEN_SyncIo_File_CreationMode_CreateNew,
  GWEN_SyncIo_File_CreationMode_CreateAlways,
  GWEN_SyncIo_File_CreationMode_OpenAlways,
  GWEN_SyncIo_File_CreationMode_TruncateExisting
} GWEN_SYNCIO_FILE_CREATIONMODE;


typedef enum {
  GWEN_SyncIo_File_Whence_Set=0,
  GWEN_SyncIo_File_Whence_Current,
  GWEN_SyncIo_File_Whence_End
} GWEN_SYNCIO_FILE_WHENCE;


#define GWEN_SYNCIO_FILE_FLAGS_READ   0x00000001
#define GWEN_SYNCIO_FILE_FLAGS_WRITE  0x00000002
#define GWEN_SYNCIO_FILE_FLAGS_APPEND 0x00000008
#define GWEN_SYNCIO_FILE_FLAGS_RANDOM 0x00000010

#define GWEN_SYNCIO_FILE_FLAGS_UREAD  0x00000100
#define GWEN_SYNCIO_FILE_FLAGS_UWRITE 0x00000200
#define GWEN_SYNCIO_FILE_FLAGS_UEXEC  0x00000400

#define GWEN_SYNCIO_FILE_FLAGS_GREAD  0x00001000
#define GWEN_SYNCIO_FILE_FLAGS_GWRITE 0x00002000
#define GWEN_SYNCIO_FILE_FLAGS_GEXEC  0x00004000

#define GWEN_SYNCIO_FILE_FLAGS_OREAD  0x00010000
#define GWEN_SYNCIO_FILE_FLAGS_OWRITE 0x00020000
#define GWEN_SYNCIO_FILE_FLAGS_OEXEC  0x00040000



#ifdef __cplusplus
extern "C" {
#endif



GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_File_new(const char *path, GWEN_SYNCIO_FILE_CREATIONMODE cm);


GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_File_fromStdin();

GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_File_fromStdout();

GWENHYWFAR_API
GWEN_SYNCIO *GWEN_SyncIo_File_fromStderr();

GWENHYWFAR_API
const char *GWEN_SyncIo_File_GetPath(const GWEN_SYNCIO *sio);

GWENHYWFAR_API
int64_t GWEN_SyncIo_File_Seek(GWEN_SYNCIO *sio, int64_t pos, GWEN_SYNCIO_FILE_WHENCE whence);


#ifdef __cplusplus
}
#endif


#endif


