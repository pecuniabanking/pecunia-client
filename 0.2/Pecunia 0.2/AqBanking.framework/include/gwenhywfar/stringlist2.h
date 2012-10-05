/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Thu Apr 03 2003
 copyright   : (C) 2003 by Martin Preuss
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

#ifndef GWENHYWFAR_STRINGLIST2_H
#define GWENHYWFAR_STRINGLIST2_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/stringlist.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/refptr.h>
#include <gwenhywfar/list.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GWEN_STRINGLIST2 GWEN_STRINGLIST2;
typedef GWEN_LIST_ITERATOR GWEN_STRINGLIST2_ITERATOR;


typedef enum {
  GWEN_StringList2_IntertMode_AlwaysAdd=0,
  GWEN_StringList2_IntertMode_NoDouble,
  GWEN_StringList2_IntertMode_Reuse
} GWEN_STRINGLIST2_INSERTMODE;


GWENHYWFAR_API
GWEN_STRINGLIST2 *GWEN_StringList2_new();
GWENHYWFAR_API
void GWEN_StringList2_free(GWEN_STRINGLIST2 *sl2);
GWENHYWFAR_API
GWEN_STRINGLIST2 *GWEN_StringList2_dup(GWEN_STRINGLIST2 *sl2);


/**
 * Normally this group of functions ignores cases when comparing two strings.
 * You can change this behaviour here.
 * @param sl2 string list
 * @param i if 0 then cases are ignored
 */
GWENHYWFAR_API
void GWEN_StringList2_SetSenseCase(GWEN_STRINGLIST2 *sl2, int i);

/**
 * Normally this group of functions ignores reference counters on stringlist
 * entries when removing a string via @ref GWEN_StringList2_RemoveString.
 * You can change this behaviour here.
 * @param sl2 string list
 * @param i if 0 then reference counters are honoured
 */
GWENHYWFAR_API
void GWEN_StringList2_SetIgnoreRefCount(GWEN_STRINGLIST2 *sl2, int i);

/**
 * Appends a string.
 * @return 0 if not appended, !=0 if appended
 * @param take if true then the StringList takes over ownership of the string
 * @param checkDouble if true the the string will only be appended if it
 * does not already exist
 */
GWENHYWFAR_API
int GWEN_StringList2_AppendString(GWEN_STRINGLIST2 *sl2,
                                  const char *s,
                                  int take,
                                  GWEN_STRINGLIST2_INSERTMODE m);

/**
 * Inserts a string.
 * @return 0 if not inserted, !=0 if inserted
 * @param take if true then the StringList takes over ownership of the string
 * @param checkDouble if true the the string will only be appended if it
 * does not already exist
 */
GWENHYWFAR_API
int GWEN_StringList2_InsertString(GWEN_STRINGLIST2 *sl2,
                                  const char *s,
                                  int take,
                                  GWEN_STRINGLIST2_INSERTMODE m);

/**
 * Removes a given string from the stringlist.
 * @return 0 if not found, !=0 if found and removed
 */
GWENHYWFAR_API int GWEN_StringList2_RemoveString(GWEN_STRINGLIST2 *sl2,
                                                const char *s);

/**
 * Checks whether the given string already exists within in the
 * string list.
 * @return !=0 if found, 0 otherwise
 */
GWENHYWFAR_API int GWEN_StringList2_HasString(const GWEN_STRINGLIST2 *sl2,
                                             const char *s);




GWENHYWFAR_API
GWEN_STRINGLIST2_ITERATOR *GWEN_StringList2_First(const GWEN_STRINGLIST2 *l);


GWENHYWFAR_API
GWEN_STRINGLIST2_ITERATOR *GWEN_StringList2_Last(const GWEN_STRINGLIST2 *l);


GWENHYWFAR_API
void GWEN_StringList2Iterator_free(GWEN_STRINGLIST2_ITERATOR *li);


GWENHYWFAR_API
const char *GWEN_StringList2Iterator_Previous(GWEN_STRINGLIST2_ITERATOR *li);


GWENHYWFAR_API
const char *GWEN_StringList2Iterator_Next(GWEN_STRINGLIST2_ITERATOR *li);


GWENHYWFAR_API
const char *GWEN_StringList2Iterator_Data(GWEN_STRINGLIST2_ITERATOR *li);

GWENHYWFAR_API
unsigned int
  GWEN_StringList2Iterator_GetLinkCount(const GWEN_STRINGLIST2_ITERATOR *li);


GWENHYWFAR_API
GWEN_REFPTR*
GWEN_StringList2Iterator_DataRefPtr(GWEN_STRINGLIST2_ITERATOR *li);


GWENHYWFAR_API void GWEN_StringList2_Dump(const GWEN_STRINGLIST2 *sl2);



#ifdef __cplusplus
}
#endif


#endif


