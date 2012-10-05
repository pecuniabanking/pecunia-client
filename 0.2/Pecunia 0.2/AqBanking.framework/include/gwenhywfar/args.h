/***************************************************************************
 $RCSfile$
                             -------------------
    cvs         : $Id$
    begin       : Sat Apr 24 2004
    copyright   : (C) 2004 by Martin Preuss
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

#ifndef GWENHYWFAR_ARGS_H
#define GWENHYWFAR_ARGS_H

#include <gwenhywfar/gwenhywfarapi.h>

#ifdef __cplusplus
extern "C" {
#endif
typedef struct GWEN_ARGS GWEN_ARGS;
#ifdef __cplusplus
}
#endif

#include <gwenhywfar/types.h>
#include <gwenhywfar/buffer.h>
#include <gwenhywfar/db.h>

#ifdef __cplusplus
extern "C" {
#endif


#define GWEN_ARGS_FLAGS_HAS_ARGUMENT     0x00000001
#define GWEN_ARGS_FLAGS_LAST             0x00000002
#define GWEN_ARGS_FLAGS_HELP             0x00000004

#define GWEN_ARGS_MODE_ALLOW_FREEPARAM   0x00000001
#define GWEN_ARGS_MODE_STOP_AT_FREEPARAM 0x00000002

#define GWEN_ARGS_RESULT_ERROR (-1)
#define GWEN_ARGS_RESULT_HELP  (-2)


typedef enum {
  GWEN_ArgsType_Char=0,
  GWEN_ArgsType_Int
} GWEN_ARGS_TYPE;

typedef enum {
  GWEN_ArgsOutType_Txt=0,
  GWEN_ArgsOutType_Html
} GWEN_ARGS_OUTTYPE;


/**
 * This is one of the very few structs inside Gwenhywfar whose
 * contents are available for direct access to the the program.
 * Developer's note: Please note that any change within this struct will
 * make it necessary to increment the SO_VERSION of the library !
 */
struct GWEN_ARGS {
  uint32_t flags;
  GWEN_ARGS_TYPE type;
  const char *name;
  unsigned int minNum;
  unsigned int maxNum;
  const char *shortOption;
  const char *longOption;
  const char *shortDescription;
  const char *longDescription;
};


/**
 * This function parses the given argument list.
 * Known options are stored within the given DB under their respective name.
 * Free parameters (which are arguments without leading "-"'s) are stored in
 * the variable "params" of the given db.
 */
GWENHYWFAR_API
int GWEN_Args_Check(int argc, char **argv,
		    int startAt,
		    uint32_t mode,
		    const GWEN_ARGS *args,
		    GWEN_DB_NODE *db);

/** Print a "usage" message into the given GWEN_BUFFER @c
 * ubuf. The message lists all available options. The
 * GWEN_ARGS_OUTTYPE argument is supposed to offer either text or
 * html as output format, but currently only text is
 * implemented. */
GWENHYWFAR_API
int GWEN_Args_Usage(const GWEN_ARGS *args, GWEN_BUFFER *ubuf,
                    GWEN_ARGS_OUTTYPE ot);

/** Currently unimplemented; does nothing and returns zero. */
GWENHYWFAR_API
int GWEN_Args_ShortUsage(const GWEN_ARGS *args, GWEN_BUFFER *ubuf,
                         GWEN_ARGS_OUTTYPE ot);

#ifdef __cplusplus
}
#endif


#endif /* GWENHYWFAR_ARGS_H */



